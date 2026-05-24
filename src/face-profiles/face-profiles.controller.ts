import { Controller, Post, Body, Param, UseGuards, Request, Delete, Get } from '@nestjs/common';
import { FaceProfilesService } from './face-profiles.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { MessagePattern, Payload, Ctx, MqttContext } from '@nestjs/microservices';
import { DeviceRoleGuard, RequireDeviceRole } from 'src/auth/device-role.guard';
import { ShareRole } from 'src/entities/device-share.entity';

@Controller('face-profiles')
export class FaceProfilesController {
  constructor(private readonly faceProfilesService: FaceProfilesService) {}

  @UseGuards(JwtAuthGuard)
  @Get('my')
  async getMyProfiles(@Request() req: any) {
    const userId = req.user.sub || req.user.userId;
    return this.faceProfilesService.getProfilesForOwner(userId);
  }

  @UseGuards(JwtAuthGuard, DeviceRoleGuard)
  @RequireDeviceRole(ShareRole.ADMIN)
  @Post('enroll')
  async enrollFace(@Body() body: any, @Request() req: any) {
    const userId = req.user.userId;
    return this.faceProfilesService.startEnrollment(userId, body.deviceId, body.name);
  }

  @UseGuards(JwtAuthGuard, DeviceRoleGuard)
  @RequireDeviceRole(ShareRole.ADMIN)
  @Post(':profileId/assign')
  async assignToDevice(
    @Param('profileId') profileId: string, 
    @Body('deviceId') targetDeviceId: string, 
    @Request() req: any
  ) {
    const userId = req.user.userId;
    return this.faceProfilesService.assignFaceToDevice(userId, profileId, targetDeviceId);
  }
   
  @MessagePattern('smartlock/devices/+/enroll_result')
  async handleMqttResult(@Payload() data: any, @Ctx() context: MqttContext) {
    const topic = context.getTopic();
    const macAddress = topic.split('/')[2];
    
    await this.faceProfilesService.handleEnrollResult(macAddress, data);
  }
  @MessagePattern('smartlock/devices/+/sync_result')
  async handleMqttSyncResult(@Payload() data: any, @Ctx() context: MqttContext) {
    const topic = context.getTopic();
    const macAddress = topic.split('/')[2];
    
    await this.faceProfilesService.handleSyncResult(macAddress, data);
  }
  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  async deleteFace(
    @Param('id') profileId: string,
    @Request() req: any
  ) {
    return this.faceProfilesService.deleteProfile(req.user.userId, profileId);
  }

  @MessagePattern('smartlock/devices/+/delete_result')
  async handleDeleteResult(
    @Payload() data: any, 
    @Ctx() context: MqttContext
  ) {
    const topic = context.getTopic();
    const macAddress = topic.split('/')[2];
    await this.faceProfilesService.processDeleteResult(macAddress, data);
  }
}