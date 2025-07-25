import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/providers.dart';

// Model untuk dashboard stats
class DashboardStats {
  final String penjualanHariIni;
  final String transaksiHariIni;
  final String produkTerjual;
  final String keuntungan;
  final String trendPenjualan;
  final String trendTransaksi;
  final String trendProduk;
  final String trendKeuntungan;
  final bool isPositiveTrendPenjualan;
  final bool isPositiveTrendTransaksi;
  final bool isPositiveTrendProduk;
  final bool isPositiveTrendKeuntungan;

  DashboardStats({
    required this.penjualanHariIni,
    required this.transaksiHariIni,
    required this.produkTerjual,
    required this.keuntungan,
    required this.trendPenjualan,
    required this.trendTransaksi,
    required this.trendProduk,
    required this.trendKeuntungan,
    required this.isPositiveTrendPenjualan,
    required this.isPositiveTrendTransaksi,
    required this.isPositiveTrendProduk,
    required this.isPositiveTrendKeuntungan,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      penjualanHariIni: json['penjualanHariIni'] ?? 'Rp 0',
      transaksiHariIni: json['transaksiHariIni'] ?? '0',
      produkTerjual: json['produkTerjual'] ?? '0',
      keuntungan: json['keuntungan'] ?? 'Rp 0',
      trendPenjualan: json['trendPenjualan'] ?? '0%',
      trendTransaksi: json['trendTransaksi'] ?? '0',
      trendProduk: json['trendProduk'] ?? '0',
      trendKeuntungan: json['trendKeuntungan'] ?? '0%',
      isPositiveTrendPenjualan: json['isPositiveTrendPenjualan'] ?? true,
      isPositiveTrendTransaksi: json['isPositiveTrendTransaksi'] ?? true,
      isPositiveTrendProduk: json['isPositiveTrendProduk'] ?? true,
      isPositiveTrendKeuntungan: json['isPositiveTrendKeuntungan'] ?? true,
    );
  }

  // Factory untuk data kosong/default
  factory DashboardStats.empty() {
    return DashboardStats(
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
    );
  }
}

// Provider untuk dashboard stats
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    final response = await dio.get('/dashboard/stats');
    return DashboardStats.fromJson(response.data);
  } on DioException catch (e) {
    // Jika endpoint belum ada atau error, return data kosong
    print('Dashboard stats error: ${e.message}');
    return DashboardStats.empty();
  } catch (e) {
    print('Dashboard stats error: $e');
    return DashboardStats.empty();
  }
});
