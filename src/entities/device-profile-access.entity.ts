import { Entity, Column, CreateDateColumn, ManyToOne, JoinColumn, PrimaryColumn } from 'typeorm';
import { FaceProfile } from './face-profile.entity';
import { Device } from './device.entity';

@Entity('device_profile_access')
export class DeviceProfileAccess {
  @PrimaryColumn()
  profile_id: string;

  @PrimaryColumn()
  device_id: string;

  @Column({ type: 'int', array: true, nullable: true })
  local_esp_ids!: number[];

  @Column({ default: 'PENDING' })
  sync_status: string; // PENDING / SYNCED / PENDING_DELETE / FAILED

  @CreateDateColumn()
  created_at: Date;

  @ManyToOne(() => FaceProfile)
  @JoinColumn({ name: 'profile_id' })
  profile: FaceProfile;

  @ManyToOne(() => Device)
  @JoinColumn({ name: 'device_id' })
  device: Device;
}