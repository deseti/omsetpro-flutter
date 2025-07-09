import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma.service';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport'; // Import PassportModule
import { JwtStrategy } from './jwt.strategy'; // Import JwtStrategy

@Module({
  imports: [
    PassportModule, // Tambahkan ini
    JwtModule.register({
      global: true,
      secret: 'O8kilXh67IS+dm0TphmXb/vO6Eb75zVeO7JiquvLekn4IXxlR/7ZDwDp5HmYer1QLbjs6AtoAKwbpP6cmWtZNA==',
      signOptions: { expiresIn: '1d' },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, PrismaService, JwtStrategy], // Tambahkan JwtStrategy di sini
})
export class AuthModule {}