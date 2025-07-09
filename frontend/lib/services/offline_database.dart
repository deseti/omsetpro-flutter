import 'package:flutter/foundation.dart';

// Import mobile implementation untuk non-web platforms
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:path/path.dart' if (dart.library.html) '';
import 'package:sqflite/sqflite.dart' if (dart.library.html) '';
import 'package:path_provider/path_provider.dart' if (dart.library.html) '';

class OfflineDatabase {
  static const _databaseName = "omsetpro_offline.db";
  static const _databaseVersion = 1;

  // Singleton pattern - hanya untuk mobile
  static Database? _database;
  
  static Future<Database?> get database async {
    if (kIsWeb) {
      print('OfflineDatabase: Web platform - no database');
      return null;
    }
    
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (kIsWeb) throw UnsupportedError('Database not supported on web');
    
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    if (kIsWeb) return;
    
    // Tabel untuk menyimpan produk offline
    await db.execute('''
      CREATE TABLE produk (
        id INTEGER PRIMARY KEY,
        cabang_id INTEGER NOT NULL,
        nama TEXT NOT NULL,
        harga INTEGER NOT NULL,
        harga_beli INTEGER,
        stok INTEGER DEFAULT 0,
        barcode TEXT,
        foto_url TEXT,
        is_arsip INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabel untuk menyimpan transaksi offline
    await db.execute('''
      CREATE TABLE transaksi_offline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cabang_id INTEGER NOT NULL,
        metode_bayar TEXT NOT NULL,
        total_harga INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabel untuk item transaksi offline
    await db.execute('''
      CREATE TABLE transaksi_item_offline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaksi_id INTEGER NOT NULL,
        produk_id INTEGER NOT NULL,
        nama_produk TEXT NOT NULL,
        harga INTEGER NOT NULL,
        jumlah INTEGER NOT NULL,
        FOREIGN KEY (transaksi_id) REFERENCES transaksi_offline (id)
      )
    ''');
  }

  // === PRODUK METHODS ===
  static Future<void> saveProdukToOffline(List<dynamic> produkList, int cabangId) async {
    if (kIsWeb) {
      print('OfflineDatabase: saveProdukToOffline called on web - ignoring');
      return;
    }
    
    final db = await database;
    if (db == null) return;
    
    // Clear existing data for this cabang
    await db.delete('produk', where: 'cabang_id = ?', whereArgs: [cabangId]);
    
    // Insert new data
    for (var produk in produkList) {
      await db.insert('produk', {
        'id': produk['id'],
        'cabang_id': cabangId,
        'nama': produk['nama'],
        'harga': produk['harga'],
        'harga_beli': produk['hargaBeli'] ?? 0,
        'stok': produk['stok'] ?? 0,
        'barcode': produk['barcode'],
        'foto_url': produk['fotoUrl'],
        'is_arsip': produk['isArsip'] == true ? 1 : 0,
      });
    }
  }

  static Future<List<Map<String, dynamic>>> getOfflineProduk(int cabangId) async {
    if (kIsWeb) {
      print('OfflineDatabase: getOfflineProduk called on web - returning empty list');
      return [];
    }
    
    final db = await database;
    if (db == null) return [];
    
    return await db.query(
      'produk',
      where: 'cabang_id = ? AND is_arsip = 0',
      whereArgs: [cabangId],
    );
  }

  // === TRANSAKSI METHODS ===
  static Future<void> saveTransaksiOffline({
    required int cabangId,
    required String metodeBayar,
    required int totalHarga,
    required List<Map<String, dynamic>> items,
  }) async {
    if (kIsWeb) {
      print('OfflineDatabase: saveTransaksiOffline called on web - ignoring');
      return;
    }
    
    final db = await database;
    if (db == null) return;
    
    // Insert transaksi
    final transaksiId = await db.insert('transaksi_offline', {
      'cabang_id': cabangId,
      'metode_bayar': metodeBayar,
      'total_harga': totalHarga,
      'is_synced': 0,
    });

    // Insert items
    for (var item in items) {
      await db.insert('transaksi_item_offline', {
        'transaksi_id': transaksiId,
        'produk_id': item['produkId'],
        'nama_produk': item['nama'],
        'harga': item['harga'],
        'jumlah': item['jumlah'],
      });
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingTransaksi() async {
    if (kIsWeb) {
      print('OfflineDatabase: getPendingTransaksi called on web - returning empty list');
      return [];
    }
    
    final db = await database;
    if (db == null) return [];
    
    return await db.query(
      'transaksi_offline',
      where: 'is_synced = 0',
    );
  }

  static Future<void> markTransaksiAsSynced(int localId) async {
    if (kIsWeb) {
      print('OfflineDatabase: markTransaksiAsSynced called on web - ignoring');
      return;
    }
    
    final db = await database;
    if (db == null) return;
    
    await db.update(
      'transaksi_offline',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // === LEGACY METHODS FOR COMPATIBILITY ===
  static Future<void> saveProdukToCache(int cabangId, List<dynamic> produkList) async {
    await saveProdukToOffline(produkList, cabangId);
  }

  static Future<List<dynamic>> getCachedProduk(int cabangId) async {
    final result = await getOfflineProduk(cabangId);
    return result.cast<dynamic>();
  }
}