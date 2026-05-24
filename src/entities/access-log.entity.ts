import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Device } from './device.entity';
import { FaceProfile } from './face-profile.entity';
import { User } from './user.entity';

@Entity('access_logs')
export class AccessLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  event_type: string; // FACE_UNLOCK / APP_UNLOCK / ALERT_SPOOF

  @CreateDateColumn({ type: 'timestamptz' })
  timestamp: Date;

  @ManyToOne(() => Device)
  @JoinColumn({ name: 'device_id' })
  device: Device;

  @ManyToOne(() => FaceProfile, { nullable: true })
  @JoinColumn({ name: 'profile_id' })
  profile: FaceProfile;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'user_id' })
  user: User;
}