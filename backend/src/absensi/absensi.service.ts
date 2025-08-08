import { Injectable, ForbiddenException, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { User, AbsensiStatus } from '@prisma/client';
import { CheckInDto, CheckOutDto, UpdateAbsensiDto, GetAbsensiDto } from './dto/absensi.dto';

@Injectable()
export class AbsensiService {
  constructor(private prisma: PrismaService) {}

  // Check-in absensi
  async checkIn(user: User, checkInDto: CheckInDto) {
    // Cek apakah user memiliki akses ke cabang
    if (user.role !== 'OWNER') {
      const akses = await this.prisma.aksesCabang.findFirst({
        where: {
          userId: user.id,
          cabangId: checkInDto.cabangId,
        },
      });

      if (!akses) {
        throw new ForbiddenException('Anda tidak memiliki akses ke cabang ini');
      }
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Cek apakah sudah check-in hari ini
    const existingAbsensi = await this.prisma.absensi.findUnique({
      where: {
        userId_cabangId_tanggal: {
          userId: user.id,
          cabangId: checkInDto.cabangId,
          tanggal: today,
        },
      },
    });

    if (existingAbsensi && existingAbsensi.checkIn) {
      throw new BadRequestException('Anda sudah check-in hari ini');
    }

    const now = new Date();
    
    if (existingAbsensi) {
      // Update existing record
      return this.prisma.absensi.update({
        where: { id: existingAbsensi.id },
        data: {
          checkIn: now,
          status: AbsensiStatus.HADIR,
          catatan: checkInDto.catatan,
        },
      });
    } else {
      // Create new record
      return this.prisma.absensi.create({
        data: {
          userId: user.id,
          cabangId: checkInDto.cabangId,
          tanggal: today,
          checkIn: now,
          status: AbsensiStatus.HADIR,
          catatan: checkInDto.catatan,
        },
      });
    }
  }

  // Check-out absensi
  async checkOut(user: User, checkOutDto: CheckOutDto) {
    const absensi = await this.prisma.absensi.findUnique({
      where: { id: checkOutDto.absensiId },
    });

    if (!absensi) {
      throw new NotFoundException('Data absensi tidak ditemukan');
    }

    if (absensi.userId !== user.id) {
      throw new ForbiddenException('Anda tidak bisa check-out untuk absensi orang lain');
    }

    if (!absensi.checkIn) {
      throw new BadRequestException('Anda belum check-in');
    }

    if (absensi.checkOut) {
      throw new BadRequestException('Anda sudah check-out');
    }

    const now = new Date();
    const updatedCatatan = checkOutDto.catatan 
      ? `${absensi.catatan || ''}${absensi.catatan ? '\n' : ''}Check-out: ${checkOutDto.catatan}`
      : absensi.catatan;

    return this.prisma.absensi.update({
      where: { id: checkOutDto.absensiId },
      data: {
        checkOut: now,
        catatan: updatedCatatan,
      },
    });
  }

  // Get riwayat absensi
  async getRiwayatAbsensi(user: User, query: GetAbsensiDto) {
    const whereClause: any = {};

    // Filter berdasarkan role
    if (user.role === 'OWNER') {
      // Owner bisa melihat semua absensi tim-nya
      const timIds = await this.prisma.user.findMany({
        where: { dikelolaOlehId: user.id },
        select: { id: true },
      });
      const userIds = [user.id, ...timIds.map(t => t.id)];
      whereClause.userId = { in: userIds };
    } else {
      // Admin/Kasir hanya bisa melihat absensi sendiri
      whereClause.userId = user.id;
    }

    // Filter tambahan dari query
    if (query.cabangId) whereClause.cabangId = query.cabangId;
    if (query.userId && user.role === 'OWNER') whereClause.userId = query.userId;
    if (query.status) whereClause.status = query.status;

    if (query.tanggalMulai || query.tanggalSelesai) {
      whereClause.tanggal = {};
      if (query.tanggalMulai) {
        whereClause.tanggal.gte = new Date(query.tanggalMulai);
      }
      if (query.tanggalSelesai) {
        whereClause.tanggal.lte = new Date(query.tanggalSelesai);
      }
    }

    return this.prisma.absensi.findMany({
      where: whereClause,
      include: {
        user: {
          select: {
            id: true,
            namaLengkap: true,
            email: true,
            role: true,
          },
        },
        cabang: {
          select: {
            id: true,
            nama: true,
          },
        },
      },
      orderBy: [
        { tanggal: 'desc' },
        { createdAt: 'desc' },
      ],
    });
  }

  // Update status absensi (untuk OWNER)
  async updateStatusAbsensi(user: User, absensiId: number, updateDto: UpdateAbsensiDto) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa mengubah status absensi');
    }

    const absensi = await this.prisma.absensi.findUnique({
      where: { id: absensiId },
      include: { user: true },
    });

    if (!absensi) {
      throw new NotFoundException('Data absensi tidak ditemukan');
    }

    // Pastikan absensi adalah milik tim owner
    if (absensi.user.dikelolaOlehId !== user.id && absensi.user.id !== user.id) {
      throw new ForbiddenException('Anda tidak bisa mengubah absensi user ini');
    }

    return this.prisma.absensi.update({
      where: { id: absensiId },
      data: {
        status: updateDto.status,
        catatan: updateDto.catatan || absensi.catatan,
      },
    });
  }

  // Get absensi hari ini untuk user
  async getAbsensiHariIni(user: User, cabangId: number) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return this.prisma.absensi.findUnique({
      where: {
        userId_cabangId_tanggal: {
          userId: user.id,
          cabangId: cabangId,
          tanggal: today,
        },
      },
      include: {
        cabang: {
          select: {
            id: true,
            nama: true,
          },
        },
      },
    });
  }
}
