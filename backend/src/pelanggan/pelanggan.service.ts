import { Injectable, ForbiddenException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreatePelangganDto } from './dto/create-pelanggan.dto';
import { User } from '@prisma/client';

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
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang dapat menambah pelanggan.');
    }

    // Cek apakah nomor HP sudah terdaftar untuk owner ini
    const existingPelanggan = await this.prisma.pelanggan.findUnique({
      where: {
        ownerId_noHp: {
          ownerId: user.id,
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
        ownerId: user.id, // Menghubungkan pelanggan dengan OWNER
      },
    });
  }

  /**
   * Menemukan semua pelanggan yang dimiliki oleh seorang OWNER.
   * @param user User yang melakukan request (OWNER)
   */
  async findAll(user: User) {
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

  // Tambahkan fungsi findOne, update, dan remove di sini nanti
}