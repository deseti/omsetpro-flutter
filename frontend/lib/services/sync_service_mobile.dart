import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'offline_database_proxy.dart' as OfflineDatabase;
import 'connectivity_service.dart';
import '../providers/providers.dart' as AppProviders;

class SyncService {
  static const String SYNC_LOCK_KEY = 'sync_in_progress';
  static bool _isSyncing = false;

  // Sync transaksi offline ke server
  static Future<bool> syncOfflineTransactions(Dio dio) async {
    if (_isSyncing) {
      print('Sync already in progress, skipping...');
      return false;
    }

    try {
      _isSyncing = true;
      print('🔄 Starting sync process...');

      // Cek koneksi internet
      final isConnected = await ConnectivityService.isConnected();
      if (!isConnected) {
        print('❌ No internet connection, sync cancelled');
        return false;
      }

      // Ambil transaksi yang belum disync dengan items yang sudah di-decode
      final unsyncedTransaksi =
          await OfflineDatabase.OfflineDatabase.getTransaksiWithDecodedItems();
      print('📋 Found ${unsyncedTransaksi.length} unsynced transactions');

      if (unsyncedTransaksi.isEmpty) {
        print('✅ No transactions to sync');
        return true;
      }

      int successCount = 0;
      int failCount = 0;

      for (var transaksi in unsyncedTransaksi) {
        try {
          print('🚀 Syncing transaction ID: ${transaksi['id']}');

          // Items dari getTransaksiWithDecodedItems sudah di-decode di field 'decodedItems'
          final decodedItems = transaksi['decodedItems'];

          // Pastikan decodedItems adalah List dan konversi ke format yang tepat
          List<Map<String, dynamic>> itemsData;
          if (decodedItems is List) {
            itemsData = decodedItems
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    return item;
                  } else if (item is Map) {
                    return Map<String, dynamic>.from(item);
                  } else {
                    print('Warning: Invalid item format: $item');
                    return <String, dynamic>{};
                  }
                })
                .where((item) => item.isNotEmpty)
                .toList();
          } else {
            print('Warning: decodedItems is not a List: $decodedItems');
            itemsData = [];
          }

          if (itemsData.isEmpty) {
            print(
                '⚠️ Transaction ${transaksi['id']} has no valid items, skipping');
            continue;
          }

          // Format items untuk server (hanya produkId dan jumlah)
          final serverItems = itemsData
              .map((item) => {
                    'produkId': item['produkId'],
                    'jumlah': item['jumlah'],
                  })
              .where(
                  (item) => item['produkId'] != null && item['jumlah'] != null)
              .toList();

          if (serverItems.isEmpty) {
            print(
                '⚠️ Transaction ${transaksi['id']} has no valid server items, skipping');
            continue;
          }

          print(
              '📦 Transaction data: cabangId=${transaksi['cabangId']}, items=${serverItems.length} items');

          // Kirim ke server
          final response = await dio.post('/transaksi', data: {
            'cabangId': transaksi['cabangId'],
            'metodeBayar': transaksi['metodeBayar'],
            'items': serverItems,
          });

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Mark sebagai synced
            await OfflineDatabase.OfflineDatabase.markTransaksiAsSynced(
                transaksi['id'] as int);
            print('✅ Transaction ${transaksi['id']} synced successfully');
            successCount++;
          } else {
            print(
                '❌ Transaction ${transaksi['id']} sync failed with status: ${response.statusCode}');
            failCount++;
          }
        } catch (e) {
          print('❌ Error syncing transaction ${transaksi['id']}: $e');
          failCount++;
        }
      }

      print('🎯 Sync completed: $successCount success, $failCount failed');
      return failCount == 0;
    } catch (e) {
      print('💥 Sync service error: $e');
      return false;
    } finally {
      _isSyncing = false;
      print('🔚 Sync process finished');
    }
  }

  // Auto sync ketika online - DIPERBAIKI untuk menghindari error ref.listen
  static Future<void> startAutoSync(WidgetRef ref) async {
    print('🔧 Setting up auto-sync listener...');

    // Gunakan periodic check instead of ref.listen untuk menghindari error
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final connectivity = await Connectivity().checkConnectivity();
        final isOnline = !connectivity.contains(ConnectivityResult.none);

        if (isOnline && !_isSyncing) {
          print('🌐 Device is online, triggering periodic sync...');
          try {
            final dio = ref.read(AppProviders.dioProvider);
            await syncOfflineTransactions(dio);
          } catch (e) {
            print('❌ Sync error (ref context issue): $e');
            // Fallback: create new dio instance
            final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
            await syncOfflineTransactions(dio);
          }
        }
      } catch (e) {
        print('❌ Auto-sync error: $e');
      }
    });
  }

  // Manual sync trigger untuk testing
  static Future<bool> manualSync(WidgetRef ref) async {
    print('🔧 Manual sync triggered...');
    final dio = ref.read(AppProviders.dioProvider);
    return await syncOfflineTransactions(dio);
  }

  // Clean up old synced data
  static Future<void> cleanupOldData() async {
    await OfflineDatabase.OfflineDatabase.clearOldData();
  }

  // Wrapper method untuk sync offline data
  static Future<bool> syncOfflineData(Dio dio) async {
    return await syncOfflineTransactions(dio);
  }
}

// Provider untuk sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});
