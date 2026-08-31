import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Device } from '../entities/device.entity';
import { DeviceShare, ShareRole } from '../entities/device-share.entity';
import { Reflector } from '@nestjs/core';

export const REQUIRE_ROLE = 'require_role';
export const RequireDeviceRole = (role: ShareRole) => Reflect.metadata(REQUIRE_ROLE, role);

@Injectable()
export class DeviceRoleGuard implements CanActivate {
  constructor(
    @InjectRepository(Device) private deviceRepo: Repository<Device>,
    @InjectRepository(DeviceShare) private shareRepo: Repository<DeviceShare>,
    private reflector: Reflector
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRole = this.reflector.get<ShareRole>(REQUIRE_ROLE, context.getHandler());
    const request = context.switchToHttp().getRequest();
    const userId = request.user.userId;
    const deviceId = request.params.id || request.params.deviceId || request.body.deviceId;

    if (!deviceId) return false;

    const device = await this.deviceRepo.findOne({ where: { id: deviceId, owner: { id: userId } } });
    if (device) return true;

    const share = await this.shareRepo.findOne({
      where: { device: { id: deviceId }, user: { id: userId } }
    });

    if (!share) throw new ForbiddenException('Bạn không có quyền trên khóa này!');
    
    if (requiredRole === ShareRole.ADMIN && share.role !== ShareRole.ADMIN) {
      throw new ForbiddenException('Chỉ Quản trị viên mới được thực hiện thao tác này!');
    }

    return true;
  }
}