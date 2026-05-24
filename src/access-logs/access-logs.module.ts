import { Module } from '@nestjs/common';
import { AccessLogsService } from './access-logs.service';
import { AccessLogsController } from './access-logs.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AccessLog } from 'src/entities/access-log.entity';
import { Device } from 'src/entities/device.entity';
import { FaceProfile } from 'src/entities/face-profile.entity';
import { User } from 'src/entities/user.entity';
import { EventsModule } from 'src/events/events.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([AccessLog, Device, FaceProfile, User]),
    EventsModule
  ],
  controllers: [AccessLogsController],
  providers: [AccessLogsService],
  exports: [AccessLogsService],
})
export class AccessLogsModule {}
