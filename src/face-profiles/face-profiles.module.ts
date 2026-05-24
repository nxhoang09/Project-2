import { Module } from '@nestjs/common';
import { FaceProfilesService } from './face-profiles.service';
import { FaceProfilesController } from './face-profiles.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FaceProfile } from 'src/entities/face-profile.entity';
import { DeviceProfileAccess } from 'src/entities/device-profile-access.entity';
import { Device } from 'src/entities/device.entity';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { DeviceShare } from 'src/entities/device-share.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([FaceProfile, DeviceProfileAccess, Device, DeviceShare]),
    ClientsModule.registerAsync([
      {
        name: 'MQTT_CLIENT',
        imports: [ConfigModule],
        inject: [ConfigService],
        useFactory: (ConfigService: ConfigService) => ({
          transport: Transport.MQTT,
          options: { url: ConfigService.get<string>('MQTT_URL')},
        }),
      },
    ]),
  ],
  controllers: [FaceProfilesController],
  providers: [FaceProfilesService],
})
export class FaceProfilesModule {}
