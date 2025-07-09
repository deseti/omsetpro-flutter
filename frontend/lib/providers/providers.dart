import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart'; // Import model baru
import '../services/connectivity_service.dart';
import '../services/offline_database_proxy.dart' as OfflineDatabase;
import 'package:flutter/foundation.dart'; // For kIsWeb

// ... (provider lain tetap sama)
final authStateProvider = StateProvider<bool>((ref) => false);
final accessTokenProvider = StateProvider<String?>((ref) => null);
final userProfileProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final cabangListProvider = StateProvider<List<dynamic>>((ref) => []);
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.6:3000'));
  final token = ref.watch(accessTokenProvider);
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }));
  return dio;
});
final produkListFutureProvider =
    FutureProvider.autoDispose.family<List<dynamic>, int>((ref, cabangId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/produk', queryParameters: {'cabangId': cabangId});
  return response.data as List<dynamic>;
});
final cartProvider = StateProvider.autoDispose<List<Map<String, dynamic>>>((ref) => []);


// --- PROVIDER BARU UNTUK DAFTAR TIM ---
final timListFutureProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/tim');
  // Ubah data JSON menjadi list objek User
  final List<dynamic> data = response.data;
  return data.map((json) => User.fromJson(json)).toList();
});

// === PROVIDER UNTUK OFFLINE MODE ===
final offlineModeProvider = StateProvider<bool>((ref) => false);

// Provider untuk produk dengan offline support
final produkListWithOfflineProvider =
    FutureProvider.autoDispose.family<List<dynamic>, int>((ref, cabangId) async {
  final dio = ref.watch(dioProvider);
  
  // Check if running on web
  if (kIsWeb) {
    // Web platform - only fetch from server, no offline support
    try {
      final response = await dio.get('/produk', queryParameters: {'cabangId': cabangId});
      return response.data as List<dynamic>;
    } catch (e) {
      // If server fails on web, return empty list
      print('Server error on web: $e');
      return [];
    }
  }
  
  // Mobile platform - full offline support
  final isConnected = await ConnectivityService.isConnected();
  
  if (isConnected) {
    try {
      // Reset offline mode when online
      ref.read(offlineModeProvider.notifier).state = false;
      
      // Try to fetch from server
      final response = await dio.get('/produk', queryParameters: {'cabangId': cabangId});
      final produkList = response.data as List<dynamic>;
      
      // Save to offline storage
      await OfflineDatabase.OfflineDatabase.saveProdukToOffline(produkList, cabangId);
      
      return produkList;
    } catch (e) {
      // If server fails, fallback to offline
      print('Server error, using offline data: $e');
      ref.read(offlineModeProvider.notifier).state = true;
      final offlineData = await OfflineDatabase.OfflineDatabase.getOfflineProduk(cabangId);
      return offlineData.map((item) => {
        'id': item['id'],
        'nama': item['nama'],
        'harga': item['harga'],
        'hargaBeli': item['hargaBeli'],
        'stok': item['stok'],
        'barcode': item['barcode'],
        'fotoUrl': item['fotoUrl'],
        'isArsip': item['isArsip'] == 1,
      }).toList();
    }
  } else {
    // No connection, use offline data
    ref.read(offlineModeProvider.notifier).state = true;
    final offlineData = await OfflineDatabase.OfflineDatabase.getOfflineProduk(cabangId);
    return offlineData.map((item) => {
      'id': item['id'],
      'nama': item['nama'],
      'harga': item['harga'],
      'hargaBeli': item['hargaBeli'],
      'stok': item['stok'],
      'barcode': item['barcode'],
      'fotoUrl': item['fotoUrl'],
      'isArsip': item['isArsip'] == 1,
    }).toList();
  }
});

// === CONNECTIVITY PROVIDER ===
final connectivityProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) {
    // Web platform - assume always connected
    return true;
  }
  return await ConnectivityService.isConnected();
});

// === EXISTING PROVIDERS ===