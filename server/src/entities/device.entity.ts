import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from './user.entity';

@Entity('devices')
export class Device {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  mac_address: string;

  @Column()
  name: string;

  @Column({ default: 'OFFLINE' })
  status: string;

  @CreateDateColumn()
  created_at: Date;

  // Khóa ngoại liên kết tới bảng users
  @ManyToOne(() => User, (user) => user.devices)
  @JoinColumn({ name: 'owner_id' })
  owner: User;
}