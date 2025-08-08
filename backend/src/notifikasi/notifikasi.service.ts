import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { User, TipeNotifikasi } from '@prisma/client';
import { CreateNotifikasiDto, GetNotifikasiDto, MarkAsReadDto } from './dto/notifikasi.dto';

@Injectable()
export class NotifikasiService {
  constructor(private prisma: PrismaService) {}

  // Create notifikasi
  async createNotifikasi(createNotifikasiDto: CreateNotifikasiDto) {
    return this.prisma.notifikasi.create({
      data: createNotifikasiDto,
      include: {
        user: {
          select: { id: true, namaLengkap: true, email: true },
        },
      },
    });
  }

  // Get notifikasi user
  async getNotifikasi(user: User, query: GetNotifikasiDto) {
    const whereClause: any = {
      userId: user.id,
    };

    if (query.isRead !== undefined) {
      whereClause.isRead = query.isRead;
    }

    if (query.tipe) {
      whereClause.tipe = query.tipe;
    }

    const limit = query.limit || 20;
    const offset = query.offset || 0;

    const [notifikasi, total, unreadCount] = await Promise.all([
      this.prisma.notifikasi.findMany({
        where: whereClause,
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.notifikasi.count({ where: whereClause }),
      this.prisma.notifikasi.count({
        where: { userId: user.id, isRead: false },
      }),
    ]);

    return {
      data: notifikasi,
      total,
      unreadCount,
      limit,
      offset,
    };
  }

  // Mark as read
  async markAsRead(user: User, markAsReadDto: MarkAsReadDto) {
    // Pastikan notifikasi milik user
    const notifikasi = await this.prisma.notifikasi.findMany({
      where: {
        id: { in: markAsReadDto.notifikasiIds },
        userId: user.id,
      },
      select: { id: true },
    });

    const validIds = notifikasi.map(n => n.id);

    if (validIds.length === 0) {
      throw new NotFoundException('Notifikasi tidak ditemukan atau tidak bisa diakses');
    }

    return this.prisma.notifikasi.updateMany({
      where: {
        id: { in: validIds },
        userId: user.id,
      },
      data: { isRead: true },
    });
  }

  // Mark all as read
  async markAllAsRead(user: User) {
    return this.prisma.notifikasi.updateMany({
      where: {
        userId: user.id,
        isRead: false,
      },
      data: { isRead: true },
    });
  }

  // Delete notifikasi
  async deleteNotifikasi(user: User, notifikasiId: number) {
    const notifikasi = await this.prisma.notifikasi.findUnique({
      where: { id: notifikasiId },
    });

    if (!notifikasi || notifikasi.userId !== user.id) {
      throw new ForbiddenException('Notifikasi tidak ditemukan atau tidak bisa diakses');
    }

    return this.prisma.notifikasi.delete({
      where: { id: notifikasiId },
    });
  }

  // Helper methods untuk membuat notifikasi otomatis
  async createShiftReminder(userId: number, shiftData: any) {
    return this.createNotifikasi({
      userId,
      tipe: 'SHIFT_REMINDER',
      judul: 'Reminder Shift',
      pesan: `Anda dijadwalkan shift ${shiftData.nama} hari ini dari ${shiftData.jamMulai} - ${shiftData.jamSelesai}`,
      data: JSON.stringify(shiftData),
    });
  }

  async createIzinRequest(ownerId: number, userRequester: User, izinData: any) {
    return this.createNotifikasi({
      userId: ownerId,
      tipe: 'IZIN_REQUEST',
      judul: 'Permohonan Izin Baru',
      pesan: `${userRequester.namaLengkap} mengajukan permohonan ${izinData.tipe.toLowerCase()}`,
      data: JSON.stringify({
        requesterId: userRequester.id,
        requesterName: userRequester.namaLengkap,
        izinId: izinData.id,
        ...izinData,
      }),
    });
  }

  async createIzinResponse(userId: number, isApproved: boolean, izinData: any, approverName: string) {
    const status = isApproved ? 'disetujui' : 'ditolak';
    const tipe: TipeNotifikasi = isApproved ? 'IZIN_APPROVED' : 'IZIN_REJECTED';
    
    return this.createNotifikasi({
      userId,
      tipe,
      judul: `Izin ${status}`,
      pesan: `Permohonan ${izinData.tipe.toLowerCase()} Anda telah ${status} oleh ${approverName}`,
      data: JSON.stringify({
        izinId: izinData.id,
        approverName,
        ...izinData,
      }),
    });
  }

  async createSystemNotification(userId: number, judul: string, pesan: string, data?: any) {
    return this.createNotifikasi({
      userId,
      tipe: 'SYSTEM',
      judul,
      pesan,
      data: data ? JSON.stringify(data) : undefined,
    });
  }

  async createGeneralNotification(userId: number, judul: string, pesan: string, data?: any) {
    return this.createNotifikasi({
      userId,
      tipe: 'GENERAL',
      judul,
      pesan,
      data: data ? JSON.stringify(data) : undefined,
    });
  }

  // Broadcast notifikasi ke semua tim
  async broadcastToTim(ownerId: number, judul: string, pesan: string, data?: any) {
    const timUsers = await this.prisma.user.findMany({
      where: { dikelolaOlehId: ownerId },
      select: { id: true },
    });

    const notifications = [
      // Include owner
      { userId: ownerId, judul, pesan, data: data ? JSON.stringify(data) : undefined },
      // Include tim
      ...timUsers.map(user => ({
        userId: user.id,
        judul,
        pesan,
        data: data ? JSON.stringify(data) : undefined,
      }))
    ];

    return this.prisma.notifikasi.createMany({
      data: notifications.map(notif => ({
        ...notif,
        tipe: 'GENERAL' as TipeNotifikasi,
      })),
    });
  }
}
