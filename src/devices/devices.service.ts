import { Injectable, Inject, NotFoundException, BadRequestException, ForbiddenException} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Device } from '../entities/device.entity';
import { ClientProxy } from '@nestjs/microservices';
import { User } from 'src/entities/user.entity';
import { DeviceShare, ShareRole } from 'src/entities/device-share.entity';
import { AccessLogsService } from 'src/access-logs/access-logs.service';
import { EventsGateway } from 'src/events/events.gateway';

@Injectable()
export class DevicesService {
  private readonly unlockCooldownMs = 5000;
  private readonly lastUnlockByDevice = new Map<string, number>();

  constructor(
    @InjectRepository(Device) private deviceRepo: Repository<Device>,
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(DeviceShare) private shareRepo: Repository<DeviceShare>,
    @Inject('MQTT_CLIENT') private mqttClient: ClientProxy,
    private accessLogsService: AccessLogsService,
    private eventsGateway: EventsGateway,
  ) {}

  async claimOwnership(userId: string, macAddress: string) {
    let device = await this.deviceRepo.findOne({
      where: { mac_address: macAddress },
      relations: ['owner']
    });

    if (!device) {
      device = this.deviceRepo.create({
        mac_address: macAddress,
        name: 'Khóa Thông Minh Mới',
      });
      device['owner_id'] = userId; 
      await this.deviceRepo.save(device);
      
      return { message: 'Đã thêm thiết bị và trở thành Chủ sở hữu (Super Admin)!' };
    }

    if (device.owner) {
      throw new BadRequestException('Khóa này đã có chủ sở hữu! Vui lòng bảo chủ nhà gửi lời mời chia sẻ vào Email của bạn.');
    }

    device['owner_id'] = userId;
    await this.deviceRepo.save(device);
    return { message: 'Đã nhận quyền Chủ sở hữu khóa thành công!' };
  }

  async unlockDevice(deviceId: string, userId: string) {
    const now = Date.now();
    const lastUnlockAt = this.lastUnlockByDevice.get(deviceId);
    if (lastUnlockAt && now - lastUnlockAt < this.unlockCooldownMs) {
      const waitSeconds = Math.ceil((this.unlockCooldownMs - (now - lastUnlockAt)) / 1000);
      throw new BadRequestException(`Vui lòng đợi ${waitSeconds}s trước khi mở khóa lại!`);
    }

    const device = await this.deviceRepo.findOne({
      where: { id: deviceId },
    });

    if (!device) {
      throw new NotFoundException('Không tìm thấy thiết bị này!');
    }

    this.lastUnlockByDevice.set(deviceId, now);
    this.accessLogsService.trackUnlockRequest(device.mac_address, userId);

    const topic = `smartlock/devices/${device.mac_address}/command`;
    const payload = {
      cmd: 'unlock',
      source: 'app',
      timestamp: new Date().toISOString(),
    };

    this.mqttClient.emit(topic, payload);
    
    return {
      message: 'Đã bắn lệnh mở cửa thành công!',
      mac_address: device.mac_address
    };
  }
  async shareDevice (ownerId: string, deviceId: string, targetEmail: string, role: ShareRole){
    const device = await this.deviceRepo.findOne({
      where: {id: deviceId},
      relations: ['owner']
    });
    if(!device || !device.owner || device.owner.id !== ownerId){
      throw new ForbiddenException('Chỉ Chủ sở hữu khóa mới được phép chia sẻ quyền!');
    }
    const targetUser = await this.userRepo.findOne({
      where:{email: targetEmail}
    });

    if(!targetUser){
      throw new NotFoundException('Không tìm thấy tài khoản nào đăng ký bằng Email này!')
    }

    if(targetUser.id === ownerId){
      throw new BadRequestException('Bạn đang là Chủ nhà rồi, không cần tự chia sẻ cho chính mình nữa!')
    }

    let share = await this.shareRepo.findOne({ where: { device: { id: deviceId }, user: { id: targetUser.id } } });

    if(share){
      share.role = role;
      await this.shareRepo.save(share);
      return { message: `Đã cập nhật quyền của [${targetEmail}] thành [${role.toUpperCase()}]!` };
    }

    share = this.shareRepo.create({
      device: device,
      user: targetUser,
      role: role
    });

    share['device_id'] = device.id;
    share['user_id'] = targetUser.id;
    await this.shareRepo.save(share);

    return { message: `Đã gửi lời mời và cấp quyền [${role.toUpperCase()}] cho [${targetEmail}] thành công!` };
  }

  async revokeAccess(ownerId: string, deviceId: string, targetEmail: string){
    const device = await this.deviceRepo.findOne({ where: { id: deviceId }, relations: ['owner'] });
    if (!device || !device.owner || device.owner.id !== ownerId) {
      throw new ForbiddenException('Chỉ Chủ sở hữu mới có quyền đuổi người khác!');
    }

    const targetUser = await this.userRepo.findOne({ where: { email: targetEmail } });
    if (!targetUser) throw new NotFoundException('Không tìm thấy người dùng này!');

    const result = await this.shareRepo.delete({ device: { id: deviceId }, user: { id: targetUser.id } });
    
    if (result.affected === 0) {
      throw new BadRequestException('Người này vốn dĩ chưa được cấp quyền trên khóa này!');
    }

    return { message: `Đã thu hồi toàn bộ quyền truy cập của [${targetEmail}]!` };
  }
  async getMyDevices(userId: string){
    const ownedDevices = await this.deviceRepo.find({
      where: {owner: {id: userId}},
      select: ['id', 'name','status', 'mac_address'],
    });
    const sharedAccesses = await this.shareRepo.find({
      where: { user: { id: userId } },
      relations: ['device'],
    });
    const sharedDevices = sharedAccesses.map(share => share.device);
    const allDevices = [...ownedDevices, ...sharedDevices];

    return allDevices.map(device => ({
      id: device.id,
      name: device.name,
      mac_address: device.mac_address,
      status: device.status,
      is_online: device.status === 'ONLINE',
    }));
  }
  async updateDeviceStatus(macAddress: string, newStatus: string){
    const device = await this.deviceRepo.findOne({
      where: {mac_address: macAddress}
    });
    if(!device) return;

    if(device.status != newStatus){
      device.status = newStatus
      await this.deviceRepo.save(device);

      this.eventsGateway.notifyDeviceStatus(device.id, newStatus);
    }
  }
}