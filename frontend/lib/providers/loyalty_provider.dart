import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'providers.dart'; // Import provider utama untuk dio

// Model untuk Aturan Loyalitas
class LoyaltyRule {
  final int kelipatanRp;
  final int dapatPoin;

  LoyaltyRule({required this.kelipatanRp, required this.dapatPoin});

  factory LoyaltyRule.fromJson(Map<String, dynamic> json) {
    return LoyaltyRule(
      kelipatanRp: json['kelipatanRp'],
      dapatPoin: json['dapatPoin'],
    );
  }
}

// Model untuk Hadiah
class Reward {
  final int id;
  final String namaHadiah;
  final int poinDibutuhkan;
  final String? deskripsi;
  final bool isActive;

  Reward({
    required this.id,
    required this.namaHadiah,
    required this.poinDibutuhkan,
    this.deskripsi,
    required this.isActive,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      namaHadiah: json['namaHadiah'],
      poinDibutuhkan: json['poinDibutuhkan'],
      deskripsi: json['deskripsi'],
      isActive: json['isActive'],
    );
  }
}

// Provider untuk mengambil aturan loyalitas saat ini
final loyaltyRuleProvider = FutureProvider.autoDispose<LoyaltyRule?>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/loyalty/rules');
    if (response.data != null) {
      return LoyaltyRule.fromJson(response.data);
    }
    return null;
  } catch (e) {
    // Jika tidak ada aturan, kembalikan null (bukan error)
    if (e is DioException && e.response?.statusCode == 404) {
      return null;
    }
    rethrow;
  }
});

// Provider untuk mengambil daftar hadiah
final rewardsProvider = FutureProvider.autoDispose<List<Reward>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/loyalty/rewards');
  final List<dynamic> data = response.data;
  return data.map((json) => Reward.fromJson(json)).toList();
});