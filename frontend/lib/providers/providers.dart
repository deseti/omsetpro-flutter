import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart'; // Import model baru

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