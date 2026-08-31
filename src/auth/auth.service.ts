import { Injectable, UnauthorizedException, ForbiddenException, BadRequestException, NotFoundException} from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { InjectRepository } from '@nestjs/typeorm';
import { User } from 'src/entities/user.entity';
import { Repository } from 'typeorm';
import { MailerService } from '@nestjs-modules/mailer';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) private userRepo: Repository<User>,
    private usersService: UsersService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private mailerService: MailerService

  ) {}

  async login(email: string, pass: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user || !(await bcrypt.compare(pass, user.password_hash))) {
      throw new UnauthorizedException('Sai email hoặc mật khẩu');
    }

    const tokens = await this.getTokens(user.id, user.email);
    await this.updateRefreshToken(user.id, tokens.refresh_token);

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.full_name,
        avatar_url: user.avatar_url,
      },
      ...tokens,
    };
  }

  async refreshTokens(userId: string, rt: string) {
    const user = await this.usersService.findById(userId);
    if (!user || !user.hashed_refresh_token) throw new ForbiddenException('Bị từ chối');

    const rtMatches = await bcrypt.compare(rt, user.hashed_refresh_token);
    if (!rtMatches) throw new ForbiddenException('Bị từ chối');

    const tokens = await this.getTokens(user.id, user.email);
    await this.updateRefreshToken(user.id, tokens.refresh_token);
    return tokens;
  }

  async logout(userId: string) {
    await this.usersService.update(userId, { hashed_refresh_token: null });
  }

  
  private async getTokens(userId: string, email: string) {
    const payload = { sub: userId, email };
    const [at, rt] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.configService.get('JWT_ACCESS_SECRET'),
        expiresIn: this.configService.get('JWT_ACCESS_EXPIRATION'),
      }),
      this.jwtService.signAsync(payload, {
        secret: this.configService.get('JWT_REFRESH_SECRET'),
        expiresIn: this.configService.get('JWT_REFRESH_EXPIRATION'),
      }),
    ]);
    return { access_token: at, refresh_token: rt };
  }

  private async updateRefreshToken(userId: string, rt: string) {
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(rt, salt);
    await this.usersService.update(userId, { hashed_refresh_token: hash });
  }

  async forgotPassword(email: string){
    const user = await this.userRepo.findOne({where: { email }});
    if (!user) {
      return { message: 'Nếu email tồn tại, mã OTP đã được gửi!' };
    }

    const otp = Math.floor(100000 + Math.random()*900000).toString();
    const expires = new Date();
    expires.setMinutes(expires.getMinutes() + 10);

    user.reset_otp = otp;
    user.reset_otp_expires = expires;
    await this.userRepo.save(user);

    await this.mailerService.sendMail({
      to: email,
      subject: 'Mã khôi phục mật khẩu SecureHome',
      html: `
        <div style="font-family: sans-serif; text-align: center;">
          <h2>Xin chào!</h2>
          <p>Bác vừa yêu cầu đổi mật khẩu. Mã OTP của bác là:</p>
          <h1 style="color: #003399; letter-spacing: 5px;">${otp}</h1>
          <p>Mã này có hiệu lực trong 10 phút. Đừng chia sẻ cho ai nhé!</p>
        </div>
      `,
    });
    return { message: 'Đã gửi mã OTP qua email!' };
  }

  async resetPassword(email: string, otp: string, newPassword: string) {
    const user = await this.userRepo.findOne({ where: { email } });
    
    if (!user || user.reset_otp !== otp) {
      throw new BadRequestException('Mã OTP không hợp lệ hoặc không tồn tại.');
    }

    if (new Date() > user.reset_otp_expires) {
      throw new BadRequestException('Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.');
    }

    const salt = await bcrypt.genSalt(10);
    user.password_hash = await bcrypt.hash(newPassword, salt);

    user.reset_otp = null as any;
    user.reset_otp_expires = null as any;
    await this.userRepo.save(user);

    return { message: 'Đổi mật khẩu thành công! Vui lòng đăng nhập lại.' };
  }

  async changePassword(userId: string, oldPass: string, newPass: string) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('Người dùng không tồn tại');

    const isMatch = await bcrypt.compare(oldPass, user.password_hash);
    if (!isMatch) {
      throw new BadRequestException('Mật khẩu hiện tại không chính xác!');
    }

    const isSame = await bcrypt.compare(newPass, user.password_hash);
    if (isSame) {
      throw new BadRequestException('Mật khẩu mới không được trùng mật khẩu cũ!');
    }
    const salt = await bcrypt.genSalt(10);
    user.password_hash = await bcrypt.hash(newPass, salt);
    await this.userRepo.save(user);

    return { message: 'Đổi mật khẩu thành công!' };
  }
}