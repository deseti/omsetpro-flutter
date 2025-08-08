import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { User } from '@prisma/client';
import { CreateAuditLogDto, GetAuditLogDto } from './dto/audit.dto';

@Injectable()
export class AuditService {
  constructor(private prisma: PrismaService) {}

  // Create audit log (akan dipanggil otomatis dari berbagai service)
  async createAuditLog(userId: number, auditData: CreateAuditLogDto, ipAddress?: string, userAgent?: string) {
    return this.prisma.auditLog.create({
      data: {
        userId,
        aksi: auditData.aksi,
        modul: auditData.modul,
        detail: auditData.detail,
        ipAddress,
        userAgent,
      },
    });
  }

  // Get audit logs (hanya untuk OWNER)
  async getAuditLogs(user: User, query: GetAuditLogDto) {
    if (user.role !== 'OWNER') {
      throw new ForbiddenException('Hanya OWNER yang bisa melihat audit log');
    }

    const whereClause: any = {};

    // Owner hanya bisa melihat audit log tim-nya
    const timIds = await this.prisma.user.findMany({
      where: { dikelolaOlehId: user.id },
      select: { id: true },
    });
    const userIds = [user.id, ...timIds.map(t => t.id)];
    whereClause.userId = { in: userIds };

    // Filter tambahan
    if (query.userId && userIds.includes(query.userId)) {
      whereClause.userId = query.userId;
    }
    if (query.aksi) whereClause.aksi = { contains: query.aksi };
    if (query.modul) whereClause.modul = query.modul;

    if (query.tanggalMulai || query.tanggalSelesai) {
      whereClause.createdAt = {};
      if (query.tanggalMulai) {
        whereClause.createdAt.gte = new Date(query.tanggalMulai);
      }
      if (query.tanggalSelesai) {
        whereClause.createdAt.lte = new Date(query.tanggalSelesai);
      }
    }

    const limit = query.limit || 50;
    const offset = query.offset || 0;

    const [logs, total] = await Promise.all([
      this.prisma.auditLog.findMany({
        where: whereClause,
        include: {
          user: {
            select: { id: true, namaLengkap: true, email: true, role: true },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.auditLog.count({ where: whereClause }),
    ]);

    return {
      data: logs,
      total,
      limit,
      offset,
    };
  }

  // Helper method untuk log aktivitas umum
  async logActivity(
    userId: number, 
    aksi: string, 
    modul: string, 
    detail?: any,
    ipAddress?: string,
    userAgent?: string
  ) {
    const detailString = detail ? JSON.stringify(detail) : undefined;
    
    return this.createAuditLog(
      userId,
      { aksi, modul, detail: detailString },
      ipAddress,
      userAgent
    );
  }

  // Log khusus untuk login
  async logLogin(userId: number, ipAddress?: string, userAgent?: string) {
    return this.logActivity(userId, 'LOGIN', 'AUTH', { timestamp: new Date() }, ipAddress, userAgent);
  }

  // Log khusus untuk logout
  async logLogout(userId: number, ipAddress?: string, userAgent?: string) {
    return this.logActivity(userId, 'LOGOUT', 'AUTH', { timestamp: new Date() }, ipAddress, userAgent);
  }

  // Log khusus untuk transaksi
  async logTransaksi(userId: number, aksi: string, transaksiId: number, detail?: any, ipAddress?: string, userAgent?: string) {
    return this.logActivity(
      userId, 
      aksi, 
      'TRANSAKSI', 
      { transaksiId, ...detail },
      ipAddress,
      userAgent
    );
  }

  // Log khusus untuk produk
  async logProduk(userId: number, aksi: string, produkId: number, detail?: any, ipAddress?: string, userAgent?: string) {
    return this.logActivity(
      userId, 
      aksi, 
      'PRODUK', 
      { produkId, ...detail },
      ipAddress,
      userAgent
    );
  }

  // Log khusus untuk cabang
  async logCabang(userId: number, aksi: string, cabangId: number, detail?: any, ipAddress?: string, userAgent?: string) {
    return this.logActivity(
      userId, 
      aksi, 
      'CABANG', 
      { cabangId, ...detail },
      ipAddress,
      userAgent
    );
  }
}
