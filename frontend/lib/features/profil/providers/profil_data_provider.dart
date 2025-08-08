import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/profil_data_model.dart';
import '../../../providers/providers.dart';

// Provider untuk data profil
final profilDataProvider = FutureProvider.autoDispose<ProfilData>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    print('🔍 Fetching profil data...');
    final response = await dio.get('/auth/profile');
    print('✅ Response received: ${response.data}');
    final profilData = ProfilData.fromJson(response.data['user']);
    return profilData;
  } on DioException catch (e) {
    print('❌ DioException: ${e.message}, Status: ${e.response?.statusCode}');
    rethrow;
  } catch (e) {
    print('❌ General error: $e');
    rethrow;
  }
});
