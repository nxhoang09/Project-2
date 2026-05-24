import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';

@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private usersService: UsersService,
  ) {}

  @Post('register')
  async register(@Body() body: any) {
    const user = await this.usersService.create(body);
    return { message: 'Đăng ký thành công!', user_id: user.id };
  }

  @HttpCode(HttpStatus.OK)
  @Post('login')
  async login(@Body() body: any) {
    return this.authService.login(body.email, body.password);
  }

  @HttpCode(HttpStatus.OK)
  @Post('refresh')
  async refresh(@Body() body: any) {
    return this.authService.refreshTokens(body.userId, body.refreshToken);
  }

  @HttpCode(HttpStatus.OK)
  @Post('logout')
  async logout(@Body() body: any) {
    await this.authService.logout(body.userId);
    return { message: 'Đã đăng xuất' };
  }
}