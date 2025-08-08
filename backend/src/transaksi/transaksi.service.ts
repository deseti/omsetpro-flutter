import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PromoTipe } from '@prisma/client'; // [BARU] Import PromoTipe
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
    const { 
      cabangId, 
      metodeBayar, 
      items, 
      pelangganId, 
      orderId,
      sumberTransaksi = 'Kasir',
      tipePengiriman,
      namaPelangganOnline,
      noHpPelangganOnline
    } = createTransaksiDto;

    const { cabang } = await this.verifyCabangAccess(cabangId, kasirId);
    const ownerId = cabang.ownerId;

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
    // ============== [LOGIKA BARU] APLIKASI PROMO & DISKON ==============
    // 1. Ambil semua promo aktif milik owner
    const promos = await this.prisma.promo.findMany({
      where: {
        ownerId,
        isActive: true,
        // Optional: Anda bisa menambahkan filter tanggal di sini nanti
        // startDate: { lte: new Date() },
        // endDate: { gte: new Date() },
      },
      include: {
        produk: { select: { produkId: true } }, // Ambil ID produk yang terkait promo
      },
    });

    let totalHargaAsli = 0;
    let totalPotongan = 0;
    const transaksiDetailData: Array<{ produkId: number; jumlah: number; hargaSaatItu: number; potonganItem: number }> = [];

    for (const produk of produkDiDb) {
      const itemDiKeranjang = items.find((item) => item.produkId === produk.id)!;
      
      if (produk.stok < itemDiKeranjang.jumlah) {
        throw new BadRequestException(`Stok untuk produk "${produk.nama}" tidak mencukupi.`);
      }

      const hargaTotalItem = produk.harga * itemDiKeranjang.jumlah;
      totalHargaAsli += hargaTotalItem;
      let potonganItem = 0;

      // 2. Cek apakah produk ini ada di dalam promo
      const promoUntukProdukIni = promos.find((p) =>
        p.produk.some((pp) => pp.produkId === produk.id),
      );

      if (promoUntukProdukIni) {
        if (promoUntukProdukIni.tipe === PromoTipe.PERCENTAGE) {
          potonganItem = hargaTotalItem * (promoUntukProdukIni.nilai / 100);
        } else if (promoUntukProdukIni.tipe === PromoTipe.NOMINAL) {
          // Potongan nominal per item, dikalikan jumlah
          potonganItem = promoUntukProdukIni.nilai * itemDiKeranjang.jumlah;
        }
        potonganItem = Math.floor(potonganItem); // Bulatkan ke bawah
      }
      
      totalPotongan += potonganItem;

      transaksiDetailData.push({
        produkId: produk.id,
        jumlah: itemDiKeranjang.jumlah,
        hargaSaatItu: produk.harga,
        potonganItem: potonganItem, // Simpan potongan per item
      });
    }
    
    const totalAkhir = totalHargaAsli - totalPotongan;
    // =================================================================

    return this.prisma.$transaction(async (tx) => {
      // 1. Buat transaksi utama
      const transaksi = await tx.transaksi.create({
        data: {
          total: totalAkhir, // Gunakan total akhir setelah diskon
          potongan: totalPotongan, // Simpan total diskon
          metodeBayar,
          sumberTransaksi,
          tipePengiriman,
          namaPelangganOnline,
          noHpPelangganOnline,
          cabangId,
          kasirId,
          pelangganId: pelangganId,
          orderId: orderId, // [PERBAIKAN] Simpan orderId untuk webhook
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
          data: { stok: { decrement: item.jumlah } },
        });
      }
      
      // ============== [LOGIKA BARU] PENAMBAHAN POIN OTOMATIS ==============
      if (pelangganId) {
        const rule = await tx.loyaltyRule.findUnique({ where: { ownerId } });
        if (rule && rule.kelipatanRp > 0) {
          // Poin dihitung dari total akhir setelah diskon
          const poinDidapat = Math.floor(totalAkhir / rule.kelipatanRp) * rule.dapatPoin;
          if (poinDidapat > 0) {
            await tx.pelanggan.update({
              where: { id: pelangganId },
              data: { totalPoin: { increment: poinDidapat } },
            });
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
        message: `Transaksi baru sebesar Rp ${totalAkhir} telah dibuat!`,
        cabangId: cabangId,
      });

      return transaksi;
    });
  }

  async getRiwayatTransaksi(params: {
    cabangId?: number;
    startDate?: Date;
    endDate?: Date;
    limit?: number;
    offset?: number;
    userId: number;
  }) {
    const { cabangId, startDate, endDate, limit = 20, offset = 0, userId } = params;

    // Verifikasi akses user
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    
    if (!user) {
      throw new NotFoundException('User tidak ditemukan');
    }

    // Build where clause
    const whereClause: any = {};

    // Filter cabang berdasarkan role
    if (user.role === 'OWNER') {
      // Owner hanya bisa melihat transaksi di cabang miliknya
      const cabangFilter: any = { ownerId: userId };
      if (cabangId) {
        cabangFilter.id = cabangId;
      }
      whereClause.cabang = cabangFilter;
    } else {
      // ADMIN/KASIR hanya bisa melihat transaksi di cabang yang bisa diakses
      const aksesQuery = {
        userId: userId,
        ...(cabangId && { cabangId }),
      };
      
      const aksesCabang = await this.prisma.aksesCabang.findMany({
        where: aksesQuery,
        select: { cabangId: true },
      });
      
      if (aksesCabang.length === 0) {
        throw new ForbiddenException('Anda tidak memiliki akses ke cabang manapun');
      }
      
      const cabangIds = aksesCabang.map(akses => akses.cabangId);
      whereClause.cabangId = { in: cabangIds };
    }

    // Filter tanggal
    if (startDate || endDate) {
      whereClause.createdAt = {};
      if (startDate) {
        whereClause.createdAt.gte = startDate;
      }
      if (endDate) {
        // Tambahkan 1 hari ke endDate untuk include seluruh hari
        const endOfDay = new Date(endDate);
        endOfDay.setHours(23, 59, 59, 999);
        whereClause.createdAt.lte = endOfDay;
      }
    }

    // Get total count untuk pagination
    const total = await this.prisma.transaksi.count({
      where: whereClause,
    });

    // Get transaksi dengan detail
    const transaksi = await this.prisma.transaksi.findMany({
      where: whereClause,
      include: {
        detail: {
          include: {
            produk: {
              select: {
                id: true,
                nama: true,
                fotoUrl: true,
              },
            },
          },
        },
        kasir: {
          select: {
            id: true,
            namaLengkap: true,
          },
        },
        cabang: {
          select: {
            id: true,
            nama: true,
          },
        },
        pelanggan: {
          select: {
            id: true,
            nama: true,
            noHp: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: limit,
      skip: offset,
    });

    return {
      data: transaksi,
      pagination: {
        total,
        limit,
        offset,
        hasMore: offset + limit < total,
      },
    };
  }

  // [BARU] Method untuk konfirmasi pembayaran transaksi online
  async konfirmasiPembayaranOnline(transaksiId: number, userId: number) {
    // Verifikasi akses user ke transaksi
    const transaksi = await this.prisma.transaksi.findUnique({
      where: { id: transaksiId },
      include: {
        cabang: true,
      },
    });

    if (!transaksi) {
      throw new NotFoundException('Transaksi tidak ditemukan');
    }

    // Cek apakah ini transaksi online dan masih pending
    if (transaksi.sumberTransaksi !== 'TokoOnline') {
      throw new BadRequestException('Bukan transaksi dari toko online');
    }

    if (transaksi.status !== 'pending') {
      throw new BadRequestException('Transaksi sudah dikonfirmasi atau dibatalkan');
    }

    // Verifikasi ownership
    await this.verifyCabangAccess(transaksi.cabangId, userId);

    // Update status transaksi menjadi completed
    const updatedTransaksi = await this.prisma.transaksi.update({
      where: { id: transaksiId },
      data: {
        status: 'completed',
      },
      include: {
        detail: {
          include: {
            produk: {
              select: {
                id: true,
                nama: true,
                fotoUrl: true,
              },
            },
          },
        },
        kasir: {
          select: {
            id: true,
            namaLengkap: true,
          },
        },
        cabang: {
          select: {
            id: true,
            nama: true,
          },
        },
      },
    });

    // Emit real-time notification (jika method ini ada)
    // this.laporanGateway.emitTransaksiUpdate(updatedTransaksi);

    return updatedTransaksi;
  }

  // [BARU] Method untuk membatalkan transaksi online
  async batalkanTransaksiOnline(transaksiId: number, userId: number) {
    // Verifikasi akses user ke transaksi
    const transaksi = await this.prisma.transaksi.findUnique({
      where: { id: transaksiId },
      include: {
        cabang: true,
        detail: {
          include: {
            produk: true,
          },
        },
      },
    });

    if (!transaksi) {
      throw new NotFoundException('Transaksi tidak ditemukan');
    }

    // Cek apakah ini transaksi online dan masih pending
    if (transaksi.sumberTransaksi !== 'TokoOnline') {
      throw new BadRequestException('Bukan transaksi dari toko online');
    }

    if (transaksi.status !== 'pending') {
      throw new BadRequestException('Transaksi sudah dikonfirmasi atau dibatalkan');
    }

    // Verifikasi ownership
    await this.verifyCabangAccess(transaksi.cabangId, userId);

    // Kembalikan stok produk dan update status
    return this.prisma.$transaction(async (tx) => {
      // Kembalikan stok
      for (const detail of transaksi.detail) {
        await tx.produk.update({
          where: { id: detail.produkId },
          data: { stok: { increment: detail.jumlah } },
        });
      }

      // Update status transaksi
      const updatedTransaksi = await tx.transaksi.update({
        where: { id: transaksiId },
        data: {
          status: 'cancelled',
        },
        include: {
          detail: {
            include: {
              produk: {
                select: {
                  id: true,
                  nama: true,
                  fotoUrl: true,
                },
              },
            },
          },
          kasir: {
            select: {
              id: true,
              namaLengkap: true,
            },
          },
          cabang: {
            select: {
              id: true,
              nama: true,
            },
          },
        },
      });

      return updatedTransaksi;
    });
  }

  // [BARU] Update informasi pengiriman
  async updateShippingInfo(
    transaksiId: number,
    shippingInfo: { nomorResi?: string; namaKurir?: string },
    userId: number
  ) {
    // 1. Cari transaksi
    const transaksi = await this.prisma.transaksi.findUnique({
      where: { id: transaksiId },
      include: {
        cabang: true,
      },
    });

    if (!transaksi) {
      throw new NotFoundException('Transaksi tidak ditemukan');
    }

    // 2. Verifikasi akses ke cabang
    await this.verifyCabangAccess(transaksi.cabangId, userId);

    // 3. Pastikan ini adalah transaksi online dengan tipe pengiriman "Diantar"
    if (transaksi.sumberTransaksi !== 'TokoOnline') {
      throw new BadRequestException('Hanya transaksi toko online yang dapat diupdate info pengirimannya');
    }

    if (transaksi.tipePengiriman !== 'Diantar') {
      throw new BadRequestException('Hanya pesanan yang diantar kurir yang dapat diupdate info pengirimannya');
    }

    // 4. Update informasi pengiriman
    const updatedTransaksi = await this.prisma.transaksi.update({
      where: { id: transaksiId },
      data: {
        nomorResi: shippingInfo.nomorResi,
        namaKurir: shippingInfo.namaKurir,
      },
      include: {
        detail: {
          include: {
            produk: {
              select: {
                id: true,
                nama: true,
                fotoUrl: true,
              },
            },
          },
        },
        kasir: {
          select: {
            id: true,
            namaLengkap: true,
          },
        },
        cabang: {
          select: {
            id: true,
            nama: true,
          },
        },
      },
    });

    return updatedTransaksi;
  }
}
