import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateTransaksiDto } from './dto/create-transaksi.dto';
import { LaporanGateway } from '../laporan/laporan.gateway';
import { LoyaltyService } from '../loyalty/loyalty.service'; // [BARU] Import LoyaltyService

@Injectable()
export class TransaksiService {
  constructor(
    private prisma: PrismaService,
    private laporanGateway: LaporanGateway,
    private loyaltyService: LoyaltyService, // [BARU] Inject LoyaltyService
  ) {}

  private async verifyCabangAccess(cabangId: number, kasirId: number) {
    // 1. Cari cabang dan kasir
    const cabang = await this.prisma.cabang.findUnique({
      where: { id: cabangId },
    });
    if (!cabang) {
      throw new NotFoundException(`Cabang dengan ID ${cabangId} tidak ditemukan`);
    }

    const kasir = await this.prisma.user.findUnique({
      where: { id: kasirId },
    });
    if (!kasir) {
      throw new NotFoundException('Kasir tidak ditemukan');
    }

    // 2. Jika kasir adalah OWNER, cek kepemilikan cabang
    if (kasir.role === 'OWNER') {
      if (cabang.ownerId !== kasirId) {
        throw new ForbiddenException('Anda bukan pemilik cabang ini');
      }
      return { cabang, kasir };
    }

    // 3. Jika kasir adalah ADMIN atau KASIR, cek akses melalui tabel AksesCabang
    const akses = await this.prisma.aksesCabang.findUnique({
      where: {
        userId_cabangId: {
          userId: kasirId,
          cabangId: cabangId,
        },
      },
    });

    if (!akses) {
      throw new ForbiddenException(
        'Anda tidak memiliki akses untuk melakukan transaksi di cabang ini',
      );
    }

    return { cabang, kasir };
  }

  async create(createTransaksiDto: CreateTransaksiDto, kasirId: number) {
    const { cabangId, metodeBayar, items, pelangganId } = createTransaksiDto;

    const { cabang } = await this.verifyCabangAccess(cabangId, kasirId);

    if (!items || items.length === 0) {
      throw new BadRequestException('Keranjang belanja tidak boleh kosong.');
    }

    const produkIds = items.map((item) => item.produkId);
    const produkDiDb = await this.prisma.produk.findMany({
      where: {
        id: { in: produkIds },
        cabangId: cabangId,
      },
    });

    if (produkDiDb.length !== produkIds.length) {
      throw new BadRequestException(
        'Beberapa produk tidak ditemukan di cabang ini.',
      );
    }

    let totalHarga = 0;
    const transaksiDetailData = produkDiDb.map((produk) => {
      const itemDiKeranjang = items.find(
        (item) => item.produkId === produk.id,
      )!;

      if (produk.stok < itemDiKeranjang.jumlah) {
        throw new BadRequestException(
          `Stok untuk produk "${produk.nama}" tidak mencukupi.`,
        );
      }

      totalHarga += produk.harga * itemDiKeranjang.jumlah;
      return {
        produkId: produk.id,
        jumlah: itemDiKeranjang.jumlah,
        hargaSaatItu: produk.harga,
      };
    });

    return this.prisma.$transaction(async (tx) => {
      // 1. Buat transaksi utama
      const transaksi = await tx.transaksi.create({
        data: {
          total: totalHarga,
          metodeBayar,
          cabangId,
          kasirId,
          pelangganId: pelangganId,
          detail: {
            create: transaksiDetailData,
          },
        },
        include: {
          detail: true,
        },
      });

      // 2. Update stok produk
      for (const item of items) {
        await tx.produk.update({
          where: { id: item.produkId },
          data: {
            stok: {
              decrement: item.jumlah,
            },
          },
        });
      }
      
      // ============== [LOGIKA BARU] PENAMBAHAN POIN OTOMATIS ==============
      if (pelangganId) {
        const ownerId = cabang.ownerId;
        const rule = await tx.loyaltyRule.findUnique({ where: { ownerId } });

        if (rule && rule.kelipatanRp > 0) {
          const poinDidapat = Math.floor(totalHarga / rule.kelipatanRp) * rule.dapatPoin;

          if (poinDidapat > 0) {
            // Tambah poin ke pelanggan
            await tx.pelanggan.update({
              where: { id: pelangganId },
              data: {
                totalPoin: {
                  increment: poinDidapat,
                },
              },
            });

            // Catat di riwayat poin
            await tx.pointHistory.create({
              data: {
                pelangganId: pelangganId,
                poin: poinDidapat,
                tipe: 'EARNED',
                deskripsi: `Poin dari transaksi #${transaksi.id}`,
                transaksiId: transaksi.id,
              },
            });
          }
        }
      }
      // =================================================================

      // 3. Kirim notifikasi real-time
      this.laporanGateway.kirimUpdateLaporan({
        message: `Transaksi baru sebesar Rp ${totalHarga} telah dibuat!`,
        cabangId: cabangId,
      });

      return transaksi;
    });
  }
}
