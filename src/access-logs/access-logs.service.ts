import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { AccessLog } from 'src/entities/access-log.entity';
import { Device } from 'src/entities/device.entity';
import { FaceProfile } from 'src/entities/face-profile.entity';
import { User } from 'src/entities/user.entity';
import { EventsGateway } from 'src/events/events.gateway';
import { Repository } from 'typeorm';

@Injectable()
export class AccessLogsService {
  private readonly unlockUserTtlMs = 15000;
  private readonly lastUnlockUserByMac = new Map<string, { userId: string; at: number }>();

  constructor(
    @InjectRepository(AccessLog) private accessLogRepo: Repository<AccessLog>,
    @InjectRepository(Device) private deviceRepo: Repository<Device>,
    @InjectRepository(FaceProfile) private faceProfileRepo: Repository<FaceProfile>,
    @InjectRepository(User) private userRepo: Repository<User>,
    private eventsGateway: EventsGateway,
  ){}

  trackUnlockRequest(macAddress: string, userId: string) {
    this.lastUnlockUserByMac.set(macAddress, { userId, at: Date.now() });
  }

  private consumeUnlockUser(macAddress: string): string | null {
    const entry = this.lastUnlockUserByMac.get(macAddress);
    if (!entry) return null;

    if (Date.now() - entry.at > this.unlockUserTtlMs) {
      this.lastUnlockUserByMac.delete(macAddress);
      return null;
    }

    this.lastUnlockUserByMac.delete(macAddress);
    return entry.userId;
  }

  private normalizeUnlockResult(data: any): { success: boolean; reason?: string } | null {
    if (!data || typeof data !== 'object') return null;

    if (typeof data.cmd === 'string' && data.cmd.toLowerCase() !== 'unlock') return null;

    const rawStatus = data.status ?? data.result ?? data.state ?? data.success ?? data.ok;
    if (rawStatus === undefined) return null;

    let success: boolean | null = null;

    if (typeof rawStatus === 'boolean') {
      success = rawStatus;
    } else if (typeof rawStatus === 'number') {
      success = rawStatus === 1;
    } else if (typeof rawStatus === 'string') {
      const normalized = rawStatus.trim().toLowerCase();
      if (['success', 'ok', 'opened', 'open', 'unlocked', 'true', '1'].includes(normalized)) {
        success = true;
      } else if (['fail', 'failed', 'error', 'denied', 'close', 'closed', 'locked', 'false', '0'].includes(normalized)) {
        success = false;
      }
    }

    if (success === null) return null;

    const reason =
      typeof data.reason === 'string'
        ? data.reason
        : typeof data.error === 'string'
          ? data.error
          : undefined;

    return { success, reason };
  }

  async saveLog(macAddress: string, data: any){
    const device = await this.deviceRepo.findOne({ where: { mac_address: macAddress } });
    if (!device) return;

    let eventType = typeof data?.event === 'string' ? data.event : undefined;
    if (eventType) {
      const normalized = eventType.trim().toUpperCase();
      if (['FACE_UNLOCK', 'FACE_UNLOCK_SUCCESS', 'UNLOCK_FACE', 'UNLOCK_SUCCESS'].includes(normalized)) {
        eventType = 'UNLOCK_SUCCESS';
      } else if (['FACE_UNLOCK_FAILED', 'UNLOCK_FAILED'].includes(normalized)) {
        eventType = 'UNLOCK_FAILED';
      }
    }

    const newLog = this.accessLogRepo.create({
      device: device,
      event_type: eventType,
    });
    let actorName = 'Không xác định';

    if (data.profile_id) {
      const profile = await this.faceProfileRepo.findOne({ where: { id: data.profile_id } });
      if (profile) {
        newLog.profile = profile; 
        actorName = profile.name;
      }
    }
    if (data.event === 'INTRUDER_ALARM') {
      actorName = 'Kẻ lạ mặt';
    }
    const savedLog = await this.accessLogRepo.save(newLog);

    const socketPayload = {
      id: savedLog.id,
      device_id: device.id,
      event_type: savedLog.event_type,
      actor_name: actorName,
      timestamp: savedLog.timestamp || new Date(), 
    };
    this.eventsGateway.notifyNewAccessLog(device.id, socketPayload);
  }

  async handleUnlockResult(macAddress: string, data: any) {
    const device = await this.deviceRepo.findOne({ where: { mac_address: macAddress } });
    if (!device) return;

    const normalized = this.normalizeUnlockResult(data);
    if (!normalized) return;

    const userIdFromPayload =
      typeof data?.user_id === 'string'
        ? data.user_id
        : typeof data?.userId === 'string'
          ? data.userId
          : null;

    const userId = userIdFromPayload || this.consumeUnlockUser(macAddress);

    const eventType = normalized.success ? 'APP_UNLOCK_SUCCESS' : 'UNLOCK_FAILED';
    const newLog = this.accessLogRepo.create({
      device: device,
      event_type: eventType,
    });

    if (userId) {
      newLog.user = { id: userId } as User;
    }

    const savedLog = await this.accessLogRepo.save(newLog);
    const timestamp = savedLog.timestamp || new Date();

    let actorName = 'App';
    if (userId) {
      const user = await this.userRepo.findOne({ where: { id: userId } });
      if (user?.full_name) actorName = user.full_name;
    }

    this.eventsGateway.notifyNewAccessLog(device.id, {
      id: savedLog.id,
      device_id: device.id,
      event_type: savedLog.event_type,
      actor_name: actorName,
      timestamp: timestamp,
    });

    this.eventsGateway.notifyUnlockResult(device.id, {
      device_id: device.id,
      mac_address: device.mac_address,
      status: normalized.success ? 'success' : 'failed',
      reason: normalized.reason,
      user_id: userId,
      timestamp: timestamp,
    });
  }

  async getLogsByDevice(deviceId: string, page: number = 1, limit: number = 20){
    const skip = (page - 1) * limit;
    const logs = await this.accessLogRepo.find({
      where: {device: {id: deviceId}},
      relations: ['user', 'profile'],
      order: {timestamp:'DESC'},
      take: limit,
      skip: skip,
    });
    return logs.map(log => {
      let actorName = 'Không xác định';
      if (log.profile) actorName = log.profile.name;
      else if (log.user) actorName = log.user.full_name;
      else if (log.event_type === 'INTRUDER_ALARM') actorName = 'Kẻ lạ mặt';

      return {
        id: log.id,
        event_type: log.event_type,
        actor_name: actorName,
        timestamp: log.timestamp,
      };
    });
  }
}