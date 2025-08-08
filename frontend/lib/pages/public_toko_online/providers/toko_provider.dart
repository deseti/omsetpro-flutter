import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../models/toko_online_model.dart';
import '../../../services/toko_online_service.dart';
import '../../../utils/api_config.dart';

// Provider untuk data toko berdasarkan slug
final tokoDataProvider =
    FutureProvider.family<TokoOnlineData, String>((ref, slug) async {
  // Create public Dio instance without auth
  final publicDio = Dio();
  publicDio.options.baseUrl = ApiConfig.baseUrl;
  final service = TokoOnlineService(publicDio);
  return service.getTokoBySlug(slug);
});
