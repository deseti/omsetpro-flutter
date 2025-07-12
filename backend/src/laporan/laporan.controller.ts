import {
  Controller,
  Get,
  Query,
  UseGuards,
  Request,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
// import { LaporanService } from './laporan.service'; // NONAKTIF - fitur laporan manual dihapus
import { InsightService } from './insight.service';
// import { GetLaporanDto } from './dto/laporan.dto'; // NONAKTIF - fitur laporan manual dihapus
import { GetInsightDto } from './dto/insight.dto';

@Controller('laporan')
@UseGuards(AuthGuard('jwt'))
export class LaporanController {
  constructor(
    // private readonly laporanService: LaporanService, // NONAKTIF - fitur laporan manual dihapus
    private readonly insightService: InsightService,
  ) {}

  /**
   * GET /laporan/insights
   * Mendapatkan dashboard insights dengan analisa otomatis
   */
  @Get('insights')
  async getDashboardInsights(@Request() req, @Query() query: GetInsightDto) {
    try {
      const userId = req.user.id;
      
      // Set default period jika tidak ada
      const dto: GetInsightDto = {
        period: query.period || 'monthly',
        cabangId: query.cabangId ? parseInt(String(query.cabangId)) : undefined,
        comparisonPeriod: query.comparisonPeriod || 'previous'
      };

      return await this.insightService.getDashboardInsights(userId, dto);
    } catch (error) {
      console.error('Error getting dashboard insights:', error);
      throw new HttpException(
        error.message || 'Gagal mendapatkan dashboard insights',
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  /**
   * GET /laporan/ringkasan-penjualan
   * NONAKTIF - Fitur laporan manual dihapus, gunakan AI Insight
   */
  // @Get('ringkasan-penjualan')
  // async getRingkasanPenjualan(@Request() req, @Query() query: GetLaporanDto) {
  //   try {
  //     // Ambil userId dari field id (sama seperti API lain)
  //     const userId = req.user.id;
  //     return await this.laporanService.getRingkasanPenjualan(userId, query);
  //   } catch (error) {
  //     throw new HttpException(
  //       error.message || 'Gagal mendapatkan ringkasan penjualan',
  //       HttpStatus.BAD_REQUEST,
  //     );
  //   }
  // }

  /**
   * GET /laporan/produk-terlaris
   * NONAKTIF - Fitur laporan manual dihapus, gunakan AI Insight
   */
  // @Get('produk-terlaris')
  // async getProdukTerlaris(@Request() req, @Query() query: GetLaporanDto) {
  //   try {
  //     const userId = req.user.id;
  //     const limit = query.limit ? parseInt(query.limit as string) : 10;
  //     return await this.laporanService.getProdukTerlaris(userId, query, limit);
  //   } catch (error) {
  //     throw new HttpException(
  //       error.message || 'Gagal mendapatkan produk terlaris',
  //       HttpStatus.BAD_REQUEST,
  //     );
  //   }
  // }

  /**
   * GET /laporan/statistik-transaksi
   * NONAKTIF - Fitur laporan manual dihapus, gunakan AI Insight
   */
  // @Get('statistik-transaksi')
  // async getStatistikTransaksi(@Request() req, @Query() query: GetLaporanDto) {
  //   try {
  //     const userId = req.user.id;
  //     return await this.laporanService.getStatistikTransaksi(userId, query);
  //   } catch (error) {
  //     throw new HttpException(
  //       error.message || 'Gagal mendapatkan statistik transaksi',
  //       HttpStatus.BAD_REQUEST,
  //     );
  //   }
  // }

  /**
   * GET /laporan/laba-rugi
   * NONAKTIF - Fitur laporan manual dihapus, gunakan AI Insight
   */
  // @Get('laba-rugi')
  // async getLaporanLabaRugi(@Request() req, @Query() query: GetLaporanDto) {
  //   try {
  //     const userId = req.user.id;
  //     return await this.laporanService.getLaporanLabaRugi(userId, query);
  //   } catch (error) {
  //     throw new HttpException(
  //       error.message || 'Gagal mendapatkan laporan laba rugi',
  //       HttpStatus.BAD_REQUEST,
  //     );
  //   }
  // }

  /**
   * GET /laporan/dashboard
   * NONAKTIF - Fitur laporan manual dihapus, gunakan AI Insight
   */
  // @Get('dashboard')
  // async getDashboard(@Request() req, @Query() query: GetLaporanDto) {
  //   try {
  //     const userId = req.user.id;
  //     console.log('🔍 === DASHBOARD REQUEST ===');
  //     console.log('User ID:', userId);
  //     console.log('Query params:', query);
  //     console.log('Timestamp:', new Date().toISOString());

  //     // Ambil semua data secara paralel
  //     const [ringkasan, produkTerlaris, statistikTransaksi, labaRugi] =
  //       await Promise.all([
  //         this.laporanService.getRingkasanPenjualan(userId, query),
  //         this.laporanService.getProdukTerlaris(userId, query, 5),
  //         this.laporanService.getStatistikTransaksi(userId, query),
  //         this.laporanService.getLaporanLabaRugi(userId, query),
  //       ]);

  //     const dashboardData = {
  //       ringkasan,
  //       produkTerlaris,
  //       statistikTransaksi: statistikTransaksi.slice(-7), // 7 hari terakhir
  //       labaRugi,
  //       generatedAt: new Date().toISOString(),
  //     };

  //     console.log('📊 Dashboard data generated at:', dashboardData.generatedAt);
  //     console.log('📊 Ringkasan total omzet:', ringkasan.totalOmzet);

  //     return dashboardData;
  //   } catch (error) {
  //     throw new HttpException(
  //       error.message || 'Gagal mendapatkan data dashboard',
  //       HttpStatus.BAD_REQUEST,
  //     );
  //   }
  // }
}
