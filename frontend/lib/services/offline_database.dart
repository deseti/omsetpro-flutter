import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class OfflineDatabase {
  static const _databaseName = "omsetpro_offline.db";
  static const _databaseVersion = 1;

  // Singleton pattern
  static Database? _database;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Tabel untuk menyimpan produk secara offline
    await db.execute('''
      CREATE TABLE produk_offline (
        id INTEGER PRIMARY KEY,
        nama TEXT NOT NULL,
        harga INTEGER NOT NULL,
        hargaBeli INTEGER NOT NULL,
        stok INTEGER DEFAULT 0,
        barcode TEXT,
        fotoUrl TEXT,
        cabangId INTEGER NOT NULL,
        isArsip INTEGER DEFAULT 0,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Tabel untuk menyimpan transaksi offline (belum disync)
    await db.execute('''
      CREATE TABLE transaksi_offline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cabangId INTEGER NOT NULL,
        metodeBayar TEXT NOT NULL,
        totalHarga INTEGER NOT NULL,
        items TEXT NOT NULL, -- JSON string dari items
        timestamp TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // Tabel untuk melacak sync status
    await db.execute('''
      CREATE TABLE sync_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tableName TEXT NOT NULL,
        lastSyncTime TEXT NOT NULL
      )
    ''');
  }

  // === PRODUK OFFLINE OPERATIONS ===
  
  static Future<void> saveProdukToOffline(List<dynamic> produkList, int cabangId) async {
    final db = await database;
    
    // Hapus produk lama untuk cabang ini
    await db.delete('produk_offline', where: 'cabangId = ?', whereArgs: [cabangId]);
    
    // Simpan produk baru
    for (var produk in produkList) {
      await db.insert('produk_offline', {
        'id': produk['id'],
        'nama': produk['nama'],
        'harga': produk['harga'],
        'hargaBeli': produk['hargaBeli'],
        'stok': produk['stok'] ?? 0,
        'barcode': produk['barcode'],
        'fotoUrl': produk['fotoUrl'],
        'cabangId': cabangId,
        'isArsip': produk['isArsip'] == true ? 1 : 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
    
    // Update sync status
    await _updateSyncStatus('produk_offline');
  }

  static Future<List<Map<String, dynamic>>> getOfflineProduk(int cabangId) async {
    final db = await database;
    return await db.query(
      'produk_offline',
      where: 'cabangId = ? AND isArsip = 0',
      whereArgs: [cabangId],
    );
  }

  // === TRANSAKSI OFFLINE OPERATIONS ===

  static Future<int> saveTransaksiOffline({
    required int cabangId,
    required String metodeBayar,
    required int totalHarga,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;
    
    return await db.insert('transaksi_offline', {
      'cabangId': cabangId,
      'metodeBayar': metodeBayar,
      'totalHarga': totalHarga,
      'items': _encodeItems(items),
      'timestamp': DateTime.now().toIso8601String(),
      'isSynced': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedTransaksi() async {
    final db = await database;
    return await db.query(
      'transaksi_offline',
      where: 'isSynced = 0',
      orderBy: 'timestamp ASC',
    );
  }

  static Future<void> markTransaksiAsSynced(int id) async {
    final db = await database;
    await db.update(
      'transaksi_offline',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getTransaksiWithDecodedItems() async {
    final db = await database;
    final transaksiList = await db.query(
      'transaksi_offline',
      where: 'isSynced = 0',
      orderBy: 'timestamp ASC',
    );
    
    return transaksiList.map((transaksi) {
      final decodedItems = _decodeItems(transaksi['items'] as String);
      return {
        ...transaksi,
        'items': decodedItems,
      };
    }).toList();
  }

  // === SYNC STATUS OPERATIONS ===

  static Future<void> _updateSyncStatus(String tableName) async {
    final db = await database;
    await db.insert(
      'sync_status',
      {
        'tableName': tableName,
        'lastSyncTime': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getLastSyncTime(String tableName) async {
    final db = await database;
    final result = await db.query(
      'sync_status',
      where: 'tableName = ?',
      whereArgs: [tableName],
      orderBy: 'lastSyncTime DESC',
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first['lastSyncTime'] as String : null;
  }

  // === HELPER METHODS ===

  static String _encodeItems(List<Map<String, dynamic>> items) {
    // Convert items to proper JSON string
    final itemsJson = items.map((item) => {
      'produkId': item['produkId'],
      'jumlah': item['jumlah'],
      'nama': item['nama'],
      'harga': item['harga'],
    }).toList();
    return jsonEncode(itemsJson);
  }

  static List<Map<String, dynamic>> _decodeItems(String itemsString) {
    try {
      final decoded = jsonDecode(itemsString) as List;
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('Error decoding items: $e');
      return [];
    }
  }

  // === CLEANUP METHODS ===

  static Future<void> clearOldData() async {
    final db = await database;
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    
    // Hapus transaksi yang sudah sync dan lebih dari 1 minggu
    await db.delete(
      'transaksi_offline',
      where: 'isSynced = 1 AND timestamp < ?',
      whereArgs: [oneWeekAgo.toIso8601String()],
    );
  }

  static Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
