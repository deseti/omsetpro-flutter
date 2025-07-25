import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { User } from '@prisma/client';

@Injectable()
export class DashboardService {
  constructor(private prisma: PrismaService) {}

  async getStats(user: User) {
    // Tentukan owner ID
    const ownerId = user.role === 'OWNER' ? user.id : user.dikelolaOlehId;
    
    if (!ownerId) {
      // Jika tidak ada owner ID, return stats kosong
      return {
        penjualanHariIni: 'Rp 0',
        transaksiHariIni: '0',
        produkTerjual: '0',
        keuntungan: 'Rp 0',
        trendPenjualan: '0%',
        trendTransaksi: '0',
        trendProduk: '0',
        trendKeuntungan: '0%',
        isPositiveTrendPenjualan: true,
        isPositiveTrendTransaksi: true,
        isPositiveTrendProduk: true,
        isPositiveTrendKeuntungan: true,
      };
    }

    // Tanggal hari ini
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    try {
      // Hitung transaksi hari ini
      const transaksiHariIni = await this.prisma.transaksi.count({
        where: {
          kasir: {
            dikelolaOlehId: ownerId,
          },
          createdAt: {
            gte: today,
            lt: tomorrow,
          },
        },
      });

      // Hitung total penjualan hari ini
      const penjualanResult = await this.prisma.transaksi.aggregate({
        _sum: {
          total: true,
        },
        where: {
          kasir: {
            dikelolaOlehId: ownerId,
          },
          createdAt: {
            gte: today,
            lt: tomorrow,
          },
        },
      });

      const totalPenjualan = penjualanResult._sum.total || 0;

      // Hitung produk terjual hari ini
      const produkTerjualResult = await this.prisma.transaksiDetail.aggregate({
        _sum: {
          jumlah: true,
        },
        where: {
          transaksi: {
            kasir: {
              dikelolaOlehId: ownerId,
            },
            createdAt: {
              gte: today,
              lt: tomorrow,
            },
          },
        },
      });

      const totalProdukTerjual = produkTerjualResult._sum.jumlah || 0;

      // Hitung keuntungan hari ini (estimasi sederhana: total penjualan - HPP)
      // Untuk sekarang kita tidak menghitung ulang, cukup gunakan data yang sudah ada
      
      // Estimasi keuntungan (bisa diperbaiki dengan data HPP yang lebih akurat)
      const estimasiKeuntungan = Math.round(totalPenjualan * 0.3); // Asumsi margin 30%

      // Format ke Rupiah
      const formatRupiah = (amount: number) => {
        return new Intl.NumberFormat('id-ID', {
          style: 'currency',
          currency: 'IDR',
          minimumFractionDigits: 0,
        }).format(amount);
      };

      // TODO: Hitung trend (perbandingan dengan kemarin)
      // Untuk sekarang, return 0% sebagai default
      
      return {
        penjualanHariIni: formatRupiah(totalPenjualan),
        transaksiHariIni: transaksiHariIni.toString(),
        produkTerjual: totalProdukTerjual.toString(),
        keuntungan: formatRupiah(estimasiKeuntungan),
        trendPenjualan: '0%',
        trendTransaksi: '0',
        trendProduk: '0',
        trendKeuntungan: '0%',
        isPositiveTrendPenjualan: true,
        isPositiveTrendTransaksi: true,
        isPositiveTrendProduk: true,
        isPositiveTrendKeuntungan: true,
      };
    } catch (error) {
      console.error('Error getting dashboard stats:', error);
      
      // Return stats kosong jika ada error
      return {
        penjualanHariIni: 'Rp 0',
        transaksiHariIni: '0',
        produkTerjual: '0',
        keuntungan: 'Rp 0',
        trendPenjualan: '0%',
        trendTransaksi: '0',
        trendProduk: '0',
        trendKeuntungan: '0%',
        isPositiveTrendPenjualan: true,
        isPositiveTrendTransaksi: true,
        isPositiveTrendProduk: true,
        isPositiveTrendKeuntungan: true,
      };
    }
  }
}
