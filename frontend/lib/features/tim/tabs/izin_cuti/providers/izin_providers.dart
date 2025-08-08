import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../providers/providers.dart';

// Provider untuk izin tim
final izinTimListProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/izin');
  return response.data;
});

final izinTimByUserProvider =
    FutureProvider.autoDispose.family<List<dynamic>, int>((ref, userId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/izin/user/$userId');
  return response.data;
});
