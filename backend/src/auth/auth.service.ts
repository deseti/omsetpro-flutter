import {
  Injectable,
  ConflictException,
  UnauthorizedException,
} from '@nestjs/common';
import { RegisterUserDto, LoginUserDto } from './auth.dto';
import { UpdateProfileDto, ChangePasswordDto } from './update-profile.dto';
import { PrismaService } from '../prisma.service';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt'; // Import JwtService

@Injectable()
export class AuthService {
  // Inject JwtService dan PrismaService
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  // Fungsi registrasi (tidak berubah)
  async create(registerUserDto: RegisterUserDto) {
    // ... (kode registrasi yang sudah ada tetap di sini)
    const { email, namaLengkap, password } = registerUserDto;
    const existingUser = await this.prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      throw new ConflictException('Email sudah terdaftar');
    }
    const saltOrRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltOrRounds);
    const user = await this.prisma.user.create({
      data: { email, namaLengkap, password: hashedPassword },
    });
    const { password: _, ...result } = user;
    return {
      message: 'Registrasi berhasil dengan password aman!',
      user: result,
    };
  }

  // --- TAMBAHKAN FUNGSI BARU INI ---
  /**
   * Fungsi untuk memvalidasi login pengguna.
   */
  async login(loginUserDto: LoginUserDto) {
    const { email, password } = loginUserDto;

    // 1. Cari pengguna berdasarkan email
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    // Jika pengguna tidak ditemukan, lempar error
    if (!user) {
      throw new UnauthorizedException('Email atau password salah');
    }

    // 2. Bandingkan password yang dikirim dengan hash di database
    const isPasswordMatch = await bcrypt.compare(password, user.password);

    // Jika password tidak cocok, lempar error
    if (!isPasswordMatch) {
      throw new UnauthorizedException('Email atau password salah');
    }

    // 3. Jika cocok, buat "tiket masuk" (JWT)
    const payload = { sub: user.id, email: user.email };
    const accessToken = await this.jwtService.signAsync(payload);

    // 4. Kirim tiket tersebut ke frontend
    return {
      message: 'Login berhasil!',
      accessToken: accessToken,
    };
  }

  /**
   * Update profil user (nama lengkap)
   */
  async updateProfile(userId: number, updateProfileDto: UpdateProfileDto) {
    const { namaLengkap } = updateProfileDto;

    // Update user
    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: { namaLengkap },
      select: {
        id: true,
        email: true,
        namaLengkap: true,
        role: true,
      },
    });

    return {
      message: 'Profil berhasil diperbarui',
      user: updatedUser,
    };
  }

  /**
   * Ubah password user
   */
  async changePassword(userId: number, changePasswordDto: ChangePasswordDto) {
    const { currentPassword, newPassword } = changePasswordDto;

    // 1. Ambil user beserta password hash
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new UnauthorizedException('User tidak ditemukan');
    }

    // 2. Verifikasi password lama
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isCurrentPasswordValid) {
      throw new UnauthorizedException('Password saat ini salah');
    }

    // 3. Hash password baru
    const saltRounds = 10;
    const hashedNewPassword = await bcrypt.hash(newPassword, saltRounds);

    // 4. Update password
    await this.prisma.user.update({
      where: { id: userId },
      data: { password: hashedNewPassword },
    });

    return {
      message: 'Password berhasil diubah',
    };
  }
}