import { Controller, Post, Body, HttpCode, HttpStatus, BadRequestException, Request, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { JwtAuthGuard } from './jwt-auth.guard';

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

  @Post('forgot-password')
  async forgotPassword(@Body('email') email: string) {
    if (!email) {
      throw new BadRequestException('Vui lòng cung cấp email!');
    }
    
    return this.authService.forgotPassword(email);
  }

  @Post('reset-password')
  async resetPassword(
    @Body('email') email: string,
    @Body('otp') otp: string,
    @Body('newPassword') newPassword: string,
  ) {
    if (!email || !otp || !newPassword) {
      throw new BadRequestException('Vui lòng điền đầy đủ thông tin!');
    }

    if (newPassword.length < 6) {
      throw new BadRequestException('Mật khẩu mới phải có ít nhất 6 ký tự!');
    }
    return this.authService.resetPassword(email, otp, newPassword);
  }

  @UseGuards(JwtAuthGuard) 
  @Post('change-password')
  async changePassword(@Body() body: any, @Request() req: any) {
    const { oldPassword, newPassword } = body;
    return this.authService.changePassword(req.user.userId, oldPassword, newPassword);
  }
}