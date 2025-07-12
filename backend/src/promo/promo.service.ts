import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreatePromoDto, UpdatePromoDto } from './dto/promo.dto';
import { User, Role } from '@prisma/client';

@Injectable()
export class PromoService {
  constructor(private prisma: PrismaService) {}

  async create(createPromoDto: CreatePromoDto, user: User) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang dapat membuat promo.');
    }

    const { produkIds, ...promoData } = createPromoDto;

    return this.prisma.promo.create({
      data: {
        ...promoData,
        ownerId: user.id,
        produk: {
          create: produkIds.map((id) => ({
            produk: {
              connect: { id },
            },
          })),
        },
      },
    });
  }

  async findAll(user: User) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang dapat melihat promo.');
    }
    return this.prisma.promo.findMany({
      where: { ownerId: user.id },
      include: {
        produk: {
          include: {
            produk: true, // Sertakan detail produk yang terhubung
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: number, user: User) {
    const promo = await this.prisma.promo.findUnique({
      where: { id },
      include: { produk: { include: { produk: true } } },
    });

    if (!promo || promo.ownerId !== user.id) {
      throw new NotFoundException('Promo tidak ditemukan atau Anda tidak memiliki akses.');
    }
    return promo;
  }

  async update(id: number, updatePromoDto: UpdatePromoDto, user: User) {
    await this.findOne(id, user); // Verifikasi kepemilikan
    const { produkIds, ...promoData } = updatePromoDto;

    return this.prisma.promo.update({
      where: { id },
      data: {
        ...promoData,
        // Jika produkIds disertakan, kita hapus relasi lama dan buat yang baru
        ...(produkIds && {
          produk: {
            deleteMany: {}, // Hapus semua relasi produk yang ada
            create: produkIds.map((produkId) => ({
              produk: {
                connect: { id: produkId },
              },
            })),
          },
        }),
      },
    });
  }

  async remove(id: number, user: User) {
    await this.findOne(id, user); // Verifikasi kepemilikan
    return this.prisma.promo.delete({ where: { id } });
  }
}