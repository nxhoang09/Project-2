import { Injectable, Inject, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { FaceProfile } from '../entities/face-profile.entity';
import { DeviceProfileAccess } from '../entities/device-profile-access.entity';
import { Device } from '../entities/device.entity';
import { DeviceShare, ShareRole } from '../entities/device-share.entity';
import { ClientProxy } from '@nestjs/microservices';

@Injectable()
export class FaceProfilesService {
  constructor(
    @InjectRepository(FaceProfile) private faceProfileRepo: Repository<FaceProfile>,
    @InjectRepository(DeviceProfileAccess) private accessRepo: Repository<DeviceProfileAccess>,
    @InjectRepository(Device) private deviceRepo: Repository<Device>,
    @InjectRepository(DeviceShare) private shareRepo: Repository<DeviceShare>,
    @Inject('MQTT_CLIENT') private mqttClient: ClientProxy,
  ) {}
  async getProfilesForOwner(userId: string) {
    const ownedDevices = await this.deviceRepo.find({
      where: { owner: { id: userId } },
      select: ['id', 'name', 'status', 'mac_address'],
    });

    const sharedAdmin = await this.shareRepo.find({
      where: { user: { id: userId }, role: ShareRole.ADMIN },
      relations: ['device'],
    });

    const deviceMap = new Map<string, { id: string; name: string; status: string; mac_address: string }>();
    for (const device of ownedDevices) {
      deviceMap.set(device.id, {
        id: device.id,
        name: device.name,
        status: device.status,
        mac_address: device.mac_address,
      });
    }

    for (const share of sharedAdmin) {
      const device = share.device;
      if (!device || deviceMap.has(device.id)) continue;
      deviceMap.set(device.id, {
        id: device.id,
        name: device.name,
        status: device.status,
        mac_address: device.mac_address,
      });
    }

    const devices = Array.from(deviceMap.values());
    if (devices.length === 0) {
      return { devices: [], profiles: [] };
    }

    const deviceIds = devices.map((device) => device.id);
    const accessRecords = await this.accessRepo.find({
      where: { device: { id: In(deviceIds) } },
      relations: ['profile', 'device'],
    });

    const profileMap = new Map<string, any>();
    for (const record of accessRecords) {
      if (!record.profile) continue;
      const existing = profileMap.get(record.profile.id) ?? {
        id: record.profile.id,
        name: record.profile.name,
        created_at: record.profile.created_at,
        device_statuses: [],
      };
      existing.device_statuses.push({
        device_id: record.device_id ?? record.device?.id,
        status: record.sync_status,
      });
      profileMap.set(record.profile.id, existing);
    }

    const profiles = Array.from(profileMap.values()).map((profile) => {
      const statuses = profile.device_statuses.map((item: any) => item.status);
      return {
        ...profile,
        status: this.pickOverallStatus(statuses),
      };
    });

    return {
      devices,
      profiles,
    };
  }

  async startEnrollment(userId: string, deviceId: string, profileName: string) {
    if (!deviceId || !profileName || !profileName.trim()) {
      throw new BadRequestException('Thiếu thông tin thiết bị hoặc tên hồ sơ!');
    }

    const device = await this.deviceRepo.findOne({ where: {id: deviceId}, relations: ['owner']});
    if(!device) throw new NotFoundException('Device not found');
    const isOwner = device.owner?.id === userId;
    if (!isOwner) {
      const share = await this.shareRepo.findOne({
        where: { device: { id: deviceId }, user: { id: userId } },
      });

      if (!share || share.role !== ShareRole.ADMIN) {
        throw new ForbiddenException('Chỉ Chủ nhà hoặc Quản trị viên (Admin) mới được phép thêm khuôn mặt!');
      }
    }
    if (device.status !== 'ONLINE') {
      throw new BadRequestException('Thiết bị đang Offline. Vui lòng thử lại khi thiết bị Online!');
    }

    const newProfile = this.faceProfileRepo.create({ name: profileName, createdBy: { id: userId } });
    const savedProfile = await this.faceProfileRepo.save(newProfile);
    const accessRecord = this.accessRepo.create({
      profile: savedProfile,            
      profile_id: savedProfile.id,     
      device: device,                  
      device_id: device.id,          
      local_esp_ids: [],
      sync_status: 'PENDING',
    } as any);

    await this.accessRepo.save(accessRecord);

    const topic = `smartlock/devices/${device.mac_address}/command`;
    const payload = {
      cmd: 'start_enroll',
      profile_id: newProfile.id,
      steps: 5 
    };
    this.mqttClient.emit(topic, payload);

    return { 
      message: 'Đã yêu cầu ESP32 bật camera. Vui lòng đứng trước thiết bị!',
      profile_id: newProfile.id
    };
  }

  async handleEnrollResult(macAddress: string, data: any) {
    const accessRecord = await this.accessRepo.findOne({
      where: { 
        profile: { id: data.profile_id },    
        device: { mac_address: macAddress }
       },
      relations: ['device']
    });

    if (!accessRecord) {
      console.log(`Không tìm thấy bản ghi quyền cho Profile [${data.profile_id}] trên Khóa [${macAddress}]`);
      return;
    }


    if (data.status !== 'success') {
      accessRecord.sync_status = 'FAILED';
      await this.accessRepo.save(accessRecord);
      console.log(`Khóa [${macAddress}] báo lỗi khi đăng ký khuôn mặt!`);
      return;
    }
    accessRecord.local_esp_ids = data.local_esp_ids ?? [];
    accessRecord.sync_status = 'SYNCED';
    await this.accessRepo.save(accessRecord);
    console.log(`Đã lưu Vector Gốc và cấp quyền cho Khóa [${macAddress}]!`);
  }

  private pickOverallStatus(statuses: string[]) {
    const normalized = statuses.map((status) => (status ?? 'PENDING').toUpperCase());
    const priority = ['PENDING_DELETE', 'FAILED', 'PENDING', 'SYNCED'];
    for (const status of priority) {
      if (normalized.includes(status)) return status;
    }
    return 'SYNCED';
  }
  async deleteProfile(userId: string, profileId: string) {
    const profile = await this.faceProfileRepo.findOne({ 
      where: { id: profileId }, 
      relations: ['createdBy'] 
    });

    if (!profile) throw new NotFoundException('Không tìm thấy hồ sơ!');
    const accessRecords = await this.accessRepo.find({
      where: { profile: { id: profileId } },
      relations: ['device', 'device.owner'] 
    });

    let isAllowed = false;

    if (profile.createdBy.id === userId) {
      isAllowed = true;
    }

    if (!isAllowed) {
      for (const record of accessRecords) {
        if (record.device.owner && record.device.owner.id === userId) {
          isAllowed = true;
          break;
        }

        const share = await this.shareRepo.findOne({
          where: { device: { id: record.device.id }, user: { id: userId } }
        });

        if (share && share.role === ShareRole.ADMIN) {
          isAllowed = true;
          break;
        }
      }
    }

    if (!isAllowed) {
      throw new ForbiddenException('Chỉ Người tạo, Chủ nhà hoặc Quản trị viên (Admin) mới được phép xóa hồ sơ này!');
    }

    for (const record of accessRecords) {
      if (record.local_esp_ids && record.local_esp_ids.length > 0) {
        const topic = `smartlock/devices/${record.device.mac_address}/command`;
        const payload = {
          cmd: 'delete_face',
          profile_id: profileId,
        };
        record.sync_status = 'PENDING_DELETE';
        await this.accessRepo.save(record);
        this.mqttClient.emit(topic, payload);
      }
    }

    return { message: 'Đã chuyển trạng thái sang Chờ Xóa và bắn lệnh xuống Khóa!' };
  }
  async processDeleteResult(macAddress: string, data: any) {
    if (data.status === 'success' || data.status === 'not_found') {
      const recordToDelete = await this.accessRepo.findOne({
        where: {
          profile:{ id: data.profile_id},
          device: {mac_address: macAddress}
        }
      });
      if(recordToDelete){
        await this.accessRepo.remove(recordToDelete);
      }

      const remainingAccess = await this.accessRepo.count({
        where: { profile: { id: data.profile_id } }
      });

      if (remainingAccess === 0) {
        await this.faceProfileRepo.delete(data.profile_id);
        console.log(`Đã dọn dẹp hoàn toàn Profile [${data.profile_id}] khỏi Database!`);
      } else {
        console.log(`Profile [${data.profile_id}] vẫn còn quyền trên ${remainingAccess} khóa khác. Giữ lại Root Profile.`);
      }
    } else {
      console.log(`Khóa [${macAddress}] báo lỗi khi xóa Profile [${data.profile_id}]. Status: ${data.status}`);
    }
  }
}
