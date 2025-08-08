import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/riwayat_transaksi_model.dart';
import '../providers/providers.dart';

final riwayatTransaksiServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return RiwayatTransaksiService(dio);
});

class RiwayatTransaksiService {
  final Dio _dio;

  RiwayatTransaksiService(this._dio);

  Future<RiwayatTransaksiResponse> getRiwayatTransaksi({
    int? cabangId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };

      if (cabangId != null) {
        queryParams['cabangId'] = cabangId;
      }

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      // Add timestamp to prevent caching
      queryParams['_t'] = DateTime.now().millisecondsSinceEpoch.toString();

      print('🔍 Fetching riwayat transaksi with params: $queryParams');

      final response = await _dio.get(
        '/transaksi/riwayat',
        queryParameters: queryParams,
      );

      print('✅ Riwayat transaksi response: ${response.statusCode}');
      print('📊 Data count: ${response.data['data']?.length ?? 0}');

      return RiwayatTransaksiResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ DioException in getRiwayatTransaksi: ${e.message}');
      print('Response data: ${e.response?.data}');
      throw Exception(_handleError(e));
    } catch (e) {
      print('❌ Error in getRiwayatTransaksi: $e');
      throw Exception('Terjadi kesalahan saat mengambil riwayat transaksi');
    }
  }

  String _handleError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return e.response?.data['message'] ?? 'Permintaan tidak valid';
      case 401:
        return 'Sesi telah berakhir, silakan login kembali';
      case 403:
        return 'Anda tidak memiliki akses untuk melihat data ini';
      case 404:
        return 'Data tidak ditemukan';
      case 500:
        return 'Terjadi kesalahan pada server';
      default:
        return 'Terjadi kesalahan jaringan';
    }
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  // Update informasi pengiriman
  Future<void> updateShippingInfo({
    required int transaksiId,
    String? nomorResi,
    String? namaKurir,
  }) async {
    try {
      print('📦 Updating shipping info for transaction: $transaksiId');
      print('🚚 Resi: $nomorResi, Kurir: $namaKurir');

      final response = await _dio.put(
        '/transaksi/$transaksiId/update-shipping',
        data: {
          'nomorResi': nomorResi,
          'namaKurir': namaKurir,
        },
      );

      print('✅ Shipping info updated: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException in updateShippingInfo: ${e.message}');
      print('Response data: ${e.response?.data}');
      throw Exception(_handleError(e));
    } catch (e) {
      print('❌ Error in updateShippingInfo: $e');
      throw Exception('Terjadi kesalahan saat mengupdate informasi pengiriman');
    }
  }
}
