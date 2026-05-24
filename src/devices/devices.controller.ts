import { Controller, Post, Param, Body, UseGuards, Request, Delete, Get } from '@nestjs/common';
import { DevicesService } from './devices.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DeviceRoleGuard, RequireDeviceRole } from '../auth/device-role.guard';
import { ShareRole } from '../entities/device-share.entity';
import { MessagePattern, Payload, Ctx, MqttContext } from '@nestjs/microservices';
@Controller('devices')
export class DevicesController {
  constructor(private readonly devicesService: DevicesService) {}

  @UseGuards(JwtAuthGuard)
  @Post('claim')
  async claimDevice(@Body('mac_address') macAddress: string, @Request() req: any) {
    return this.devicesService.claimOwnership(req.user.userId, macAddress);
  }

  @UseGuards(JwtAuthGuard, DeviceRoleGuard)
  @RequireDeviceRole(ShareRole.VIEWER) 
  @Post(':id/unlock')
  async unlock(@Param('id') deviceId: string, @Request() req: any) {
    const userId = req.user.sub || req.user.userId;
    return this.devicesService.unlockDevice(deviceId, userId);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/share')
  async shareDevice(
    @Param('id') deviceId: string, 
    @Body('email') email: string, 
    @Body('role') role: ShareRole, 
    @Request() req: any
  ) {
    return this.devicesService.shareDevice(req.user.userId, deviceId, email, role);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id/share/:email')
  async revokeAccess(
    @Param('id') deviceId: string, 
    @Param('email') email: string, 
    @Request() req: any
  ) {
    return this.devicesService.revokeAccess(req.user.userId, deviceId, email);
  }

  @UseGuards(JwtAuthGuard)
  @Get('my-devices')
  async getMyDevices(@Request() req: any) {
    const userId = req.user.sub || req.user.userId; 
    return this.devicesService.getMyDevices(userId);
  }

  @MessagePattern('smartlock/devices/+/status')
  async handleDeviceStatus(@Payload() status: string, @Ctx() context: MqttContext) {
    const topic = context.getTopic();
    const topicParts = topic.split('/');
    const macAddress = topicParts[2];
    await this.devicesService.updateDeviceStatus(macAddress, status);
  }
}