import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/laporan_provider.dart';

class LaporanRefreshHelper {
  static void refreshAllLaporanData(WidgetRef ref) {
    // Gunakan provider refresh function yang baru
    print('🔄 === REFRESH ALL LAPORAN DATA CALLED ===');
    final refreshFunction = ref.read(refreshAllLaporanProvider);
    refreshFunction();
    
    print('🔄 All laporan data refreshed');
  }
  
  static void refreshLaporanAfterTransaction(WidgetRef ref) {
    // Khusus refresh setelah transaksi baru
    print('🚀 === LAPORAN REFRESH AFTER TRANSACTION CALLED ===');
    refreshAllLaporanData(ref);
    print('💰 Laporan refreshed after new transaction');
  }
  
  static void enableAutoRefresh(WidgetRef ref) {
    ref.read(autoRefreshEnabledProvider.notifier).state = true;
    print('⏰ Auto-refresh enabled');
  }
  
  static void disableAutoRefresh(WidgetRef ref) {
    ref.read(autoRefreshEnabledProvider.notifier).state = false;
    print('⏸️ Auto-refresh disabled');
  }
  
  // Alias untuk backward compatibility
  static void refreshAfterTransaction(WidgetRef ref) {
    refreshLaporanAfterTransaction(ref);
  }
}
