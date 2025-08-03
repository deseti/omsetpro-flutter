import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../providers/providers.dart';

class HomeDataService {
  static Future<void> fetchInitialData(WidgetRef ref, bool mounted) async {
    if (ref.read(userProfileProvider) != null) return;
    
    try {
      final dio = ref.read(dioProvider);
      await Future.wait([
        dio.get('/auth/profile').then((response) {
          if (mounted) {
            ref.read(userProfileProvider.notifier).state =
                response.data['user'];
          }
        }),
        dio.get('/cabang').then((response) {
          if (mounted) {
            ref.read(cabangListProvider.notifier).state = response.data;
          }
        }),
      ]);
    } catch (e) {
      print('Gagal memuat data awal: $e');
    }
  }
}
