import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { 
  GetLaporanDto, 
  RingkasanPenjualanDto, 
  ProdukTerlarisDto, 
  StatistikTransaksiDto, 
  LaporanLabaRugiDto 
} from './dto/laporan.dto';

@Injectable()
export class LaporanService {
  constructor(private prisma: PrismaService) {}

  /**
   * Mendapatkan ringkasan penjualan untuk periode tertentu
   */
  async getRingkasanPenjualan(
    userId: number, 
    dto: GetLaporanDto
  ): Promise<RingkasanPenjualanDto> {
    const { startDate, endDate, cabangId } = dto;

    // Default ke bulan ini jika tidak ada tanggal
    const start = startDate ? new Date(startDate) : new Date(new Date().getFullYear(), new Date().getMonth(), 1);
    const end = endDate ? new Date(endDate) : new Date();
    
    // Adjust to WIB timezone (UTC+7)
    // Set start to beginning of day in WIB (subtract 7 hours from UTC)
    start.setHours(0, 0, 0, 0);
    start.setHours(start.getHours() - 7); // Convert to UTC for WIB 00:00
    
    // Set end to end of day in WIB (subtract 7 hours from UTC)
    end.setHours(23, 59, 59, 999);
    end.setHours(end.getHours() - 7); // Convert to UTC for WIB 23:59

    console.log('📅 Date range adjusted for WIB (UTC+7):', {
      start: start.toISOString(),
      end: end.toISOString(),
      startWIB: new Date(start.getTime() + 7*60*60*1000).toString(),
      endWIB: new Date(end.getTime() + 7*60*60*1000).toString()
    });

    // Query untuk mendapatkan data transaksi dengan filter akses user
    const whereCondition: any = {
      createdAt: {
        gte: start,
        lte: end,
      },
    };

    // Tambahkan filter cabang jika diminta
    if (cabangId) {
      whereCondition.cabangId = cabangId;
    }

    // Tambahkan filter akses berdasarkan role user
    const cabangFilter = await this.getCabangFilter(userId);
    console.log('🔍 Cabang filter result:', JSON.stringify(cabangFilter, null, 2));
    
    // Apply cabang filter to ensure multi-tenancy
    whereCondition.cabang = cabangFilter;

    console.log('🔍 === RINGKASAN PENJUALAN QUERY ===');
    console.log('UserId:', userId);
    console.log('Start date:', start);
    console.log('End date:', end);
    console.log('Where condition (WITH FILTER):', JSON.stringify(whereCondition, null, 2));

    const transaksi = await this.prisma.transaksi.findMany({
      where: whereCondition,
      include: {
        detail: {
          include: {
            produk: true,
          },
        },
      },
    });

    console.log('📊 Found transaksi count:', transaksi.length);
    if (transaksi.length > 0) {
      console.log('📊 Sample transaksi:', {
        id: transaksi[0].id,
        total: transaksi[0].total,
        cabangId: transaksi[0].cabangId,
        createdAt: transaksi[0].createdAt,
        detailCount: transaksi[0].detail.length
      });
    }

    // Debug: cek total transaksi tanpa filter
    const allTransaksi = await this.prisma.transaksi.findMany({
      where: {
        createdAt: {
          gte: start,
          lte: end,
        },
      },
    });
    console.log('📊 Total transaksi in date range (no filter):', allTransaksi.length);

    // Debug: cek semua transaksi untuk owner ini (tanpa filter tanggal)
    const allOwnerTransaksi = await this.prisma.transaksi.findMany({
      where: {
        cabang: { ownerId: userId },
      },
      orderBy: { createdAt: 'desc' },
      take: 5,
    });
    console.log('📊 Latest 5 transaksi for owner (no date filter):', 
      allOwnerTransaksi.map(t => ({
        id: t.id,
        total: t.total,
        cabangId: t.cabangId,
        kasirId: t.kasirId,
        createdAt: t.createdAt.toISOString()
      }))
    );

    // Debug: cek semua transaksi untuk cabang owner ini
    const ownerCabangTransaksi = await this.prisma.transaksi.findMany({
      where: {
        cabang: { ownerId: userId },
        createdAt: {
          gte: start,
          lte: end,
        },
      },
    });
    console.log('📊 Total transaksi for owner cabang:', ownerCabangTransaksi.length);

    // Debug: cek semua transaksi user
    const userTransaksi = await this.prisma.transaksi.findMany({
      where: {
        kasirId: userId,
        createdAt: {
          gte: start,
          lte: end,
        },
      },
    });
    console.log('📊 Total transaksi by kasirId:', userTransaksi.length);

    // Hitung ringkasan
    let totalOmzet = 0;
    let totalLaba = 0;
    let totalBarangTerjual = 0;

    for (const t of transaksi) {
      totalOmzet += t.total;
      
      for (const detail of t.detail) {
        totalBarangTerjual += detail.jumlah;
        // Laba = (Harga Jual - Harga Beli) * Jumlah
        const labaProduk = (detail.hargaSaatItu - detail.produk.hargaBeli) * detail.jumlah;
        totalLaba += labaProduk;
      }
    }

    const totalTransaksi = transaksi.length;
    const rataRataTransaksi = totalTransaksi > 0 ? totalOmzet / totalTransaksi : 0;

    return {
      totalOmzet,
      totalLaba,
      totalTransaksi,
      totalBarangTerjual,
      rataRataTransaksi: Math.round(rataRataTransaksi),
      periode: {
        startDate: start.toISOString(),
        endDate: end.toISOString(),
      },
    };
  }

  /**
   * Mendapatkan produk terlaris
   */
  async getProdukTerlaris(
    userId: number,
    dto: GetLaporanDto,
    limit: number = 10
  ): Promise<ProdukTerlarisDto[]> {
    const { startDate, endDate, cabangId } = dto;

    const start = startDate ? new Date(startDate) : new Date(new Date().getFullYear(), new Date().getMonth(), 1);
    const end = endDate ? new Date(endDate) : new Date();

    // Buat kondisi where dengan filter akses user
    const whereCondition: any = {
      transaksi: {
        createdAt: {
          gte: start,
          lte: end,
        },
        cabang: await this.getCabangFilter(userId),
      },
    };

    // Tambahkan filter cabang jika diminta
    if (cabangId) {
      whereCondition.transaksi.cabangId = cabangId;
    }

    // Query agregasi untuk produk terlaris
    const produkTerlaris = await this.prisma.transaksiDetail.groupBy({
      by: ['produkId'],
      where: whereCondition,
      _sum: {
        jumlah: true,
      },
      orderBy: {
        _sum: {
          jumlah: 'desc',
        },
      },
      take: limit,
    });

    // Ambil detail produk dan hitung omzet/laba
    const result: ProdukTerlarisDto[] = [];
    
    for (const item of produkTerlaris) {
      const produk = await this.prisma.produk.findUnique({
        where: { id: item.produkId },
      });

      if (!produk) continue;

      // Hitung total omzet dan laba untuk produk ini
      const transaksiDetail = await this.prisma.transaksiDetail.findMany({
        where: {
          produkId: item.produkId,
          transaksi: {
            createdAt: {
              gte: start,
              lte: end,
            },
            ...(cabangId && { cabangId }),
            cabang: await this.getCabangFilter(userId),
          },
        },
      });

      let totalOmzet = 0;
      let totalLaba = 0;

      for (const detail of transaksiDetail) {
        totalOmzet += detail.hargaSaatItu * detail.jumlah;
        totalLaba += (detail.hargaSaatItu - produk.hargaBeli) * detail.jumlah;
      }

      result.push({
        produkId: produk.id,
        namaProduk: produk.nama,
        totalTerjual: item._sum.jumlah || 0,
        totalOmzet,
        totalLaba,
      });
    }

    return result;
  }

  /**
   * Mendapatkan statistik transaksi harian
   */
  async getStatistikTransaksi(
    userId: number,
    dto: GetLaporanDto
  ): Promise<StatistikTransaksiDto[]> {
    const { startDate, endDate, cabangId } = dto;

    const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000); // 30 hari lalu
    const end = endDate ? new Date(endDate) : new Date();

    // Buat kondisi where dengan filter akses user
    const whereCondition: any = {
      createdAt: {
        gte: start,
        lte: end,
      },
      cabang: await this.getCabangFilter(userId),
    };

    // Tambahkan filter cabang jika diminta
    if (cabangId) {
      whereCondition.cabangId = cabangId;
    }

    // Query transaksi dalam periode
    const transaksi = await this.prisma.transaksi.findMany({
      where: whereCondition,
      include: {
        detail: {
          include: {
            produk: true,
          },
        },
      },
      orderBy: {
        createdAt: 'asc',
      },
    });

    // Group by tanggal
    const statistikMap = new Map<string, {
      jumlahTransaksi: number;
      totalOmzet: number;
      totalLaba: number;
    }>();

    for (const t of transaksi) {
      const tanggal = t.createdAt.toISOString().split('T')[0]; // YYYY-MM-DD
      
      if (!statistikMap.has(tanggal)) {
        statistikMap.set(tanggal, {
          jumlahTransaksi: 0,
          totalOmzet: 0,
          totalLaba: 0,
        });
      }

      const stat = statistikMap.get(tanggal)!;
      stat.jumlahTransaksi++;
      stat.totalOmzet += t.total;

      // Hitung laba
      for (const detail of t.detail) {
        const labaProduk = (detail.hargaSaatItu - detail.produk.hargaBeli) * detail.jumlah;
        stat.totalLaba += labaProduk;
      }
    }

    // Convert ke array
    const result: StatistikTransaksiDto[] = [];
    for (const [tanggal, stat] of statistikMap) {
      result.push({
        tanggal,
        jumlahTransaksi: stat.jumlahTransaksi,
        totalOmzet: stat.totalOmzet,
        totalLaba: stat.totalLaba,
      });
    }

    return result.sort((a, b) => a.tanggal.localeCompare(b.tanggal));
  }

  /**
   * Mendapatkan laporan laba rugi
   */
  async getLaporanLabaRugi(
    userId: number,
    dto: GetLaporanDto
  ): Promise<LaporanLabaRugiDto> {
    const ringkasan = await this.getRingkasanPenjualan(userId, dto);
    
    const totalPenjualan = ringkasan.totalOmzet;
    const totalHPP = totalPenjualan - ringkasan.totalLaba;
    const totalLaba = ringkasan.totalLaba;
    const margin = totalPenjualan > 0 ? (totalLaba / totalPenjualan) * 100 : 0;

    return {
      totalPendapatan: totalPenjualan,
      totalPenjualan,
      totalHPP,
      totalLaba,
      margin: Math.round(margin * 100) / 100, // 2 decimal places
      periode: ringkasan.periode,
    };
  }

  /**
   * Mendapatkan filter cabang berdasarkan role user (lebih permisif seperti API lama)
   */
  private async getCabangFilter(userId: number) {
    console.log('🔍 === GET CABANG FILTER ===');
    console.log('User ID:', userId);
    
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        cabang: true,
        aksesCabang: true,
      },
    });

    if (!user) {
      throw new Error('User tidak ditemukan');
    }

    console.log('👤 User found:', {
      id: user.id,
      role: user.role,
      cabangCount: user.cabang?.length || 0,
      aksesCabangCount: user.aksesCabang?.length || 0
    });

    if (user.role === 'OWNER') {
      // Owner bisa akses semua cabang yang dia miliki
      const filter = {
        ownerId: userId,
      };
      console.log('👑 Owner filter:', filter);
      return filter;
    } else {
      // Admin/Kasir bisa akses cabang yang diberikan akses
      // Jika tidak ada akses cabang, kembalikan filter yang tidak akan match (empty result)
      const cabangIds = user.aksesCabang.map(akses => akses.cabangId);
      console.log('🏢 Cabang IDs from aksesCabang:', cabangIds);
      
      if (cabangIds.length === 0) {
        // Jika tidak ada akses, return filter yang tidak akan match dengan cabang manapun
        const filter = {
          id: {
            in: [],
          },
        };
        console.log('❌ No access filter:', filter);
        return filter;
      }
      const filter = {
        id: {
          in: cabangIds,
        },
      };
      console.log('✅ Access filter:', filter);
      return filter;
    }
  }
}
