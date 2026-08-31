import {
  Controller,
  Get,
  UseGuards,
  Request,
  Patch,
  Body,
  BadRequestException,
  Post,
  Delete,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UsersService } from './users.service';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Express } from 'express';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getProfile(@Request() req: any) {
    const user = await this.usersService.findById(req.user.userId);
    if (user) {
      const { password_hash, hashed_refresh_token, ...result } = user;
      return result;
    }
    return null;
  }

  @UseGuards(JwtAuthGuard)
  @Patch('me')
  async updateProfile(@Body() body: any, @Request() req: any) {
    const fullName = typeof body?.full_name === 'string' ? body.full_name : undefined;
    if (fullName === undefined) {
      throw new BadRequestException('Thiếu họ tên cần cập nhật');
    }
    const user = await this.usersService.updateProfile(req.user.userId, { full_name: fullName });
    const { password_hash, hashed_refresh_token, ...result } = user;
    return result;
  }

  @Post('fcm-token')
  @UseGuards(JwtAuthGuard) 
  async updateFcmToken(@Request() req, @Body('fcm_token') token: string) {
    await this.usersService.updateToken(req.user.userId, token);
    return { success: true, message: 'Đã lưu FCM Token' };
  }

  @Delete('fcm-token')
  @UseGuards(JwtAuthGuard)
  async removeFcmToken(@Request() req) {
    await this.usersService.updateToken(req.user.userId, null);
    return { success: true, message: 'Đã xóa FCM Token' };
  }

  @UseGuards(JwtAuthGuard)
  @Post('me/avatar')
  @UseInterceptors(
    FileInterceptor('avatar', {
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: (_req, file, callback) => {
        if (!file.mimetype.startsWith('image/')) {
          return callback(new BadRequestException('Chỉ hỗ trợ file ảnh'), false);
        }
        return callback(null, true);
      },
    }),
  )
  async uploadAvatar(@UploadedFile() file: Express.Multer.File, @Request() req: any) {
    if (!file) {
      throw new BadRequestException('Vui lòng chọn ảnh đại diện');
    }
    const user = await this.usersService.uploadAvatar(req.user.userId, file);
    const { password_hash, hashed_refresh_token, ...result } = user;
    return result;
  }
}