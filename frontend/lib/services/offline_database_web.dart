// Stub implementation for web platform
class OfflineDatabase {
  static Future<void> initDatabase() async {
    // Web platform - no local database
    print('OfflineDatabase: Web platform detected - using stub implementation');
  }

  static Future<void> saveProdukToCache(int cabangId, List<dynamic> produkList) async {
    // Web platform - no local storage for products
    print('OfflineDatabase: saveProdukToCache called on web - ignoring');
  }

  static Future<List<dynamic>> getCachedProduk(int cabangId) async {
    // Web platform - return empty list
    print('OfflineDatabase: getCachedProduk called on web - returning empty list');
    return [];
  }

  static Future<void> saveTransaksiOffline({
    required int cabangId,
    required String metodeBayar,
    required int totalHarga,
    required List<Map<String, dynamic>> items,
  }) async {
    // Web platform - no offline transaction storage
    print('OfflineDatabase: saveTransaksiOffline called on web - ignoring');
  }

  static Future<List<Map<String, dynamic>>> getPendingTransaksi() async {
    // Web platform - return empty list
    print('OfflineDatabase: getPendingTransaksi called on web - returning empty list');
    return [];
  }

  static Future<void> markTransaksiAsSynced(int localId) async {
    // Web platform - no action needed
    print('OfflineDatabase: markTransaksiAsSynced called on web - ignoring');
  }

  // Methods needed by provider
  static Future<void> saveProdukToOffline(List<dynamic> produkList, int cabangId) async {
    // Web platform - no offline storage
    print('OfflineDatabase: saveProdukToOffline called on web - ignoring');
  }

  static Future<List<Map<String, dynamic>>> getOfflineProduk(int cabangId) async {
    // Web platform - return empty list
    print('OfflineDatabase: getOfflineProduk called on web - returning empty list');
    return [];
  }

  // Getter for database (not used on web)
  static get database => null;
}
