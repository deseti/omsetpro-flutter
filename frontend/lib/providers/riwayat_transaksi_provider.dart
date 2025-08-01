import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/riwayat_transaksi_model.dart';
import '../services/riwayat_transaksi_service.dart';

// Provider untuk filter periode yang dipilih
final selectedPeriodeProvider = StateProvider<FilterPeriode>((ref) {
  return FilterPeriode.hariIni; // Default hari ini
});

// Provider untuk cabang yang dipilih untuk filter
final selectedCabangForRiwayatProvider = StateProvider<int?>((ref) => null);

// Provider untuk data riwayat transaksi
final riwayatTransaksiProvider = StateNotifierProvider.autoDispose<RiwayatTransaksiNotifier, AsyncValue<List<RiwayatTransaksi>>>((ref) {
  final service = ref.watch(riwayatTransaksiServiceProvider);
  return RiwayatTransaksiNotifier(service, ref);
});

// Provider untuk pagination info
final riwayatPaginationProvider = StateProvider<PaginationInfo?>((ref) => null);

class RiwayatTransaksiNotifier extends StateNotifier<AsyncValue<List<RiwayatTransaksi>>> {
  final RiwayatTransaksiService _service;
  final Ref _ref;
  List<RiwayatTransaksi> _allData = [];
  bool _isLoadingMore = false;

  RiwayatTransaksiNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    // Delay the initial load to avoid provider circular dependency
    Future.microtask(() => loadInitialData());
  }

  Future<void> loadInitialData() async {
    try {
      state = const AsyncValue.loading();
      
      final periode = _ref.read(selectedPeriodeProvider);
      final cabangId = _ref.read(selectedCabangForRiwayatProvider);
      final dateRange = periode.dateRange;

      final response = await _service.getRiwayatTransaksi(
        cabangId: cabangId,
        startDate: dateRange.start,
        endDate: dateRange.end,
        limit: 20,
        offset: 0,
      );

      _allData = response.data;
      _ref.read(riwayatPaginationProvider.notifier).state = response.pagination;
      state = AsyncValue.data(_allData);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    
    final pagination = _ref.read(riwayatPaginationProvider);
    if (pagination == null || !pagination.hasMore) return;

    try {
      _isLoadingMore = true;
      
      final periode = _ref.read(selectedPeriodeProvider);
      final cabangId = _ref.read(selectedCabangForRiwayatProvider);
      final dateRange = periode.dateRange;

      final response = await _service.getRiwayatTransaksi(
        cabangId: cabangId,
        startDate: dateRange.start,
        endDate: dateRange.end,
        limit: 20,
        offset: pagination.offset + pagination.limit,
      );

      _allData.addAll(response.data);
      _ref.read(riwayatPaginationProvider.notifier).state = response.pagination;
      state = AsyncValue.data(_allData);
    } catch (e) {
      // Error saat load more tidak mengubah state utama
      print('Error loading more data: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    await loadInitialData();
  }

  void onPeriodeChanged(FilterPeriode newPeriode) {
    _ref.read(selectedPeriodeProvider.notifier).state = newPeriode;
    loadInitialData();
  }

  void onCabangChanged(int? cabangId) {
    _ref.read(selectedCabangForRiwayatProvider.notifier).state = cabangId;
    loadInitialData();
  }

  bool get isLoadingMore => _isLoadingMore;
}
