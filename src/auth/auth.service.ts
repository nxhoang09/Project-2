import { Injectable, UnauthorizedException, ForbiddenException} from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async login(email: string, pass: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user || !(await bcrypt.compare(pass, user.password_hash))) {
      throw new UnauthorizedException('Sai email hoặc mật khẩu');
    }

    const tokens = await this.getTokens(user.id, user.email);
    await this.updateRefreshToken(user.id, tokens.refresh_token);

    return {
      user: { id: user.id, email: user.email, name: user.full_name },
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
}