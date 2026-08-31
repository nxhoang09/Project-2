import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { Device } from './entities/device.entity';
import { DeviceShare } from './entities/device-share.entity';
import { FaceProfile } from './entities/face-profile.entity';
import { DeviceProfileAccess } from './entities/device-profile-access.entity';
import { AccessLog } from './entities/access-log.entity';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { DevicesModule } from './devices/devices.module';
import { AccessLogsModule } from './access-logs/access-logs.module';
import { FaceProfilesModule } from './face-profiles/face-profiles.module';
import { EventsModule } from './events/events.module';
import { MailerModule } from '@nestjs-modules/mailer';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, envFilePath: '.env' }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DB_HOST'),
        port: configService.get<number>('DB_PORT'),
        username: configService.get<string>('DB_USER'),
        password: configService.get<string>('DB_PASSWORD'),
        database: configService.get<string>('DB_NAME'),
        ssl: { rejectUnauthorized: false }, 
        synchronize: true, 
        entities: [User, Device, DeviceShare, FaceProfile, DeviceProfileAccess, AccessLog],
      }),
    }),
    MailerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: async (configService: ConfigService) => ({
        transport: {
          host: configService.get<string>('MAIL_HOST'),
          port: 465,
          secure: true, 
          auth: {
            user: configService.get<string>('MAIL_USER'),
            pass: configService.get<string>('MAIL_PASS'),
          },
        },
        defaults: {
          from: configService.get<string>('MAIL_FROM'),
        },
      }),
    }),
    UsersModule,
    AuthModule,
    DevicesModule,
    AccessLogsModule,
    FaceProfilesModule,
    EventsModule
  ],
})
export class AppModule {}