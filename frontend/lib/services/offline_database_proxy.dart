// Platform-agnostic offline database wrapper
import 'package:flutter/foundation.dart';

// Conditional imports
import 'offline_database_mobile.dart' if (dart.library.html) 'offline_database_web.dart' as impl;

class OfflineDatabase {
  // Proxy all methods to the appropriate implementation
  static Future<dynamic> get database async {
    return impl.OfflineDatabase.database;
  }

  static Future<void> saveProdukToOffline(List<dynamic> produkList, int cabangId) async {
    return impl.OfflineDatabase.saveProdukToOffline(produkList, cabangId);
  }

  static Future<List<Map<String, dynamic>>> getOfflineProduk(int cabangId) async {
    return impl.OfflineDatabase.getOfflineProduk(cabangId);
  }

  static Future<void> saveTransaksiOffline({
    required int cabangId,
    required String metodeBayar,
    required int totalHarga,
    required List<Map<String, dynamic>> items,
  }) async {
    return impl.OfflineDatabase.saveTransaksiOffline(
      cabangId: cabangId,
      metodeBayar: metodeBayar,
      totalHarga: totalHarga,
      items: items,
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingTransaksi() async {
    return impl.OfflineDatabase.getPendingTransaksi();
  }

  static Future<void> markTransaksiAsSynced(int localId) async {
    return impl.OfflineDatabase.markTransaksiAsSynced(localId);
  }
}
