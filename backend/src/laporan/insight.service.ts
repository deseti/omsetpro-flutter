import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import {
  InsightDashboardDto,
  InsightCardDto,
  SalesComparisonDto,
  ProductInsightDto,
  ProfitInsightDto,
  TrendDataDto,
  GetInsightDto
} from './dto/insight.dto';

@Injectable()
export class InsightService {
  constructor(private prisma: PrismaService) {}

  /**
   * Mendapatkan dashboard insight lengkap
   */
  async getDashboardInsights(
    userId: number,
    dto: GetInsightDto
  ): Promise<InsightDashboardDto> {
    const { period, cabangId, comparisonPeriod = 'previous' } = dto;

    // Dapatkan periode saat ini dan sebelumnya
    const periods = this.calculatePeriods(period, comparisonPeriod);
    const cabangFilter = await this.getCabangFilter(userId);

    // Parallel execution untuk performa yang lebih baik
    const [
      currentData,
      previousData,
      trendData,
      productInsights
    ] = await Promise.all([
      this.getPeriodData(periods.current, cabangFilter, cabangId),
      this.getPeriodData(periods.previous, cabangFilter, cabangId),
      this.getTrendData(userId, period, cabangFilter, cabangId),
      this.getProductInsights(userId, periods.current, periods.previous, cabangFilter, cabangId)
    ]);

    // Generate insights
    const insights = this.generateInsightCards(currentData, previousData, period);
    const salesComparison = this.generateSalesComparison(currentData, previousData, periods);
    const profitInsights = this.generateProfitInsights(currentData, previousData);

    return {
      insights,
      salesComparison,
      productInsights,
      profitInsights,
      trendData,
      lastUpdated: new Date().toISOString()
    };
  }

  /**
   * Generate insight cards untuk dashboard
   */
  private generateInsightCards(
    currentData: any,
    previousData: any,
    period: string
  ): InsightCardDto[] {
    const insights: InsightCardDto[] = [];

    // 1. Sales Performance Insight
    const salesChange = this.calculatePercentageChange(currentData.totalSales, previousData.totalSales);
    insights.push({
      id: 'sales-performance',
      title: `Penjualan ${this.getPeriodLabel(period)}`,
      value: this.formatCurrency(currentData.totalSales),
      trend: salesChange >= 0 ? 'up' : 'down',
      trendPercentage: Math.abs(salesChange),
      description: `${salesChange >= 0 ? 'Naik' : 'Turun'} ${Math.abs(salesChange).toFixed(1)}% dibanding ${this.getPreviousPeriodLabel(period)}`,
      type: salesChange >= 0 ? 'success' : salesChange > -10 ? 'warning' : 'danger',
      icon: 'trending-up'
    });

    // 2. Transaction Count Insight
    const transactionChange = this.calculatePercentageChange(currentData.totalTransactions, previousData.totalTransactions);
    insights.push({
      id: 'transaction-count',
      title: 'Total Transaksi',
      value: currentData.totalTransactions,
      trend: transactionChange >= 0 ? 'up' : 'down',
      trendPercentage: Math.abs(transactionChange),
      description: `${transactionChange >= 0 ? 'Bertambah' : 'Berkurang'} ${Math.abs(transactionChange).toFixed(1)}% transaksi`,
      type: transactionChange >= 0 ? 'success' : 'warning',
      icon: 'shopping-cart'
    });

    // 3. Profit Margin Insight
    const profitMargin = currentData.totalSales > 0 ? (currentData.totalProfit / currentData.totalSales) * 100 : 0;
    const prevProfitMargin = previousData.totalSales > 0 ? (previousData.totalProfit / previousData.totalSales) * 100 : 0;
    const marginChange = profitMargin - prevProfitMargin;
    
    insights.push({
      id: 'profit-margin',
      title: 'Margin Keuntungan',
      value: `${profitMargin.toFixed(1)}%`,
      trend: marginChange >= 0 ? 'up' : 'down',
      trendPercentage: Math.abs(marginChange),
      description: `Margin ${marginChange >= 0 ? 'meningkat' : 'menurun'} ${Math.abs(marginChange).toFixed(1)}%`,
      type: profitMargin >= 20 ? 'success' : profitMargin >= 10 ? 'warning' : 'danger',
      icon: 'percent'
    });

    // 4. Average Transaction Value
    const avgTransactionValue = currentData.totalTransactions > 0 ? currentData.totalSales / currentData.totalTransactions : 0;
    const prevAvgTransactionValue = previousData.totalTransactions > 0 ? previousData.totalSales / previousData.totalTransactions : 0;
    const avgChange = this.calculatePercentageChange(avgTransactionValue, prevAvgTransactionValue);

    insights.push({
      id: 'avg-transaction',
      title: 'Rata-rata per Transaksi',
      value: this.formatCurrency(avgTransactionValue),
      trend: avgChange >= 0 ? 'up' : 'down',
      trendPercentage: Math.abs(avgChange),
      description: `${avgChange >= 0 ? 'Naik' : 'Turun'} ${Math.abs(avgChange).toFixed(1)}% per transaksi`,
      type: 'info',
      icon: 'calculator'
    });

    return insights;
  }

  /**
   * Generate sales comparison data
   */
  private generateSalesComparison(
    currentData: any,
    previousData: any,
    periods: { current: any, previous: any }
  ): SalesComparisonDto {
    const percentage = this.calculatePercentageChange(currentData.totalSales, previousData.totalSales);
    
    return {
      currentPeriod: {
        value: currentData.totalSales,
        label: 'Periode Sekarang',
        startDate: periods.current.start.toISOString(),
        endDate: periods.current.end.toISOString()
      },
      previousPeriod: {
        value: previousData.totalSales,
        label: 'Periode Sebelumnya',
        startDate: periods.previous.start.toISOString(),
        endDate: periods.previous.end.toISOString()
      },
      comparison: {
        percentage: Math.abs(percentage),
        trend: percentage >= 0 ? 'up' : 'down',
        description: `Penjualan ${percentage >= 0 ? 'meningkat' : 'menurun'} ${Math.abs(percentage).toFixed(1)}% dibanding periode sebelumnya`
      }
    };
  }

  /**
   * Generate product insights
   */
  private async getProductInsights(
    userId: number,
    currentPeriod: any,
    previousPeriod: any,
    cabangFilter: any,
    cabangId?: number
  ): Promise<ProductInsightDto> {
    // Get current period top products
    const currentTopProducts = await this.getTopProducts(currentPeriod, cabangFilter, cabangId, 5);
    const previousTopProducts = await this.getTopProducts(previousPeriod, cabangFilter, cabangId, 10);

    // Find top product
    const topProduct = currentTopProducts[0] || { name: 'Tidak ada data', sales: 0, percentage: 0 };

    // Find rising product (product with highest growth)
    let risingProduct: { name: string; growthPercentage: number } | null = null;
    let maxGrowth = 0;

    for (const current of currentTopProducts) {
      const previous = previousTopProducts.find(p => p.name === current.name);
      if (previous) {
        const growth = this.calculatePercentageChange(current.sales, previous.sales);
        if (growth > maxGrowth && growth > 20) { // Minimal 20% growth
          maxGrowth = growth;
          risingProduct = {
            name: current.name,
            growthPercentage: growth
          };
        }
      }
    }

    // Find declining product
    let decliningProduct: { name: string; declinePercentage: number } | null = null;
    let maxDecline = 0;

    for (const previous of previousTopProducts) {
      const current = currentTopProducts.find(p => p.name === previous.name);
      const currentSales = current ? current.sales : 0;
      const decline = this.calculatePercentageChange(currentSales, previous.sales);
      
      if (decline < maxDecline && decline < -20) { // Minimal 20% decline
        maxDecline = decline;
        decliningProduct = {
          name: previous.name,
          declinePercentage: Math.abs(decline)
        };
      }
    }

    return {
      topProduct,
      risingProduct,
      decliningProduct
    };
  }

  /**
   * Generate profit insights
   */
  private generateProfitInsights(currentData: any, previousData: any): ProfitInsightDto {
    const profitMargin = currentData.totalSales > 0 ? (currentData.totalProfit / currentData.totalSales) * 100 : 0;
    const percentage = this.calculatePercentageChange(currentData.totalProfit, previousData.totalProfit);

    return {
      currentProfit: currentData.totalProfit,
      previousProfit: previousData.totalProfit,
      profitMargin,
      comparison: {
        percentage: Math.abs(percentage),
        trend: percentage >= 0 ? 'up' : 'down',
        description: `Keuntungan ${percentage >= 0 ? 'meningkat' : 'menurun'} ${Math.abs(percentage).toFixed(1)}%`
      }
    };
  }

  /**
   * Get trend data for charts
   */
  private async getTrendData(
    userId: number,
    period: string,
    cabangFilter: any,
    cabangId?: number
  ): Promise<TrendDataDto[]> {
    const days = period === 'daily' ? 7 : period === 'weekly' ? 4 : period === 'monthly' ? 12 : 7;
    const trendData: TrendDataDto[] = [];

    for (let i = days - 1; i >= 0; i--) {
      const date = new Date();
      
      if (period === 'daily') {
        date.setDate(date.getDate() - i);
      } else if (period === 'weekly') {
        date.setDate(date.getDate() - (i * 7));
      } else if (period === 'monthly') {
        date.setMonth(date.getMonth() - i);
      }

      const startDate = new Date(date);
      const endDate = new Date(date);

      if (period === 'daily') {
        startDate.setHours(0, 0, 0, 0);
        endDate.setHours(23, 59, 59, 999);
      } else if (period === 'weekly') {
        startDate.setDate(date.getDate() - date.getDay());
        endDate.setDate(startDate.getDate() + 6);
        startDate.setHours(0, 0, 0, 0);
        endDate.setHours(23, 59, 59, 999);
      } else if (period === 'monthly') {
        startDate.setDate(1);
        startDate.setHours(0, 0, 0, 0);
        endDate.setMonth(startDate.getMonth() + 1, 0);
        endDate.setHours(23, 59, 59, 999);
      }

      const periodData = await this.getPeriodData(
        { start: startDate, end: endDate },
        cabangFilter,
        cabangId
      );

      trendData.push({
        date: startDate.toISOString().split('T')[0],
        sales: periodData.totalSales,
        transactions: periodData.totalTransactions,
        profit: periodData.totalProfit
      });
    }

    return trendData;
  }

  /**
   * Helper: Calculate periods for comparison
   */
  private calculatePeriods(period: string, comparisonPeriod: string) {
    const now = new Date();
    const current = { start: new Date(), end: new Date() };
    const previous = { start: new Date(), end: new Date() };

    if (period === 'daily') {
      // Current day
      current.start.setHours(0, 0, 0, 0);
      current.end.setHours(23, 59, 59, 999);
      
      // Previous day
      previous.start.setDate(now.getDate() - 1);
      previous.start.setHours(0, 0, 0, 0);
      previous.end.setDate(now.getDate() - 1);
      previous.end.setHours(23, 59, 59, 999);
    } else if (period === 'weekly') {
      // Current week
      const startOfWeek = now.getDate() - now.getDay();
      current.start.setDate(startOfWeek);
      current.start.setHours(0, 0, 0, 0);
      current.end.setDate(startOfWeek + 6);
      current.end.setHours(23, 59, 59, 999);
      
      // Previous week
      previous.start.setDate(startOfWeek - 7);
      previous.start.setHours(0, 0, 0, 0);
      previous.end.setDate(startOfWeek - 1);
      previous.end.setHours(23, 59, 59, 999);
    } else if (period === 'monthly') {
      // Current month
      current.start.setDate(1);
      current.start.setHours(0, 0, 0, 0);
      current.end.setMonth(now.getMonth() + 1, 0);
      current.end.setHours(23, 59, 59, 999);
      
      // Previous month
      previous.start.setMonth(now.getMonth() - 1, 1);
      previous.start.setHours(0, 0, 0, 0);
      previous.end.setMonth(now.getMonth(), 0);
      previous.end.setHours(23, 59, 59, 999);
    } else if (period === 'yearly') {
      // Current year
      current.start.setMonth(0, 1);
      current.start.setHours(0, 0, 0, 0);
      current.end.setMonth(11, 31);
      current.end.setHours(23, 59, 59, 999);
      
      // Previous year
      previous.start.setFullYear(now.getFullYear() - 1, 0, 1);
      previous.start.setHours(0, 0, 0, 0);
      previous.end.setFullYear(now.getFullYear() - 1, 11, 31);
      previous.end.setHours(23, 59, 59, 999);
    }

    return { current, previous };
  }

  /**
   * Helper: Get data for a specific period
   */
  private async getPeriodData(period: any, cabangFilter: any, cabangId?: number) {
    const whereCondition: any = {
      createdAt: {
        gte: period.start,
        lte: period.end,
      },
      cabang: cabangFilter,
    };

    if (cabangId) {
      whereCondition.cabangId = cabangId;
    }

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

    let totalSales = 0;
    let totalProfit = 0;
    let totalItems = 0;

    for (const t of transaksi) {
      totalSales += t.total;
      
      for (const detail of t.detail) {
        totalItems += detail.jumlah;
        const profit = (detail.hargaSaatItu - detail.produk.hargaBeli) * detail.jumlah;
        totalProfit += profit;
      }
    }

    return {
      totalSales,
      totalProfit,
      totalTransactions: transaksi.length,
      totalItems,
    };
  }

  /**
   * Helper: Get top products for a period
   */
  private async getTopProducts(period: any, cabangFilter: any, cabangId?: number, limit: number = 5): Promise<Array<{name: string, sales: number, percentage: number}>> {
    const whereCondition: any = {
      transaksi: {
        createdAt: {
          gte: period.start,
          lte: period.end,
        },
        cabang: cabangFilter,
      },
    };

    if (cabangId) {
      whereCondition.transaksi.cabangId = cabangId;
    }

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

    const results: Array<{name: string, sales: number, percentage: number}> = [];
    const totalSales = produkTerlaris.reduce((sum, item) => sum + (item._sum.jumlah || 0), 0);

    for (const item of produkTerlaris) {
      const produk = await this.prisma.produk.findUnique({
        where: { id: item.produkId },
      });

      if (produk) {
        results.push({
          name: produk.nama,
          sales: item._sum.jumlah || 0,
          percentage: totalSales > 0 ? ((item._sum.jumlah || 0) / totalSales) * 100 : 0
        });
      }
    }

    return results;
  }

  /**
   * Helper: Get cabang filter based on user role
   */
  private async getCabangFilter(userId: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        aksesCabang: true,
      },
    });

    if (!user) {
      throw new Error('User not found');
    }

    if (user.role === 'OWNER') {
      return { ownerId: userId };
    } else {
      const cabangIds = user.aksesCabang.map(akses => akses.cabangId);
      return { id: { in: cabangIds } };
    }
  }

  /**
   * Helper functions
   */
  private calculatePercentageChange(current: number, previous: number): number {
    if (previous === 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  private formatCurrency(amount: number): string {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(amount);
  }

  private getPeriodLabel(period: string): string {
    const labels = {
      daily: 'Hari Ini',
      weekly: 'Minggu Ini',
      monthly: 'Bulan Ini',
      yearly: 'Tahun Ini'
    };
    return labels[period] || 'Periode Ini';
  }

  private getPreviousPeriodLabel(period: string): string {
    const labels = {
      daily: 'kemarin',
      weekly: 'minggu lalu',
      monthly: 'bulan lalu',
      yearly: 'tahun lalu'
    };
    return labels[period] || 'periode sebelumnya';
  }
}
