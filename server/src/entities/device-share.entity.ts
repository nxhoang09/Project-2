import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from './user.entity';
import { Device } from './device.entity';

export enum ShareRole {
  ADMIN = 'admin',
  VIEWER = 'viewer',
}

@Entity('device_shares')
export class DeviceShare {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'enum', enum: ShareRole, default: ShareRole.VIEWER})
  role: ShareRole; 

  @CreateDateColumn()
  created_at: Date;

  @ManyToOne(() => Device, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'device_id' })
  device: Device;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;
}