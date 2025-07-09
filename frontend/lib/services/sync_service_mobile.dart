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
      final unsyncedTransaksi = await OfflineDatabase.getTransaksiWithDecodedItems();
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
          
          // Items sudah berupa List<Map<String, dynamic>>
          final itemsData = transaksi['items'] as List<Map<String, dynamic>>;
          
          // Format items untuk server (hanya produkId dan jumlah)
          final serverItems = itemsData.map((item) => {
            'produkId': item['produkId'],
            'jumlah': item['jumlah'],
          }).toList();
          
          print('📦 Transaction data: cabangId=${transaksi['cabangId']}, items=${serverItems.length} items');
          
          // Kirim ke server
          final response = await dio.post('/transaksi', data: {
            'cabangId': transaksi['cabangId'],
            'metodeBayar': transaksi['metodeBayar'],
            'items': serverItems,
          });

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Mark sebagai synced
            await OfflineDatabase.markTransaksiAsSynced(transaksi['id'] as int);
            print('✅ Transaction ${transaksi['id']} synced successfully');
            successCount++;
          } else {
            print('❌ Transaction ${transaksi['id']} sync failed with status: ${response.statusCode}');
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

  // Auto sync ketika online
  static Future<void> startAutoSync(WidgetRef ref) async {
    print('🔧 Setting up auto-sync listener...');
    
    // Listen connectivity changes
    ref.listen(connectivityProvider, (previous, next) async {
      next.when(
        data: (isOnline) async {
          print('📡 Connectivity changed: ${isOnline ? 'ONLINE' : 'OFFLINE'}');
          
          if (isOnline && !_isSyncing) {
            print('🌐 Device is online, triggering sync...');
            final dio = ref.read(dioProvider);
            final result = await syncOfflineTransactions(dio);
            print('🔄 Auto-sync result: $result');
          }
        },
        loading: () {
          print('📡 Connectivity loading...');
        },
        error: (error, stack) {
          print('❌ Connectivity error: $error');
        },
      );
    });
  }

  // Manual sync trigger untuk testing
  static Future<bool> manualSync(WidgetRef ref) async {
    print('🔧 Manual sync triggered...');
    final dio = ref.read(dioProvider);
    return await syncOfflineTransactions(dio);
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
