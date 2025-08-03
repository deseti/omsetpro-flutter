import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../widgets/home/modern_home_sections.dart';

class HomeQuickStats extends ConsumerWidget {
  const HomeQuickStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) {
        // Jika error, tampilkan stats kosong
        final emptyStats = <StatsItem>[
          const StatsItem(
            title: 'Penjualan Hari Ini',
            value: 'Rp 0',
            icon: Icons.trending_up,
            iconColor: Colors.green,
            trend: '0%',
            isPositiveTrend: true,
          ),
          const StatsItem(
            title: 'Transaksi',
            value: '0',
            subtitle: 'Hari ini',
            icon: Icons.receipt_long,
            iconColor: Colors.blue,
            trend: '0',
            isPositiveTrend: true,
          ),
          const StatsItem(
            title: 'Produk Terjual',
            value: '0',
            subtitle: 'Item',
            icon: Icons.inventory_2,
            iconColor: Colors.orange,
            trend: '0',
            isPositiveTrend: true,
          ),
          const StatsItem(
            title: 'Keuntungan',
            value: 'Rp 0',
            subtitle: 'Margin 0%',
            icon: Icons.account_balance_wallet,
            iconColor: Colors.purple,
            trend: '0%',
            isPositiveTrend: true,
          ),
        ];

        return ModernStatsGrid(
          title: 'Ringkasan Hari Ini',
          stats: emptyStats,
        );
      },
      data: (dashboardStats) {
        final stats = <StatsItem>[
          StatsItem(
            title: 'Penjualan Hari Ini',
            value: dashboardStats.penjualanHariIni,
            icon: Icons.trending_up,
            iconColor: Colors.green,
            trend: dashboardStats.trendPenjualan,
            isPositiveTrend: dashboardStats.isPositiveTrendPenjualan,
          ),
          StatsItem(
            title: 'Transaksi',
            value: dashboardStats.transaksiHariIni,
            subtitle: 'Hari ini',
            icon: Icons.receipt_long,
            iconColor: Colors.blue,
            trend: dashboardStats.trendTransaksi,
            isPositiveTrend: dashboardStats.isPositiveTrendTransaksi,
          ),
          StatsItem(
            title: 'Produk Terjual',
            value: dashboardStats.produkTerjual,
            subtitle: 'Item',
            icon: Icons.inventory_2,
            iconColor: Colors.orange,
            trend: dashboardStats.trendProduk,
            isPositiveTrend: dashboardStats.isPositiveTrendProduk,
          ),
          StatsItem(
            title: 'Keuntungan',
            value: dashboardStats.keuntungan,
            subtitle: 'Margin',
            icon: Icons.account_balance_wallet,
            iconColor: Colors.purple,
            trend: dashboardStats.trendKeuntungan,
            isPositiveTrend: dashboardStats.isPositiveTrendKeuntungan,
          ),
        ];

        return ModernStatsGrid(
          title: 'Ringkasan Hari Ini',
          stats: stats,
        );
      },
    );
  }
}
