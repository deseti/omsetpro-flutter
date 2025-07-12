import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart'; // Import provider utama untuk dio

// Enum untuk tipe promo, harus sama dengan di backend
enum PromoTipe { PERCENTAGE, NOMINAL }

// Model untuk Produk Sederhana (untuk pilihan)
class SimpleProduk {
  final int id;
  final String nama;
  final int cabangId; // Tambahkan ini untuk referensi
  final String cabangNama;

  SimpleProduk({
    required this.id,
    required this.nama,
    required this.cabangId,
    required this.cabangNama,
  });
}

// Model untuk Promo
class Promo {
  final int id;
  final String nama;
  final String? deskripsi;
  final PromoTipe tipe;
  final double nilai;
  final bool isActive;
  final List<SimpleProduk> produk;

  Promo({
    required this.id,
    required this.nama,
    this.deskripsi,
    required this.tipe,
    required this.nilai,
    required this.isActive,
    required this.produk,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    var produkList = (json['produk'] as List)
        .map((item) => SimpleProduk(
              id: item['produk']['id'],
              nama: item['produk']['nama'],
              cabangId: item['produk']['cabangId'],
              cabangNama: '', // Nama cabang tidak dikirim dari API ini
            ))
        .toList();

    return Promo(
      id: json['id'],
      nama: json['nama'],
      deskripsi: json['deskripsi'],
      tipe: PromoTipe.values.byName(json['tipe']),
      nilai: (json['nilai'] as num).toDouble(),
      isActive: json['isActive'],
      produk: produkList,
    );
  }
}

// Provider untuk mengambil daftar semua promo
final promoListProvider = FutureProvider.autoDispose<List<Promo>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/promo');
  final List<dynamic> data = response.data;
  return data.map((json) => Promo.fromJson(json)).toList();
});

// [BARU & DIPERBAIKI] Provider untuk mengambil SEMUA produk dari SEMUA cabang milik Owner
final allOwnerProductsProvider = FutureProvider.autoDispose<List<SimpleProduk>>((ref) async {
  final dio = ref.watch(dioProvider);
  
  // 1. Ambil semua cabang milik owner
  final cabangResponse = await dio.get('/cabang');
  final List<dynamic> cabangList = cabangResponse.data;

  List<SimpleProduk> allProduk = [];

  // 2. Untuk setiap cabang, ambil produknya
  for (var cabang in cabangList) {
    try {
      final produkResponse = await dio.get('/produk', queryParameters: {'cabangId': cabang['id']});
      final List<dynamic> produkList = produkResponse.data;
      for (var produk in produkList) {
        allProduk.add(SimpleProduk(
          id: produk['id'],
          nama: produk['nama'],
          cabangId: cabang['id'],
          cabangNama: cabang['nama'],
        ));
      }
    } catch (e) {
      // Abaikan jika gagal mengambil produk dari satu cabang, lanjutkan ke cabang lain
      print('Gagal mengambil produk dari cabang ${cabang['id']}: $e');
    }
  }

  return allProduk;
});