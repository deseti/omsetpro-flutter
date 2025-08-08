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
    List<SimpleProduk> produkList = (json['produk'] as List)
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
final allOwnerProductsProvider =
    FutureProvider.autoDispose<List<SimpleProduk>>((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    print('🔍 Mulai mengambil data cabang...');

    // 1. Ambil semua cabang milik owner
    final cabangResponse = await dio.get('/cabang');
    final List<dynamic> cabangList = cabangResponse.data;

    print('📋 Ditemukan ${cabangList.length} cabang');

    List<SimpleProduk> allProduk = [];

    // 2. Untuk setiap cabang, ambil produknya
    for (var cabang in cabangList) {
      try {
        print(
            '🏪 Mengambil produk dari cabang: ${cabang['nama']} (ID: ${cabang['id']})');

        final produkResponse = await dio
            .get('/produk', queryParameters: {'cabangId': cabang['id']});
        final List<dynamic> produkList = produkResponse.data;

        print(
            '📦 Ditemukan ${produkList.length} produk di cabang ${cabang['nama']}');

        for (var produk in produkList) {
          allProduk.add(SimpleProduk(
            id: produk['id'],
            nama: produk['nama'],
            cabangId: cabang['id'],
            cabangNama: cabang['nama'],
          ));
        }
      } catch (e) {
        print('❌ Gagal mengambil produk dari cabang ${cabang['id']}: $e');
        // Lanjutkan ke cabang berikutnya
      }
    }

    print('✅ Total produk ditemukan: ${allProduk.length}');
    return allProduk;
  } catch (e) {
    print('❌ Error di allOwnerProductsProvider: $e');
    rethrow;
  }
});

// [ALTERNATIF ROBUST] Provider untuk mengambil semua produk milik owner
final directProdukListProvider =
    FutureProvider.autoDispose<List<SimpleProduk>>((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    print('🔍 [Direct] Mengambil semua produk milik owner...');

    // Coba gunakan endpoint baru terlebih dahulu
    try {
      final produkResponse = await dio.get('/produk/all-owner-products');
      print('✅ [Direct] Response produk: ${produkResponse.statusCode}');

      if (produkResponse.data == null) {
        print('❌ [Direct] Data produk null');
        return <SimpleProduk>[];
      }

      final List<dynamic> produkList = produkResponse.data as List<dynamic>;
      print('📦 [Direct] Jumlah produk: ${produkList.length}');

      final result = produkList.map((produk) {
        return SimpleProduk(
          id: produk['id'] as int,
          nama: produk['nama'] as String,
          cabangId: produk['cabang']['id'] as int,
          cabangNama: produk['cabang']['nama'] as String,
        );
      }).toList();

      print('✅ [Direct] Berhasil mapping ${result.length} produk');
      return result;
    } catch (e) {
      print('⚠️ [Direct] Endpoint baru gagal, fallback ke metode lama: $e');

      // Fallback: gunakan metode lama
      final cabangResponse = await dio.get('/cabang');
      final List<dynamic> cabangList = cabangResponse.data;

      print('📋 [Fallback] Ditemukan ${cabangList.length} cabang');

      if (cabangList.isEmpty) {
        print('⚠️ [Fallback] Tidak ada cabang');
        return <SimpleProduk>[];
      }

      List<SimpleProduk> allProduk = [];

      // Ambil produk dari setiap cabang
      for (var cabang in cabangList) {
        try {
          print(
              '🏪 [Fallback] Mengambil produk dari cabang: ${cabang['nama']} (ID: ${cabang['id']})');

          final produkResponse = await dio
              .get('/produk', queryParameters: {'cabangId': cabang['id']});
          final List<dynamic> produkList = produkResponse.data;

          print(
              '📦 [Fallback] Ditemukan ${produkList.length} produk di cabang ${cabang['nama']}');

          for (var produk in produkList) {
            allProduk.add(SimpleProduk(
              id: produk['id'],
              nama: produk['nama'],
              cabangId: cabang['id'],
              cabangNama: cabang['nama'],
            ));
          }
        } catch (e) {
          print(
              '❌ [Fallback] Gagal mengambil produk dari cabang ${cabang['id']}: $e');
          // Lanjutkan ke cabang berikutnya
        }
      }

      print('✅ [Fallback] Total produk ditemukan: ${allProduk.length}');
      return allProduk;
    }
  } catch (e, stackTrace) {
    print('❌ [Direct] Error fatal: $e');
    print('📍 [Direct] StackTrace: $stackTrace');
    throw Exception('Gagal mengambil data produk: $e');
  }
});

// [PROVIDER SIMPLE UNTUK DEBUG] Provider sederhana untuk debug
final simpleProdukProvider =
    FutureProvider.autoDispose<List<SimpleProduk>>((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    print('🔍 [Simple] Mencoba endpoint sederhana...');

    // Ambil data cabang terlebih dahulu
    final cabangResponse = await dio.get('/cabang');
    final List<dynamic> cabangData = cabangResponse.data;

    if (cabangData.isEmpty) {
      print('⚠️ [Simple] Tidak ada cabang ditemukan');
      return <SimpleProduk>[];
    }

    print('📋 [Simple] Ditemukan ${cabangData.length} cabang');

    // Ambil produk dari cabang pertama saja untuk test
    final firstCabang = cabangData.first;
    final cabangId = firstCabang['id'];
    final cabangNama = firstCabang['nama'];

    print('🏪 [Simple] Mengambil produk dari cabang: $cabangNama');

    final produkResponse =
        await dio.get('/produk', queryParameters: {'cabangId': cabangId});
    final List<dynamic> produkData = produkResponse.data;

    print('📦 [Simple] Ditemukan ${produkData.length} produk');

    final result = produkData
        .map((produk) => SimpleProduk(
              id: produk['id'],
              nama: produk['nama'],
              cabangId: cabangId,
              cabangNama: cabangNama,
            ))
        .toList();

    print('✅ [Simple] Berhasil mapping ${result.length} produk');
    return result;
  } catch (e, stackTrace) {
    print('❌ [Simple] Error: $e');
    print('📍 [Simple] StackTrace: $stackTrace');
    throw Exception('Error mengambil produk: $e');
  }
});
