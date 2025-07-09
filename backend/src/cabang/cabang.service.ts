import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateCabangDto } from './dto/create-cabang.dto';
import { UpdateCabangDto } from './dto/update-cabang.dto';
import { User, Role } from '@prisma/client'; // Import Role

@Injectable()
export class CabangService {
  constructor(private prisma: PrismaService) {}

  // Membuat cabang baru, hanya bisa dilakukan oleh OWNER
  async create(createCabangDto: CreateCabangDto, user: User) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa membuat cabang baru.');
    }
    return this.prisma.cabang.create({
      data: {
        ...createCabangDto,
        ownerId: user.id, // Hubungkan dengan ID OWNER
      },
    });
  }

  // --- LOGIKA BARU DI SINI ---
  // Menemukan cabang berdasarkan peran pengguna
  async findAll(user: User) {
    // Jika pengguna adalah OWNER, tampilkan semua cabang miliknya
    if (user.role === 'OWNER') {
      return this.prisma.cabang.findMany({
        where: { ownerId: user.id },
      });
    }

    // Jika pengguna adalah ADMIN atau KASIR,
    // tampilkan hanya cabang yang aksesnya telah diberikan kepadanya.
    return this.prisma.cabang.findMany({
      where: {
        aksesPengguna: {
          some: {
            userId: user.id,
          },
        },
      },
    });
  }

  // Menemukan satu cabang spesifik
  async findOne(id: number, user: User) {
    const cabang = await this.prisma.cabang.findUnique({
      where: { id },
    });

    if (!cabang) {
      throw new NotFoundException('Cabang tidak ditemukan');
    }

    // Jika OWNER, cek apakah dia pemilik cabang ini
    if (user.role === 'OWNER') {
      if (cabang.ownerId !== user.id) {
        throw new ForbiddenException('Anda bukan pemilik cabang ini');
      }
      return cabang;
    }

    // Jika ADMIN/KASIR, cek apakah dia punya akses ke cabang ini
    const akses = await this.prisma.aksesCabang.findUnique({
      where: {
        userId_cabangId: {
          userId: user.id,
          cabangId: id,
        },
      },
    });

    if (!akses) {
      throw new ForbiddenException('Anda tidak memiliki akses ke cabang ini');
    }

    return cabang;
  }

  // Mengupdate data cabang
  async update(id: number, updateCabangDto: UpdateCabangDto, user: User) {
    // findOne sudah berisi logika pengecekan hak akses
    await this.findOne(id, user);
    return this.prisma.cabang.update({
      where: { id },
      data: updateCabangDto,
    });
  }

  // Menghapus cabang (hanya OWNER)
  async remove(id: number, user: User) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa menghapus cabang.');
    }
    // findOne akan memastikan OWNER ini adalah pemilik cabang yang benar
    await this.findOne(id, user);
    return this.prisma.cabang.delete({
      where: { id },
    });
  }
}