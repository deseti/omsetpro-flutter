import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/toko_online_model.dart';
import '../providers/providers.dart';

final tokoOnlineServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return TokoOnlineService(dio);
});

class TokoOnlineService {
  final Dio _dio;

  TokoOnlineService(this._dio);

  // Untuk Merchant: Mendapatkan pengaturan toko online
  Future<TokoOnlineSettings> getTokoOnlineSettings() async {
    try {
      final response = await _dio.get('/pengaturan/akun-toko');
      return TokoOnlineSettings.fromJson(response.data);
    } catch (e) {
      throw Exception('Error mendapatkan pengaturan toko online: $e');
    }
  }

  // Untuk Merchant: Update pengaturan toko online
  Future<void> updateTokoOnlineSettings(TokoOnlineSettings settings) async {
    try {
      await _dio.post('/pengaturan/akun-toko', data: settings.toJson());
    } catch (e) {
      throw Exception('Error update pengaturan toko online: $e');
    }
  }

  // Untuk Merchant: Mendapatkan daftar rekening bank
  Future<List<RekeningBank>> getRekeningBank() async {
    try {
      final response = await _dio.get('/pengaturan/rekening-bank');
      final List<dynamic> data = response.data;
      return data.map((e) => RekeningBank.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error mendapatkan rekening bank: $e');
    }
  }

  // Untuk Merchant: Menambah rekening bank
  Future<void> addRekeningBank(RekeningBank rekening) async {
    try {
      await _dio.post('/pengaturan/rekening-bank', data: rekening.toJson());
    } catch (e) {
      throw Exception('Error menambah rekening bank: $e');
    }
  }

  // Untuk Merchant: Menghapus rekening bank
  Future<void> deleteRekeningBank(int rekeningId) async {
    try {
      await _dio.delete('/pengaturan/rekening-bank/$rekeningId');
    } catch (e) {
      throw Exception('Error menghapus rekening bank: $e');
    }
  }

  // Untuk Public: Mendapatkan data toko online berdasarkan slug
  Future<TokoOnlineData> getTokoBySlug(String slug) async {
    try {
      // Use a new dio instance without auth for public API
      final publicDio = Dio();
      publicDio.options.baseUrl = _dio.options.baseUrl;

      final response = await publicDio.get('/toko/$slug');
      return TokoOnlineData.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Toko online tidak ditemukan');
      }
      throw Exception('Error mendapatkan data toko: ${e.message}');
    }
  }

  // Untuk Public: Membuat pesanan
  Future<Map<String, dynamic>> createOrder(
      String slug, OrderRequest order) async {
    try {
      // Use a new dio instance without auth for public API
      final publicDio = Dio();
      publicDio.options.baseUrl = _dio.options.baseUrl;

      final response =
          await publicDio.post('/toko/$slug/order', data: order.toJson());
      return response.data;
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Gagal membuat pesanan';
      throw Exception('Error membuat pesanan: $errorMessage');
    }
  }

  // Generate QR Code data (URL toko online)
  String generateTokoOnlineUrl(String slug) {
    // For now return a simple URL, this can be configured later
    return 'https://omsetpro.com/toko/$slug';
  }

  // Untuk Merchant: Konfirmasi pembayaran transaksi online
  Future<void> konfirmasiPembayaranOnline(int transaksiId) async {
    try {
      await _dio.put('/transaksi/$transaksiId/konfirmasi-online');
    } catch (e) {
      throw Exception('Error konfirmasi pembayaran: $e');
    }
  }

  // Untuk Merchant: Batalkan transaksi online
  Future<void> batalkanTransaksiOnline(int transaksiId) async {
    try {
      await _dio.put('/transaksi/$transaksiId/batalkan-online');
    } catch (e) {
      throw Exception('Error batalkan transaksi: $e');
    }
  }
}
