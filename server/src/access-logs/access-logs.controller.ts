import { Controller, Get, Query, UseGuards, Param } from '@nestjs/common';
import { AccessLogsService } from './access-logs.service';
import { MessagePattern, Payload, Ctx, MqttContext } from '@nestjs/microservices';
import { JwtAuthGuard } from 'src/auth/jwt-auth.guard';

@Controller()
export class AccessLogsController {
  constructor(private readonly accessLogsService: AccessLogsService) {}
  @MessagePattern('smartlock/devices/+/report')
  async handleDeviceReport(@Payload() data: any, @Ctx() context: MqttContext) {
    const topic = context.getTopic(); 
    const macAddress = topic.split('/')[2]; 
    return this.accessLogsService.saveLog(macAddress, data);
  }

  @MessagePattern('smartlock/devices/+/unlock_result')
  async handleUnlockResult(@Payload() data: any, @Ctx() context: MqttContext) {
    const topic = context.getTopic();
    const macAddress = topic.split('/')[2];
    return this.accessLogsService.handleUnlockResult(macAddress, data);
  }

  @MessagePattern('smartlock/devices/+/command')
  async handleUnlockResultFromCommand(@Payload() data: any, @Ctx() context: MqttContext) {
    const topic = context.getTopic();
    const macAddress = topic.split('/')[2];
    return this.accessLogsService.handleUnlockResult(macAddress, data);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':deviceId/logs')
  async getLogs(
    @Param('deviceId') deviceId: string,
    @Query('page') page:string,
    @Query('limit') limit: string
  ){
    const pageNum = Number(page) || 1;
    const limitNum = Number(limit) || 20;

    return this.accessLogsService.getLogsByDevice(deviceId, pageNum, limitNum);
  }
}