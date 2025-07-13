import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../models/pelanggan_model.dart'; // <-- IMPORT MODEL PELANGGAN
import '../services/connectivity_service.dart';
import '../services/offline_database_proxy.dart' as OfflineDatabase;
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../utils/api_config.dart'; // Import API config
import '../services/network_service.dart'; // Import network service

// ... (provider lain tetap sama)
final authStateProvider = StateProvider<bool>((ref) => false);
final accessTokenProvider = StateProvider<String?>((ref) => null);
final userProfileProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final cabangListProvider = StateProvider<List<dynamic>>((ref) => []);
// Buat dua provider: satu async dan satu sync untuk compatibility
final dioAsyncProvider = FutureProvider<Dio>((ref) async {
  final dio = await NetworkService.getDio();
  final token = ref.watch(accessTokenProvider);

  dio.interceptors.clear();
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }));

  return dio;
});

// Provider sync untuk backward compatibility dengan existing code
final dioProvider = Provider<Dio>((ref) {
  // Gunakan ApiConfig untuk mendapatkan baseURL yang tepat
  final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final token = ref.watch(accessTokenProvider);

  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }));

  return dio;
});
final produkListFutureProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, cabangId) async {
  final dio = ref.watch(dioProvider);
  final response =
      await dio.get('/produk', queryParameters: {'cabangId': cabangId});
  return response.data as List<dynamic>;
});
final cartProvider =
    StateProvider.autoDispose<List<Map<String, dynamic>>>((ref) => []);

// --- PROVIDER BARU UNTUK DAFTAR TIM ---
final timListFutureProvider =
    FutureProvider.autoDispose<List<User>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/tim');
  // Ubah data JSON menjadi list objek User
  final List<dynamic> data = response.data;
  return data.map((json) => User.fromJson(json)).toList();
});

// === PROVIDER UNTUK OFFLINE MODE ===
final offlineModeProvider = StateProvider<bool>((ref) => false);

// Provider untuk produk dengan offline support
final produkListWithOfflineProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, cabangId) async {
  final dio = ref.watch(dioProvider);

  // Check if running on web
  if (kIsWeb) {
    try {
      final response =
          await dio.get('/produk', queryParameters: {'cabangId': cabangId});
      return response.data as List<dynamic>;
    } catch (e) {
      print('Server error on web: $e');
      return [];
    }
  }

  // Mobile platform - full offline support
  final isConnected = await ConnectivityService.isConnected();

  if (isConnected) {
    try {
      ref.read(offlineModeProvider.notifier).state = false;
      // Gunakan dioProvider yang sudah ada authentication token
      final response =
          await dio.get('/produk', queryParameters: {'cabangId': cabangId});
      final produkList = response.data as List<dynamic>;
      await OfflineDatabase.OfflineDatabase.saveProdukToOffline(
          produkList, cabangId);
      return produkList;
    } catch (e) {
      print('Server error, using offline data: $e');
      ref.read(offlineModeProvider.notifier).state = true;
      final offlineData =
          await OfflineDatabase.OfflineDatabase.getOfflineProduk(cabangId);
      return offlineData
          .map((item) => {
                'id': item['id'],
                'nama': item['nama'],
                'harga': item['harga'],
                'hargaBeli': item['hargaBeli'],
                'stok': item['stok'],
                'barcode': item['barcode'],
                'fotoUrl': item['fotoUrl'],
                'isArsip': item['isArsip'] == 1,
              })
          .toList();
    }
  } else {
    ref.read(offlineModeProvider.notifier).state = true;
    final offlineData =
        await OfflineDatabase.OfflineDatabase.getOfflineProduk(cabangId);
    return offlineData
        .map((item) => {
              'id': item['id'],
              'nama': item['nama'],
              'harga': item['harga'],
              'hargaBeli': item['hargaBeli'],
              'stok': item['stok'],
              'barcode': item['barcode'],
              'fotoUrl': item['fotoUrl'],
              'isArsip': item['isArsip'] == 1,
            })
        .toList();
  }
});

// === CONNECTIVITY PROVIDER ===
final connectivityProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) {
    return true;
  }
  return await ConnectivityService.isConnected();
});

final networkDioProvider = FutureProvider<Dio>((ref) async {
  return await NetworkService.getDio();
});

// [BARU] Provider untuk pelanggan yang dipilih di kasir
final selectedPelangganProvider =
    StateProvider.autoDispose<Pelanggan?>((ref) => null);

// [BARU] Provider untuk promo aktif yang bisa diterapkan di kasir
final activePromosProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/promo');
  final List<dynamic> allPromos = response.data;
  
  // Filter hanya promo yang aktif
  return allPromos.where((promo) => promo['isActive'] == true).toList();
});

// [BARU] Provider untuk menyimpan promo yang dipilih di kasir
final selectedPromoProvider = StateProvider.autoDispose<Map<String, dynamic>?>((ref) => null);

// [BARU] Provider untuk menghitung total setelah promo
final cartTotalWithPromoProvider = Provider.autoDispose<Map<String, dynamic>>((ref) {
  final cart = ref.watch(cartProvider);
  final selectedPromo = ref.watch(selectedPromoProvider);
  
  // Hitung subtotal normal
  final subtotal = cart.fold<double>(0, (sum, item) {
    return sum + (item['produk']['harga'] * item['jumlah']);
  }).toInt();
  
  int totalDiskon = 0;
  int totalAkhir = subtotal;
  
  if (selectedPromo != null) {
    // Hitung diskon berdasarkan produk yang ada di cart dan termasuk dalam promo
    final List<dynamic> promoProdukIds = selectedPromo['produk']?.map((p) => p['produk']['id']).toList() ?? [];
    
    for (final item in cart) {
      final produkId = item['produk']['id'];
      if (promoProdukIds.contains(produkId)) {
        final hargaItem = (item['produk']['harga'] as num).toInt();
        final jumlahItem = (item['jumlah'] as num).toInt();
        final subtotalItem = hargaItem * jumlahItem;
        
        if (selectedPromo['tipe'] == 'PERCENTAGE') {
          final diskonItem = (subtotalItem * (selectedPromo['nilai'] as num) / 100).round();
          totalDiskon += diskonItem;
        } else if (selectedPromo['tipe'] == 'NOMINAL') {
          // Untuk diskon nominal, terapkan per item
          final diskonPerItem = (selectedPromo['nilai'] as num).toInt();
          totalDiskon += (diskonPerItem * jumlahItem);
        }
      }
    }
    
    totalAkhir = subtotal - totalDiskon;
    if (totalAkhir < 0) totalAkhir = 0; // Pastikan tidak negatif
  }
  
  return {
    'subtotal': subtotal,
    'totalDiskon': totalDiskon,
    'totalAkhir': totalAkhir,
    'namaPromo': selectedPromo?['nama'],
  };
});
