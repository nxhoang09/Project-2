import { Injectable, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async create(data: any): Promise<User> {
    const existing = await this.usersRepository.findOne({ where: { email: data.email } });
    if (existing) throw new ConflictException('Email đã tồn tại!');

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(data.password, salt);

    const newUser = this.usersRepository.create({
      email: data.email,
      password_hash,
      full_name: data.full_name,
    });
    return this.usersRepository.save(newUser);
  }

  // Tìm User bằng Email
  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { email } });
  }

  // Tìm User bằng ID
  async findById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { id } });
  }

  // Cập nhật Database (Dùng để lưu Refresh Token)
  async update(id: string, updateData: any) {
    return this.usersRepository.update(id, updateData);
  }
}