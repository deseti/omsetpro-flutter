import { Injectable, ForbiddenException, ConflictException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreatePelangganDto } from './dto/create-pelanggan.dto';
import { User, Role } from '@prisma/client';

@Injectable()
export class PelangganService {
  constructor(private prisma: PrismaService) {}

  /**
   * Membuat pelanggan baru. Hanya bisa dilakukan oleh OWNER.
   * Pelanggan terikat dengan Owner, bukan cabang.
   * @param createPelangganDto Data pelanggan baru
   * @param user User yang melakukan request (OWNER)
   */
  async create(createPelangganDto: CreatePelangganDto, user: User) {
    // Owner bisa membuat pelanggan baru
    // Admin dan Kasir juga bisa, tapi mereka terikat pada Owner dari user yang mengundang mereka
    const ownerId = user.role === 'OWNER' ? user.id : user.dikelolaOlehId;

    if (!ownerId) {
        throw new UnauthorizedException('Tidak dapat menentukan ID Owner untuk pengguna ini.');
    }

    const existingPelanggan = await this.prisma.pelanggan.findUnique({
      where: {
        ownerId_noHp: {
          ownerId: ownerId,
          noHp: createPelangganDto.noHp,
        },
      },
    });

    if (existingPelanggan) {
      throw new ConflictException('Nomor HP pelanggan sudah terdaftar.');
    }

    return this.prisma.pelanggan.create({
      data: {
        ...createPelangganDto,
        ownerId: ownerId,
      },
    });
  }

  /**
   * Menemukan semua pelanggan yang dimiliki oleh seorang OWNER.
   * @param user User yang melakukan request (OWNER)
   */

  async findAll(user: User) {
    // Hanya OWNER yang bisa melihat semua pelanggan
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang dapat melihat daftar pelanggan.');
    }

    return this.prisma.pelanggan.findMany({
      where: {
        ownerId: user.id,
      },
      orderBy: {
        nama: 'asc',
      },
    });
  }

  /**
   * [BARU] Mencari pelanggan berdasarkan nama atau nomor HP.
   * Bisa diakses oleh semua role (Owner, Admin, Kasir).
   * @param query Kata kunci pencarian
   * @param user User yang melakukan request
   */
  async search(query: string, user: User) {
    const ownerId = user.role === 'OWNER' ? user.id : user.dikelolaOlehId;

     if (!ownerId) {
        throw new UnauthorizedException('Tidak dapat menentukan ID Owner untuk pengguna ini.');
    }
    
    return this.prisma.pelanggan.findMany({
      where: {
        ownerId: ownerId,
        OR: [
          {
            nama: {
              contains: query,
              // mode: 'insensitive' dihapus karena tidak didukung oleh SQLite.
              // Pencarian nama akan menjadi case-sensitive.
            },
          },
          {
            noHp: {
              contains: query,
            },
          },
        ],
      },
      take: 10, // Batasi hasil pencarian
    });
  }

  // Tambahkan fungsi findOne, update, dan remove di sini nanti
}