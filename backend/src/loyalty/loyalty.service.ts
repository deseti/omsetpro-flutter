import { Injectable, ForbiddenException, NotFoundException, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { User, Role } from '@prisma/client';
import { SetLoyaltyRuleDto, CreateRewardDto, UpdateRewardDto, RedeemRewardDto } from './dto/loyalty.dto';

@Injectable()
export class LoyaltyService {
  constructor(private prisma: PrismaService) {}

  // Mengatur atau memperbarui aturan perolehan poin untuk seorang Owner
  async setRule(dto: SetLoyaltyRuleDto, user: User) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang dapat mengatur aturan loyalitas.');
    }
    return this.prisma.loyaltyRule.upsert({
      where: { ownerId: user.id },
      update: { ...dto },
      create: { ...dto, ownerId: user.id },
    });
  }

  // Mendapatkan aturan poin yang berlaku untuk seorang Owner
  async getRule(user: User) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang dapat melihat aturan loyalitas.');
    }
    return this.prisma.loyaltyRule.findUnique({
      where: { ownerId: user.id },
    });
  }

  // Membuat hadiah baru di katalog
  async createReward(dto: CreateRewardDto, user: User) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang dapat menambah hadiah.');
    }
    return this.prisma.reward.create({
      data: {
        ...dto,
        ownerId: user.id,
      },
    });
  }

  // Menemukan semua hadiah yang dimiliki seorang Owner
  async findAllRewards(user: User) {
    const ownerId = user.role === 'OWNER' ? user.id : user.dikelolaOlehId;

    // [PERBAIKAN] Tambahkan pengecekan untuk memastikan ownerId tidak null
    if (!ownerId) {
      throw new UnauthorizedException('Tidak dapat menentukan ID Owner untuk pengguna ini.');
    }

    return this.prisma.reward.findMany({
      where: { ownerId }, // Sekarang ownerId dijamin bukan null
      orderBy: { poinDibutuhkan: 'asc' },
    });
  }

  // Memperbarui data hadiah
  async updateReward(id: number, dto: UpdateRewardDto, user: User) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang dapat mengubah hadiah.');
    }
    const reward = await this.prisma.reward.findUnique({ where: { id } });
    if (!reward || reward.ownerId !== user.id) {
      throw new NotFoundException('Hadiah tidak ditemukan atau Anda tidak memiliki akses.');
    }
    return this.prisma.reward.update({
      where: { id },
      data: dto,
    });
  }

  // Menukarkan poin pelanggan dengan hadiah
  async redeemReward(dto: RedeemRewardDto, user: User) {
    const ownerId = user.role === 'OWNER' ? user.id : user.dikelolaOlehId;

    // [PERBAIKAN] Tambahkan pengecekan untuk memastikan ownerId tidak null
    if (!ownerId) {
      throw new UnauthorizedException('Tidak dapat menentukan ID Owner untuk pengguna ini.');
    }

    return this.prisma.$transaction(async (tx) => {
      // 1. Dapatkan data pelanggan dan hadiah
      const pelanggan = await tx.pelanggan.findUnique({ where: { id: dto.pelangganId } });
      const reward = await tx.reward.findUnique({ where: { id: dto.rewardId } });

      // 2. Validasi
      if (!pelanggan || pelanggan.ownerId !== ownerId) {
        throw new NotFoundException('Pelanggan tidak ditemukan.');
      }
      if (!reward || reward.ownerId !== ownerId) {
        throw new NotFoundException('Hadiah tidak ditemukan.');
      }
      if (!reward.isActive) {
        throw new BadRequestException('Hadiah ini sedang tidak aktif.');
      }
      if (pelanggan.totalPoin < reward.poinDibutuhkan) {
        throw new BadRequestException('Poin pelanggan tidak mencukupi.');
      }

      // 3. Kurangi poin pelanggan
      const updatedPelanggan = await tx.pelanggan.update({
        where: { id: dto.pelangganId },
        data: {
          totalPoin: {
            decrement: reward.poinDibutuhkan,
          },
        },
      });

      // 4. Catat riwayat penukaran
      await tx.pointHistory.create({
        data: {
          pelangganId: dto.pelangganId,
          poin: -reward.poinDibutuhkan, // Poin negatif karena ditukar
          tipe: 'REDEEMED',
          deskripsi: `Menukar hadiah: ${reward.namaHadiah}`,
        },
      });

      return {
        message: 'Penukaran poin berhasil!',
        pelanggan: updatedPelanggan,
      };
    });
  }
}