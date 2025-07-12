class Pelanggan {
  final int id;
  final String nama;
  final String noHp;
  final String? email;
  final String? alamat;
  final int totalPoin;

  Pelanggan({
    required this.id,
    required this.nama,
    required this.noHp,
    this.email,
    this.alamat,
    required this.totalPoin,
  });

  factory Pelanggan.fromJson(Map<String, dynamic> json) {
    return Pelanggan(
      id: json['id'],
      nama: json['nama'],
      noHp: json['noHp'],
      email: json['email'],
      alamat: json['alamat'],
      totalPoin: json['totalPoin'] ?? 0,
    );
  }
}