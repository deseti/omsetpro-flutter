import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'offline_database.dart';
import 'connectivity_service.dart';
import '../providers/providers.dart';

class SyncService {
  static const String SYNC_LOCK_KEY = 'sync_in_progress';
  static bool _isSyncing = false;

  // Sync transaksi offline ke server
  static Future<bool> syncOfflineTransactions(Dio dio) async {
    if (_isSyncing) return false;
    
    try {
      _isSyncing = true;
      
      // Cek koneksi internet
      final isConnected = await ConnectivityService.isConnected();
      if (!isConnected) return false;

      // Ambil transaksi yang belum disync dengan items yang sudah di-decode
      final unsyncedTransaksi = await OfflineDatabase.getTransaksiWithDecodedItems();
      if (unsyncedTransaksi.isEmpty) return true;

      int successCount = 0;
      int failCount = 0;

      for (var transaksi in unsyncedTransaksi) {
        try {
          // Items sudah berupa List<Map<String, dynamic>>
          final itemsData = transaksi['items'] as List<Map<String, dynamic>>;
          
          // Format items untuk server (hanya produkId dan jumlah)
          final serverItems = itemsData.map((item) => {
            'produkId': item['produkId'],
            'jumlah': item['jumlah'],
          }).toList();
          
          // Kirim ke server
          final response = await dio.post('/transaksi', data: {
            'cabangId': transaksi['cabangId'],
            'metodeBayar': transaksi['metodeBayar'],
            'items': serverItems,
          });

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Mark sebagai synced
            await OfflineDatabase.markTransaksiAsSynced(transaksi['id'] as int);
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          print('Error syncing transaction ${transaksi['id']}: $e');
          failCount++;
        }
      }

      print('Sync completed: $successCount success, $failCount failed');
      return failCount == 0;

    } catch (e) {
      print('Sync service error: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // Auto sync ketika online
  static Future<void> startAutoSync(WidgetRef ref) async {
    // Listen connectivity changes
    ref.listen(connectivityProvider, (previous, next) async {
      next.when(
        data: (isOnline) async {
          if (isOnline && !_isSyncing) {
            final dio = ref.read(dioProvider);
            await syncOfflineTransactions(dio);
          }
        },
        loading: () {},
        error: (error, stack) {},
      );
    });
  }

  // Clean up old synced data
  static Future<void> cleanupOldData() async {
    await OfflineDatabase.clearOldData();
  }
}

// Provider untuk sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});
