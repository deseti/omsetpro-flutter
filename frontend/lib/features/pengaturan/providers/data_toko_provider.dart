import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/data_toko_model.dart';
import '../../../providers/providers.dart';

// Provider untuk data toko
final dataTokoProvider = FutureProvider.autoDispose<DataToko>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    print('🔍 Fetching akun toko data...');
    final response = await dio.get('/pengaturan/akun-toko');
    print('✅ Response received: ${response.data}');
    final dataToko = DataToko.fromJson(response.data);
    print('📋 Parsed data toko - logoUrl: ${dataToko.logoUrl}');
    return dataToko;
  } on DioException catch (e) {
    print('❌ DioException: ${e.message}, Status: ${e.response?.statusCode}');
    if (e.response?.statusCode == 404) {
      // Jika belum ada data, return data kosong
      print('📝 Returning empty data for 404');
      return DataToko(
        nama: '',
        alamat: '',
        telepon: '',
        email: '',
        kategoriBisnis: '',
      );
    }
    rethrow;
  } catch (e) {
    print('❌ General error: $e');
    rethrow;
  }
});
