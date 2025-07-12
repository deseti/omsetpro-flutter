import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/laporan/laporan_models.dart';
import '../services/laporan_service.dart';
import 'providers.dart';
import 'dart:async';

// Provider untuk LaporanService
final laporanServiceProvider = Provider<LaporanService>((ref) {
  // Gunakan Dio dari provider yang sama
  final dio = ref.read(dioProvider);
  return LaporanService.withDio(dio);
});

// Provider untuk filter tanggal
final dateRangeProvider = StateProvider<DateRange>((ref) {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  return DateRange(startDate: startOfMonth, endDate: now);
});

// Provider untuk cabang yang dipilih
final selectedCabangProvider = StateProvider<int?>((ref) => null);

// Provider untuk Dashboard Data - DINONAKTIFKAN
// Fitur laporan manual telah dinonaktifkan, gunakan Smart AI Insights
/*
final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final service = ref.read(laporanServiceProvider);
  final dateRange = ref.watch(dateRangeProvider);
  final cabangId = ref.watch(selectedCabangProvider);

  return await service.getDashboard(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    cabangId: cabangId,
  );
});
*/

// Provider untuk Ringkasan Penjualan - DINONAKTIFKAN
// Fitur laporan manual telah dinonaktifkan, gunakan Smart AI Insights
/*
final ringkasanPenjualanProvider = FutureProvider.autoDispose<RingkasanPenjualan>((ref) async {
  final service = ref.read(laporanServiceProvider);
  final dateRange = ref.watch(dateRangeProvider);
  final cabangId = ref.watch(selectedCabangProvider);

  return await service.getRingkasanPenjualan(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    cabangId: cabangId,
  );
});
*/

// Provider untuk Produk Terlaris - DINONAKTIFKAN
// Fitur laporan manual telah dinonaktifkan, gunakan Smart AI Insights
/*
final produkTerlarisProvider = FutureProvider.autoDispose<List<ProdukTerlaris>>((ref) async {
  final service = ref.read(laporanServiceProvider);
  final dateRange = ref.watch(dateRangeProvider);
  final cabangId = ref.watch(selectedCabangProvider);

  return await service.getProdukTerlaris(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    cabangId: cabangId,
    limit: 10,
  );
});
*/

// Provider untuk Statistik Transaksi - DINONAKTIFKAN
// Fitur laporan manual telah dinonaktifkan, gunakan Smart AI Insights
/*
final statistikTransaksiProvider = FutureProvider.autoDispose<List<StatistikTransaksi>>((ref) async {
  final service = ref.read(laporanServiceProvider);
  final dateRange = ref.watch(dateRangeProvider);
  final cabangId = ref.watch(selectedCabangProvider);

  return await service.getStatistikTransaksi(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    cabangId: cabangId,
  );
});
*/

// Provider untuk Laporan Laba Rugi - DINONAKTIFKAN
// Fitur laporan manual telah dinonaktifkan, gunakan Smart AI Insights
/*
final laporanLabaRugiProvider = FutureProvider.autoDispose<LaporanLabaRugi>((ref) async {
  final service = ref.read(laporanServiceProvider);
  final dateRange = ref.watch(dateRangeProvider);
  final cabangId = ref.watch(selectedCabangProvider);

  return await service.getLaporanLabaRugi(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    cabangId: cabangId,
  );
});
*/

// Helper class untuk date range
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({
    required this.startDate,
    required this.endDate,
  });

  DateRange copyWith({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return DateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

// Provider untuk preset filter tanggal
final dateRangePresetsProvider = Provider<List<DateRangePreset>>((ref) {
  final now = DateTime.now();
  
  return [
    DateRangePreset(
      name: 'Hari Ini',
      startDate: DateTime(now.year, now.month, now.day),
      endDate: now,
    ),
    DateRangePreset(
      name: '7 Hari Terakhir',
      startDate: now.subtract(const Duration(days: 6)),
      endDate: now,
    ),
    DateRangePreset(
      name: '30 Hari Terakhir',
      startDate: now.subtract(const Duration(days: 29)),
      endDate: now,
    ),
    DateRangePreset(
      name: 'Bulan Ini',
      startDate: DateTime(now.year, now.month, 1),
      endDate: now,
    ),
    DateRangePreset(
      name: 'Bulan Lalu',
      startDate: DateTime(now.year, now.month - 1, 1),
      endDate: DateTime(now.year, now.month, 0),
    ),
  ];
});

class DateRangePreset {
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  DateRangePreset({
    required this.name,
    required this.startDate,
    required this.endDate,
  });
}

// Provider untuk auto-refresh timer
final autoRefreshProvider = StateProvider<Timer?>((ref) => null);

// Provider untuk kontroler auto-refresh
final autoRefreshEnabledProvider = StateProvider<bool>((ref) => true);

// Provider untuk global timer auto-refresh
final globalAutoRefreshProvider = Provider<void>((ref) {
  Timer? timer;
  
  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (ref.read(autoRefreshEnabledProvider)) {
        // DINONAKTIFKAN - Refresh semua laporan provider
        // ref.invalidate(dashboardProvider);
        // ref.invalidate(ringkasanPenjualanProvider);
        // ref.invalidate(produkTerlarisProvider);
        // ref.invalidate(statistikTransaksiProvider);
        // ref.invalidate(laporanLabaRugiProvider);
        print('Auto-refresh dinonaktifkan - fitur laporan manual telah dihapus');
      }
    });
  }
  
  // Start timer immediately
  startTimer();
  
  // Restart timer when auto-refresh is re-enabled
  ref.listen(autoRefreshEnabledProvider, (previous, next) {
    if (next && !(previous ?? false)) {
      startTimer();
    } else if (!next && (previous ?? false)) {
      timer?.cancel();
    }
  });
  
  ref.onDispose(() => timer?.cancel());
});

// Provider untuk manual refresh semua data - DINONAKTIFKAN
// Fitur laporan manual telah dinonaktifkan, gunakan Smart AI Insights
final refreshAllLaporanProvider = Provider<void Function()>((ref) {
  return () {
    print('🔃 === REFRESH LAPORAN DINONAKTIFKAN ===');
    // ref.invalidate(dashboardProvider);
    // ref.invalidate(ringkasanPenjualanProvider);
    // ref.invalidate(produkTerlarisProvider);
    // ref.invalidate(statistikTransaksiProvider);
    // ref.invalidate(laporanLabaRugiProvider);
    print('🔃 Refresh dinonaktifkan - fitur laporan manual telah dihapus');
  };
});
