import { Injectable, ForbiddenException, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { User } from '@prisma/client';
import { CreateGajiTimDto, UpdateGajiTimDto, GetLaporanGajiDto } from './dto/gaji.dto';

@Injectable()
export class GajiService {
  constructor(private prisma: PrismaService) {}

  // Create/Set gaji untuk anggota tim
  async createGajiTim(user: User, createGajiDto: CreateGajiTimDto) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa mengatur gaji tim');
    }

    // Cek apakah target user adalah anggota tim
    const targetUser = await this.prisma.user.findUnique({
      where: { id: createGajiDto.userId },
    });

    if (!targetUser || targetUser.dikelolaOlehId !== user.id) {
      throw new ForbiddenException('User bukan anggota tim Anda');
    }

    // Cek apakah sudah ada pengaturan gaji
    const existingGaji = await this.prisma.gajiTim.findUnique({
      where: { userId: createGajiDto.userId },
    });

    if (existingGaji) {
      throw new BadRequestException('User sudah memiliki pengaturan gaji. Gunakan endpoint update.');
    }

    return this.prisma.gajiTim.create({
      data: {
        userId: createGajiDto.userId,
        gajiPokok: createGajiDto.gajiPokok,
        komisiPersen: createGajiDto.komisiPersen || 0,
        komisiNominal: createGajiDto.komisiNominal || 0,
        tunjangan: createGajiDto.tunjangan || 0,
      },
      include: {
        user: {
          select: { id: true, namaLengkap: true, email: true, role: true },
        },
      },
    });
  }

  // Update gaji tim
  async updateGajiTim(user: User, userId: number, updateGajiDto: UpdateGajiTimDto) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa mengupdate gaji tim');
    }

    const gajiTim = await this.prisma.gajiTim.findUnique({
      where: { userId },
      include: { user: true },
    });

    if (!gajiTim) {
      throw new NotFoundException('Pengaturan gaji tidak ditemukan');
    }

    if (gajiTim.user.dikelolaOlehId !== user.id && gajiTim.user.id !== user.id) {
      throw new ForbiddenException('Anda tidak bisa mengupdate gaji user ini');
    }

    return this.prisma.gajiTim.update({
      where: { userId },
      data: updateGajiDto,
      include: {
        user: {
          select: { id: true, namaLengkap: true, email: true, role: true },
        },
      },
    });
  }

  // Get daftar gaji tim
  async getGajiTim(user: User) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa melihat gaji tim');
    }

    // Get semua tim owner
    const timIds = await this.prisma.user.findMany({
      where: { dikelolaOlehId: user.id },
      select: { id: true },
    });
    const userIds = [user.id, ...timIds.map(t => t.id)];

    return this.prisma.gajiTim.findMany({
      where: {
        userId: { in: userIds },
        isActive: true,
      },
      include: {
        user: {
          select: { id: true, namaLengkap: true, email: true, role: true },
        },
      },
      orderBy: { user: { namaLengkap: 'asc' } },
    });
  }

  // Get gaji user sendiri
  async getMyGaji(user: User) {
    return this.prisma.gajiTim.findUnique({
      where: { userId: user.id },
      include: {
        user: {
          select: { id: true, namaLengkap: true, email: true, role: true },
        },
      },
    });
  }

  // Calculate laporan gaji bulanan
  async getLaporanGaji(user: User, query: GetLaporanGajiDto) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa melihat laporan gaji');
    }

    const currentDate = new Date();
    const tahun = query.tahun || currentDate.getFullYear();
    const bulan = query.bulan || currentDate.getMonth() + 1;

    // Tanggal awal dan akhir bulan
    const startDate = new Date(tahun, bulan - 1, 1);
    const endDate = new Date(tahun, bulan, 0, 23, 59, 59);

    // Get tim IDs
    const timIds = await this.prisma.user.findMany({
      where: { dikelolaOlehId: user.id },
      select: { id: true },
    });
    let userIds = [user.id, ...timIds.map(t => t.id)];

    if (query.userId && userIds.includes(query.userId)) {
      userIds = [query.userId];
    }

    // Get data gaji dan transaksi
    const results = await Promise.all(
      userIds.map(async (userId) => {
        const gajiTim = await this.prisma.gajiTim.findUnique({
          where: { userId },
          include: {
            user: {
              select: { id: true, namaLengkap: true, email: true, role: true },
            },
          },
        });

        if (!gajiTim) return null;

        // Hitung transaksi dalam periode
        const whereClause: any = {
          kasirId: userId,
          createdAt: {
            gte: startDate,
            lte: endDate,
          },
          status: 'paid', // Hanya transaksi yang sudah dibayar
        };

        if (query.cabangId) {
          whereClause.cabangId = query.cabangId;
        }

        const [transaksiCount, totalPenjualan] = await Promise.all([
          this.prisma.transaksi.count({ where: whereClause }),
          this.prisma.transaksi.aggregate({
            where: whereClause,
            _sum: { total: true },
          }),
        ]);

        // Hitung absensi dalam periode
        const absensiStats = await this.prisma.absensi.groupBy({
          by: ['status'],
          where: {
            userId,
            tanggal: {
              gte: startDate,
              lte: endDate,
            },
          },
          _count: { status: true },
        });

        // Hitung komisi
        const penjualan = totalPenjualan._sum.total || 0;
        const komisiPersen = (penjualan * gajiTim.komisiPersen) / 100;
        const komisiNominal = transaksiCount * gajiTim.komisiNominal;
        const totalKomisi = komisiPersen + komisiNominal;

        // Total gaji
        const totalGaji = gajiTim.gajiPokok + totalKomisi + gajiTim.tunjangan;

        return {
          user: gajiTim.user,
          gajiPokok: gajiTim.gajiPokok,
          tunjangan: gajiTim.tunjangan,
          komisiPersen: gajiTim.komisiPersen,
          komisiNominal: gajiTim.komisiNominal,
          periode: { bulan, tahun },
          performa: {
            totalTransaksi: transaksiCount,
            totalPenjualan: penjualan,
            komisiPersen,
            komisiNominal,
            totalKomisi,
          },
          absensi: absensiStats.reduce((acc, stat) => {
            acc[stat.status] = stat._count.status;
            return acc;
          }, {} as Record<string, number>),
          totalGaji,
        };
      })
    );

    return results.filter(Boolean);
  }

  // Delete pengaturan gaji
  async deleteGajiTim(user: User, userId: number) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa menghapus pengaturan gaji');
    }

    const gajiTim = await this.prisma.gajiTim.findUnique({
      where: { userId },
      include: { user: true },
    });

    if (!gajiTim) {
      throw new NotFoundException('Pengaturan gaji tidak ditemukan');
    }

    if (gajiTim.user.dikelolaOlehId !== user.id && gajiTim.user.id !== user.id) {
      throw new ForbiddenException('Anda tidak bisa menghapus pengaturan gaji user ini');
    }

    return this.prisma.gajiTim.delete({
      where: { userId },
    });
  }
}
