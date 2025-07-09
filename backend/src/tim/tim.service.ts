import { Injectable, ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { UndangUserDto } from './dto/undang-user.dto';
import { TugaskanAksesDto } from './dto/tugaskan-akses.dto';
import * as bcrypt from 'bcrypt';
import { User, Role } from '@prisma/client';

@Injectable()
export class TimService {
  constructor(private prisma: PrismaService) {}

  // --- LOGIKA BARU DI SINI ---
  async findAll(requestingUser: User) {
    if (requestingUser.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa melihat daftar tim.');
    }

    // Ambil semua user yang 'dikelolaOlehId'-nya adalah ID si Owner
    const users = await this.prisma.user.findMany({
      where: {
        dikelolaOlehId: requestingUser.id,
      },
      include: {
        aksesCabang: {
          include: {
            cabang: true,
          },
        },
      },
    });

    return users.map((user) => {
      const { password, ...result } = user;
      return result;
    });
  }

  // --- LOGIKA BARU DI SINI ---
  async undangUser(dto: UndangUserDto, invitingUser: User) {
    if (invitingUser.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa mengundang pengguna baru.');
    }

    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (existingUser) {
      throw new ConflictException('Email sudah terdaftar.');
    }
    if (dto.role === 'OWNER') {
      throw new ForbiddenException('Tidak bisa mengundang pengguna dengan peran OWNER.');
    }

    const saltOrRounds = 10;
    const hashedPassword = await bcrypt.hash(dto.password, saltOrRounds);

    // Saat membuat user baru, hubungkan ke Owner yang mengundang
    const newUser = await this.prisma.user.create({
      data: {
        email: dto.email,
        namaLengkap: dto.namaLengkap,
        password: hashedPassword,
        role: dto.role,
        dikelolaOlehId: invitingUser.id, // <-- Kunci Multi-Tenancy
      },
    });

    const { password, ...result } = newUser;
    return result;
  }

  // Fungsi tugaskanAkses (tidak berubah)
  async tugaskanAkses(dto: TugaskanAksesDto, assigningUser: User) {
    if (assigningUser.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa menugaskan akses.');
    }
    const userToAssign = await this.prisma.user.findUnique({ where: { id: dto.userId } });
    if (!userToAssign) {
      throw new NotFoundException(`Pengguna dengan ID ${dto.userId} tidak ditemukan.`);
    }
    // Cek tambahan: pastikan Owner hanya bisa menugaskan timnya sendiri
    if (userToAssign.dikelolaOlehId !== assigningUser.id) {
        throw new ForbiddenException('Anda hanya bisa menugaskan anggota tim Anda sendiri.');
    }
    const cabangToAssign = await this.prisma.cabang.findUnique({ where: { id: dto.cabangId } });
    if (!cabangToAssign) {
      throw new NotFoundException(`Cabang dengan ID ${dto.cabangId} tidak ditemukan.`);
    }
    if (cabangToAssign.ownerId !== assigningUser.id) {
      throw new ForbiddenException('Anda bukan pemilik cabang ini.');
    }
    return this.prisma.aksesCabang.create({
      data: {
        userId: dto.userId,
        cabangId: dto.cabangId,
      },
    });
  }
  
  // Fungsi hapusAkses (tidak berubah)
  async hapusAkses(dto: TugaskanAksesDto, assigningUser: User) {
    if (assigningUser.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa mengelola akses.');
    }
    const cabang = await this.prisma.cabang.findUnique({ where: { id: dto.cabangId } });
    if (!cabang || cabang.ownerId !== assigningUser.id) {
        throw new ForbiddenException('Anda tidak memiliki akses ke cabang ini untuk mengelola hak akses.');
    }
    return this.prisma.aksesCabang.delete({
      where: {
        userId_cabangId: {
          userId: dto.userId,
          cabangId: dto.cabangId,
        },
      },
    });
  }
}