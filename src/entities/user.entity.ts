import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToMany } from 'typeorm';
import { Device } from './device.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  password_hash: string;

  @Column()
  full_name: string;

  @Column({ nullable: true })
  hashed_refresh_token: string;

  @CreateDateColumn()
  created_at: Date;

  @OneToMany(() => Device, (device) => device.owner)
  devices: Device[];
}