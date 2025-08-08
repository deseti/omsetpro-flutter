// Model untuk data toko
class DataToko {
  final String nama;
  final String? logoUrl;
  final String alamat;
  final String telepon;
  final String email;
  final String kategoriBisnis;

  DataToko({
    required this.nama,
    this.logoUrl,
    required this.alamat,
    required this.telepon,
    required this.email,
    required this.kategoriBisnis,
  });

  factory DataToko.fromJson(Map<String, dynamic> json) {
    return DataToko(
      nama: json['nama'] ?? '',
      logoUrl: json['logoUrl'],
      alamat: json['alamat'] ?? '',
      telepon: json['telepon'] ?? '',
      email: json['email'] ?? '',
      kategoriBisnis: json['kategoriBisnis'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'logoUrl': logoUrl,
      'alamat': alamat,
      'telepon': telepon,
      'email': email,
      'kategoriBisnis': kategoriBisnis,
    };
  }
}

// Daftar kategori bisnis
const List<String> kategoriBisnisList = [
  'Makanan & Minuman',
  'Fashion & Pakaian',
  'Elektronik',
  'Kecantikan & Kesehatan',
  'Rumah Tangga',
  'Otomotif',
  'Olahraga & Outdoor',
  'Buku & Alat Tulis',
  'Mainan & Hobi',
  'Jasa & Layanan',
  'Lainnya',
];
