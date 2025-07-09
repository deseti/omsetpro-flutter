import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../prisma.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private prisma: PrismaService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: 'O8kilXh67IS+dm0TphmXb/vO6Eb75zVeO7JiquvLekn4IXxlR/7ZDwDp5HmYer1QLbjs6AtoAKwbpP6cmWtZNA==', // HARUS SAMA dengan di auth.module.ts
    });
  }

  // Fungsi ini akan otomatis dijalankan oleh Passport setelah token tervalidasi
  async validate(payload: { sub: number; email: string }) {
    // Kita cari pengguna di database berdasarkan ID dari payload token
    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    
    if (!user) {
      throw new UnauthorizedException('User tidak ditemukan.');
    }
    
    // Hapus password dari objek user sebelum dikembalikan
    const { password, ...result } = user;
    
    // Objek yang di-return di sini akan disisipkan ke dalam objek `request`
    return result;
  }
}