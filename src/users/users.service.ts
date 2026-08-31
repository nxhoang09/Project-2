import {
  Injectable,
  ConflictException,
  BadRequestException,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';
import * as bcrypt from 'bcrypt';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import type { Express } from 'express';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    private configService: ConfigService,
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

  async updateToken(userId: string, token: string| null): Promise<void> {
    await this.usersRepository.update(userId,{
      fcm_token: token,
    });
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

  async updateProfile(
    userId: string,
    updateData: { full_name?: string; avatar_url?: string | null },
  ): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('Người dùng không tồn tại');

    if (typeof updateData.full_name === 'string') {
      const trimmed = updateData.full_name.trim();
      if (!trimmed) throw new BadRequestException('Họ tên không được để trống');
      user.full_name = trimmed;
    }

    if (updateData.avatar_url !== undefined) {
      user.avatar_url = updateData.avatar_url ?? null;
    }

    return this.usersRepository.save(user);
  }

  async uploadAvatar(userId: string, file: Express.Multer.File): Promise<User> {
    const { supabaseUrl, serviceKey, bucket } = this.getSupabaseConfig();
    const objectPath = this.buildAvatarPath(userId, file.mimetype);
    const uploadUrl = `${supabaseUrl}/storage/v1/object/${bucket}/${objectPath}`;

    const response = await fetch(uploadUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${serviceKey}`,
        'Content-Type': file.mimetype,
        'x-upsert': 'true',
      },
      body: new Uint8Array(file.buffer),
    });

    if (!response.ok) {
      const detail = await response.text();
      throw new InternalServerErrorException(
        detail || 'Không thể tải ảnh lên storage.',
      );
    }

    const publicUrl = `${supabaseUrl}/storage/v1/object/public/${bucket}/${objectPath}`;
    return this.updateProfile(userId, { avatar_url: publicUrl });
  }

  private getSupabaseConfig() {
    const rawUrl = this.configService.get<string>('SUPABASE_URL')?.trim();
    const serviceKey = this.configService
      .get<string>('SUPABASE_SERVICE_ROLE_KEY')
      ?.trim();
    const bucket =
      this.configService.get<string>('SUPABASE_STORAGE_BUCKET')?.trim() || 'avatars';

    if (!rawUrl || !serviceKey) {
      throw new InternalServerErrorException('Supabase chưa được cấu hình');
    }

    const supabaseUrl = rawUrl.endsWith('/') ? rawUrl.slice(0, -1) : rawUrl;
    return { supabaseUrl, serviceKey, bucket };
  }

  private buildAvatarPath(userId: string, mimeType: string) {
    const extension = this.getAvatarExtension(mimeType);
    return `${userId}/${Date.now()}-${randomUUID()}.${extension}`;
  }

  private getAvatarExtension(mimeType: string) {
    switch (mimeType.toLowerCase()) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/jpeg':
      case 'image/jpg':
      default:
        return 'jpg';
    }
  }
}