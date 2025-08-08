import { Injectable, ForbiddenException, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { User, TipeIzin, StatusIzin } from '@prisma/client';
import { CreateIzinTimDto, UpdateStatusIzinDto, GetIzinTimDto } from './dto/izin.dto';

@Injectable()
export class IzinService {
  constructor(private prisma: PrismaService) {}

  // Create izin (untuk tim/karyawan)
  async createIzinTim(user: User, createIzinDto: CreateIzinTimDto) {
    // Validasi tanggal
    const tanggalMulai = new Date(createIzinDto.tanggalMulai);
    const tanggalSelesai = new Date(createIzinDto.tanggalSelesai);

    if (tanggalMulai > tanggalSelesai) {
      throw new BadRequestException('Tanggal mulai tidak boleh lebih besar dari tanggal selesai');
    }

    // Cek apakah sudah ada izin yang overlap
    const existingIzin = await this.prisma.izinTim.findFirst({
      where: {
        userId: user.id,
        status: { in: ['PENDING', 'APPROVED'] },
        OR: [
          {
            tanggalMulai: { lte: tanggalSelesai },
            tanggalSelesai: { gte: tanggalMulai },
          },
        ],
      },
    });

    if (existingIzin) {
      throw new BadRequestException('Anda sudah memiliki izin yang overlap dengan tanggal tersebut');
    }

    return this.prisma.izinTim.create({
      data: {
        userId: user.id,
        tipe: createIzinDto.tipe,
        tanggalMulai,
        tanggalSelesai,
        alasan: createIzinDto.alasan,
      },
      include: {
        user: {
          select: { id: true, namaLengkap: true, email: true, role: true },
        },
      },
    });
  }

  // Get izin tim
  async getIzinTim(user: User, query: GetIzinTimDto) {
    const whereClause: any = {};

    // Filter berdasarkan role
    if (user.role === 'OWNER') {
      // Owner bisa melihat izin semua timnya
      const timIds = await this.prisma.user.findMany({
        where: { dikelolaOlehId: user.id },
        select: { id: true },
      });
      const userIds = [user.id, ...timIds.map(t => t.id)];
      whereClause.userId = { in: userIds };
    } else {
      // Admin/Kasir hanya bisa melihat izin sendiri
      whereClause.userId = user.id;
    }

    // Filter tambahan
    if (query.userId && user.role === 'OWNER') whereClause.userId = query.userId;
    if (query.tipe) whereClause.tipe = query.tipe;
    if (query.status) whereClause.status = query.status;

    if (query.tanggalMulai || query.tanggalSelesai) {
      whereClause.OR = [
        {
          tanggalMulai: {
            gte: query.tanggalMulai ? new Date(query.tanggalMulai) : undefined,
            lte: query.tanggalSelesai ? new Date(query.tanggalSelesai) : undefined,
          },
        },
        {
          tanggalSelesai: {
            gte: query.tanggalMulai ? new Date(query.tanggalMulai) : undefined,
            lte: query.tanggalSelesai ? new Date(query.tanggalSelesai) : undefined,
          },
        },
      ];
    }

    return this.prisma.izinTim.findMany({
      where: whereClause,
      include: {
        user: {
          select: { id: true, namaLengkap: true, email: true, role: true },
        },
        approver: {
          select: { id: true, namaLengkap: true, email: true },
        },
      },
      orderBy: [
        { createdAt: 'desc' },
      ],
    });
  }

  // Update status izin (untuk OWNER)
  async updateStatusIzin(user: User, izinId: number, updateDto: UpdateStatusIzinDto) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa mengupdate status izin');
    }

    const izinTim = await this.prisma.izinTim.findUnique({
      where: { id: izinId },
      include: { user: true },
    });

    if (!izinTim) {
      throw new NotFoundException('Izin tidak ditemukan');
    }

    // Pastikan izin adalah milik tim owner
    if (izinTim.user.dikelolaOlehId !== user.id && izinTim.user.id !== user.id) {
      throw new ForbiddenException('Anda tidak bisa mengupdate izin user ini');
    }

    if (izinTim.status !== 'PENDING') {
      throw new BadRequestException('Izin sudah diproses sebelumnya');
    }

    const now = new Date();

    return this.prisma.izinTim.update({
      where: { id: izinId },
      data: {
        status: updateDto.status,
        approvedBy: user.id,
        approvedAt: now,
        catatan: updateDto.catatan,
      },
      include: {
        user: {
          select: { id: true, namaLengkap: true, email: true, role: true },
        },
        approver: {
          select: { id: true, namaLengkap: true, email: true },
        },
      },
    });
  }

  // Get izin pending (untuk OWNER)
  async getIzinPending(user: User) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa melihat izin pending');
    }

    const timIds = await this.prisma.user.findMany({
      where: { dikelolaOlehId: user.id },
      select: { id: true },
    });
    const userIds = timIds.map(t => t.id); // Tidak termasuk owner sendiri untuk approval

    return this.prisma.izinTim.findMany({
      where: {
        userId: { in: userIds },
        status: 'PENDING',
      },
      include: {
        user: {
          select: { id: true, namaLengkap: true, email: true, role: true },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  // Delete izin (hanya bisa menghapus izin sendiri dan masih PENDING)
  async deleteIzinTim(user: User, izinId: number) {
    const izinTim = await this.prisma.izinTim.findUnique({
      where: { id: izinId },
    });

    if (!izinTim) {
      throw new NotFoundException('Izin tidak ditemukan');
    }

    // Hanya bisa menghapus izin sendiri atau owner bisa menghapus izin timnya
    if (izinTim.userId !== user.id && user.role !== 'OWNER') {
      throw new ForbiddenException('Anda tidak bisa menghapus izin ini');
    }

    if (user.role === 'OWNER') {
      const targetUser = await this.prisma.user.findUnique({
        where: { id: izinTim.userId },
      });

      if (targetUser?.dikelolaOlehId !== user.id && targetUser?.id !== user.id) {
        throw new ForbiddenException('Anda tidak bisa menghapus izin user ini');
      }
    }

    if (izinTim.status !== 'PENDING') {
      throw new BadRequestException('Hanya bisa menghapus izin yang masih pending');
    }

    return this.prisma.izinTim.delete({
      where: { id: izinId },
    });
  }

  // Get statistik izin (untuk OWNER)
  async getStatistikIzin(user: User, tahun?: number, bulan?: number) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa melihat statistik izin');
    }

    const currentDate = new Date();
    const targetTahun = tahun || currentDate.getFullYear();
    const targetBulan = bulan || currentDate.getMonth() + 1;

    const startDate = new Date(targetTahun, targetBulan - 1, 1);
    const endDate = new Date(targetTahun, targetBulan, 0, 23, 59, 59);

    const timIds = await this.prisma.user.findMany({
      where: { dikelolaOlehId: user.id },
      select: { id: true },
    });
    const userIds = [user.id, ...timIds.map(t => t.id)];

    const [totalIzin, statusStats, tipeStats] = await Promise.all([
      this.prisma.izinTim.count({
        where: {
          userId: { in: userIds },
          tanggalMulai: { gte: startDate, lte: endDate },
        },
      }),
      this.prisma.izinTim.groupBy({
        by: ['status'],
        where: {
          userId: { in: userIds },
          tanggalMulai: { gte: startDate, lte: endDate },
        },
        _count: { status: true },
      }),
      this.prisma.izinTim.groupBy({
        by: ['tipe'],
        where: {
          userId: { in: userIds },
          tanggalMulai: { gte: startDate, lte: endDate },
        },
        _count: { tipe: true },
      }),
    ]);

    return {
      periode: { bulan: targetBulan, tahun: targetTahun },
      totalIzin,
      statusStats: statusStats.reduce((acc, stat) => {
        acc[stat.status] = stat._count.status;
        return acc;
      }, {} as Record<string, number>),
      tipeStats: tipeStats.reduce((acc, stat) => {
        acc[stat.tipe] = stat._count.tipe;
        return acc;
      }, {} as Record<string, number>),
    };
  }
}
