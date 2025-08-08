class TokoOnlineSettings {
  final String? tokoOnlineSlug;
  final bool isTokoOnlineActive;
  final bool allowPickup;
  final bool allowDelivery;

  TokoOnlineSettings({
    this.tokoOnlineSlug,
    required this.isTokoOnlineActive,
    required this.allowPickup,
    required this.allowDelivery,
  });

  factory TokoOnlineSettings.fromJson(Map<String, dynamic> json) {
    return TokoOnlineSettings(
      tokoOnlineSlug: json['tokoOnlineSlug'],
      isTokoOnlineActive: json['isTokoOnlineActive'] ?? false,
      allowPickup: json['allowPickup'] ?? true,
      allowDelivery: json['allowDelivery'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tokoOnlineSlug': tokoOnlineSlug,
      'isTokoOnlineActive': isTokoOnlineActive,
      'allowPickup': allowPickup,
      'allowDelivery': allowDelivery,
    };
  }

  TokoOnlineSettings copyWith({
    String? tokoOnlineSlug,
    bool? isTokoOnlineActive,
    bool? allowPickup,
    bool? allowDelivery,
  }) {
    return TokoOnlineSettings(
      tokoOnlineSlug: tokoOnlineSlug ?? this.tokoOnlineSlug,
      isTokoOnlineActive: isTokoOnlineActive ?? this.isTokoOnlineActive,
      allowPickup: allowPickup ?? this.allowPickup,
      allowDelivery: allowDelivery ?? this.allowDelivery,
    );
  }
}

class RekeningBank {
  final int? id;
  final String namaBank;
  final String nomorRekening;
  final String namaPemilik;
  final DateTime? createdAt;

  RekeningBank({
    this.id,
    required this.namaBank,
    required this.nomorRekening,
    required this.namaPemilik,
    this.createdAt,
  });

  factory RekeningBank.fromJson(Map<String, dynamic> json) {
    return RekeningBank(
      id: json['id'],
      namaBank: json['namaBank'] ?? '',
      nomorRekening: json['nomorRekening'] ?? '',
      namaPemilik: json['namaPemilik'] ?? '',
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'namaBank': namaBank,
      'nomorRekening': nomorRekening,
      'namaPemilik': namaPemilik,
    };
  }
}

class TokoOnlineData {
  final int id;
  final String nama;
  final String? logoUrl;
  final String alamat;
  final String telepon;
  final String email;
  final bool allowPickup;
  final bool allowDelivery;
  final List<Produk> produk;
  final List<RekeningBank> rekeningBank;

  TokoOnlineData({
    required this.id,
    required this.nama,
    this.logoUrl,
    required this.alamat,
    required this.telepon,
    required this.email,
    required this.allowPickup,
    required this.allowDelivery,
    required this.produk,
    required this.rekeningBank,
  });

  factory TokoOnlineData.fromJson(Map<String, dynamic> json) {
    return TokoOnlineData(
      id: json['id'],
      nama: json['nama'] ?? '',
      logoUrl: json['logoUrl'],
      alamat: json['alamat'] ?? '',
      telepon: json['telepon'] ?? '',
      email: json['email'] ?? '',
      allowPickup: json['allowPickup'] ?? true,
      allowDelivery: json['allowDelivery'] ?? false,
      produk: (json['produk'] as List<dynamic>? ?? [])
          .map((e) => Produk.fromJson(e))
          .toList(),
      rekeningBank: (json['rekeningBank'] as List<dynamic>? ?? [])
          .map((e) => RekeningBank.fromJson(e))
          .toList(),
    );
  }
}

class Produk {
  final int id;
  final String nama;
  final int harga;
  final int stok;
  final String? fotoUrl;
  final int cabangId;
  final String cabangNama;

  Produk({
    required this.id,
    required this.nama,
    required this.harga,
    required this.stok,
    this.fotoUrl,
    required this.cabangId,
    required this.cabangNama,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      id: json['id'],
      nama: json['nama'] ?? '',
      harga: json['harga'] ?? 0,
      stok: json['stok'] ?? 0,
      fotoUrl: json['fotoUrl'],
      cabangId: json['cabangId'] ?? 0,
      cabangNama: json['cabangNama'] ?? '',
    );
  }
}

class CartItem {
  final Produk produk;
  int jumlah;

  CartItem({
    required this.produk,
    required this.jumlah,
  });

  int get subtotal => produk.harga * jumlah;
}

class OrderRequest {
  final List<OrderItem> items;
  final String namaPelanggan;
  final String noHpPelanggan;
  final String tipePengiriman; // 'Diambil' atau 'Diantar'

  OrderRequest({
    required this.items,
    required this.namaPelanggan,
    required this.noHpPelanggan,
    required this.tipePengiriman,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'namaPelanggan': namaPelanggan,
      'noHpPelanggan': noHpPelanggan,
      'tipePengiriman': tipePengiriman,
    };
  }
}

class OrderItem {
  final int produkId;
  final int jumlah;

  OrderItem({
    required this.produkId,
    required this.jumlah,
  });

  Map<String, dynamic> toJson() {
    return {
      'produkId': produkId,
      'jumlah': jumlah,
    };
  }
}
