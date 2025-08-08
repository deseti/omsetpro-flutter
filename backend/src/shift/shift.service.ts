import { Injectable, ForbiddenException, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { User } from '@prisma/client';
import { CreateShiftDto, UpdateShiftDto, CreateJadwalTimDto, GetJadwalDto } from './dto/shift.dto';

@Injectable()
export class ShiftService {
  constructor(private prisma: PrismaService) {}

  // CRUD Shift
  async createShift(user: User, createShiftDto: CreateShiftDto) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa membuat shift');
    }

    // Cek apakah cabang milik owner
    const cabang = await this.prisma.cabang.findUnique({
      where: { id: createShiftDto.cabangId },
    });

    if (!cabang || cabang.ownerId !== user.id) {
      throw new ForbiddenException('Anda tidak memiliki akses ke cabang ini');
    }

    return this.prisma.shift.create({
      data: createShiftDto,
      include: {
        cabang: {
          select: { id: true, nama: true },
        },
      },
    });
  }

  async getShifts(user: User, cabangId?: number) {
    const whereClause: any = {};

    if (user.role === 'OWNER') {
      // Owner bisa melihat shift di cabang miliknya
      const cabangIds = await this.prisma.cabang.findMany({
        where: { ownerId: user.id },
        select: { id: true },
      });
      whereClause.cabangId = { in: cabangIds.map(c => c.id) };
    } else {
      // Admin/Kasir hanya bisa melihat shift di cabang yang bisa diakses
      const akses = await this.prisma.aksesCabang.findMany({
        where: { userId: user.id },
        select: { cabangId: true },
      });
      whereClause.cabangId = { in: akses.map(a => a.cabangId) };
    }

    if (cabangId) {
      whereClause.cabangId = cabangId;
    }

    return this.prisma.shift.findMany({
      where: whereClause,
      include: {
        cabang: {
          select: { id: true, nama: true },
        },
        jadwalTim: {
          include: {
            user: {
              select: { id: true, namaLengkap: true, email: true },
            },
          },
        },
      },
      orderBy: { nama: 'asc' },
    });
  }

  async updateShift(user: User, shiftId: number, updateShiftDto: UpdateShiftDto) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa mengupdate shift');
    }

    const shift = await this.prisma.shift.findUnique({
      where: { id: shiftId },
      include: { cabang: true },
    });

    if (!shift) {
      throw new NotFoundException('Shift tidak ditemukan');
    }

    if (shift.cabang.ownerId !== user.id) {
      throw new ForbiddenException('Anda tidak bisa mengupdate shift ini');
    }

    return this.prisma.shift.update({
      where: { id: shiftId },
      data: updateShiftDto,
      include: {
        cabang: {
          select: { id: true, nama: true },
        },
      },
    });
  }

  async deleteShift(user: User, shiftId: number) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa menghapus shift');
    }

    const shift = await this.prisma.shift.findUnique({
      where: { id: shiftId },
      include: { cabang: true },
    });

    if (!shift) {
      throw new NotFoundException('Shift tidak ditemukan');
    }

    if (shift.cabang.ownerId !== user.id) {
      throw new ForbiddenException('Anda tidak bisa menghapus shift ini');
    }

    return this.prisma.shift.delete({
      where: { id: shiftId },
    });
  }

  // CRUD Jadwal Tim
  async createJadwalTim(user: User, createJadwalDto: CreateJadwalTimDto) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa membuat jadwal tim');
    }

    // Cek apakah shift dan user valid
    const shift = await this.prisma.shift.findUnique({
      where: { id: createJadwalDto.shiftId },
      include: { cabang: true },
    });

    if (!shift || shift.cabang.ownerId !== user.id) {
      throw new ForbiddenException('Shift tidak valid atau tidak bisa diakses');
    }

    const targetUser = await this.prisma.user.findUnique({
      where: { id: createJadwalDto.userId },
    });

    if (!targetUser || targetUser.dikelolaOlehId !== user.id) {
      throw new ForbiddenException('User tidak valid atau bukan anggota tim Anda');
    }

    // Cek apakah user sudah memiliki jadwal di tanggal tersebut
    const tanggal = new Date(createJadwalDto.tanggal);
    const existingJadwal = await this.prisma.jadwalTim.findUnique({
      where: {
        userId_tanggal: {
          userId: createJadwalDto.userId,
          tanggal: tanggal,
        },
      },
    });

    if (existingJadwal) {
      throw new BadRequestException('User sudah memiliki jadwal di tanggal tersebut');
    }

    return this.prisma.jadwalTim.create({
      data: {
        userId: createJadwalDto.userId,
        shiftId: createJadwalDto.shiftId,
        tanggal: tanggal,
      },
      include: {
        user: {
          select: { id: true, namaLengkap: true, email: true },
        },
        shift: {
          include: {
            cabang: {
              select: { id: true, nama: true },
            },
          },
        },
      },
    });
  }

  async getJadwalTim(user: User, query: GetJadwalDto) {
    const whereClause: any = {};

    // Filter berdasarkan role
    if (user.role === 'OWNER') {
      // Owner bisa melihat jadwal semua timnya
      const timIds = await this.prisma.user.findMany({
        where: { dikelolaOlehId: user.id },
        select: { id: true },
      });
      const userIds = [user.id, ...timIds.map(t => t.id)];
      whereClause.userId = { in: userIds };
    } else {
      // Admin/Kasir hanya bisa melihat jadwal sendiri
      whereClause.userId = user.id;
    }

    // Filter tambahan
    if (query.userId && user.role === 'OWNER') whereClause.userId = query.userId;
    if (query.shiftId) whereClause.shiftId = query.shiftId;

    if (query.tanggalMulai || query.tanggalSelesai) {
      whereClause.tanggal = {};
      if (query.tanggalMulai) {
        whereClause.tanggal.gte = new Date(query.tanggalMulai);
      }
      if (query.tanggalSelesai) {
        whereClause.tanggal.lte = new Date(query.tanggalSelesai);
      }
    }

    // Filter cabang
    if (query.cabangId) {
      whereClause.shift = {
        cabangId: query.cabangId,
      };
    }

    return this.prisma.jadwalTim.findMany({
      where: whereClause,
      include: {
        user: {
          select: { id: true, namaLengkap: true, email: true, role: true },
        },
        shift: {
          include: {
            cabang: {
              select: { id: true, nama: true },
            },
          },
        },
      },
      orderBy: [
        { tanggal: 'asc' },
        { shift: { jamMulai: 'asc' } },
      ],
    });
  }

  async deleteJadwalTim(user: User, jadwalId: number) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa menghapus jadwal');
    }

    const jadwal = await this.prisma.jadwalTim.findUnique({
      where: { id: jadwalId },
      include: { 
        user: true,
        shift: { include: { cabang: true } }
      },
    });

    if (!jadwal) {
      throw new NotFoundException('Jadwal tidak ditemukan');
    }

    if (jadwal.user.dikelolaOlehId !== user.id && jadwal.user.id !== user.id) {
      throw new ForbiddenException('Anda tidak bisa menghapus jadwal ini');
    }

    return this.prisma.jadwalTim.delete({
      where: { id: jadwalId },
    });
  }

  // Get jadwal hari ini untuk user
  async getJadwalHariIni(user: User) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return this.prisma.jadwalTim.findUnique({
      where: {
        userId_tanggal: {
          userId: user.id,
          tanggal: today,
        },
      },
      include: {
        shift: {
          include: {
            cabang: {
              select: { id: true, nama: true },
            },
          },
        },
      },
    });
  }
}
