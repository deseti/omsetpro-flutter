enum Role {
  OWNER,
  ADMIN,
  KASIR,
}

// Model untuk akses cabang
class AksesCabang {
  final int userId;
  final int cabangId;
  final String namaCabang;

  AksesCabang({
    required this.userId,
    required this.cabangId,
    required this.namaCabang,
  });

  factory AksesCabang.fromJson(Map<String, dynamic> json) {
    return AksesCabang(
      userId: json['userId'],
      cabangId: json['cabangId'],
      namaCabang: json['cabang']?['nama'] ?? 'Nama Cabang Tidak Ditemukan',
    );
  }
}

// Model untuk User
class User {
  final int id;
  final String email;
  final String namaLengkap;
  final Role role;
  final List<AksesCabang> aksesCabang;

  User({
    required this.id,
    required this.email,
    required this.namaLengkap,
    required this.role,
    required this.aksesCabang,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    var aksesList = json['aksesCabang'] as List;
    List<AksesCabang> aksesCabangList = aksesList.map((i) => AksesCabang.fromJson(i)).toList();

    return User(
      id: json['id'],
      email: json['email'],
      namaLengkap: json['namaLengkap'],
      role: Role.values.byName(json['role']),
      aksesCabang: aksesCabangList,
    );
  }
}