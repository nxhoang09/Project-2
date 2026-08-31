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

  @Column({ type: 'text', nullable: true })
  avatar_url: string | null;

  @Column({ nullable: true })
  hashed_refresh_token: string;

  @Column({nullable: true})
  reset_otp: string;

  @Column({type: 'timestamp', nullable: true})
  reset_otp_expires: Date;

  @CreateDateColumn()
  created_at: Date;

  @OneToMany(() => Device, (device) => device.owner)
  devices: Device[];

  @Column({ type: 'varchar', nullable: true})
  fcm_token: string | null;
}