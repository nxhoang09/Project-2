import { Module } from '@nestjs/common';
import { DevicesService } from './devices.service';
import { DevicesController } from './devices.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Device } from '../entities/device.entity';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { DeviceShare } from 'src/entities/device-share.entity';
import { User } from 'src/entities/user.entity';
import { AccessLogsModule } from 'src/access-logs/access-logs.module';
import { EventsModule } from 'src/events/events.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Device, DeviceShare, User]), 
    AccessLogsModule,
    EventsModule,
    ClientsModule.registerAsync([
      {
        name: 'MQTT_CLIENT',
        imports: [ConfigModule],
        inject: [ConfigService],
        useFactory: (configService: ConfigService) => ({
          transport: Transport.MQTT,
          options: {
            url: configService.get<string>('MQTT_URL'),
          },
        }),
      },
    ]),
  ],
  controllers: [DevicesController],
  providers: [DevicesService],
})
export class DevicesModule {}