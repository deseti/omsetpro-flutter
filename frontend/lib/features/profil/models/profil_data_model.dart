import '../../../models/user_model.dart';

// Model untuk data profil user
class ProfilData {
  final String namaLengkap;
  final String email;
  final Role role;
  final List<AksesCabang> aksesCabang;

  ProfilData({
    required this.namaLengkap,
    required this.email,
    required this.role,
    required this.aksesCabang,
  });

  factory ProfilData.fromJson(Map<String, dynamic> json) {
    List<dynamic> aksesList = json['aksesCabang'] as List? ?? [];
    List<AksesCabang> aksesCabangList =
        aksesList.map((i) => AksesCabang.fromJson(i)).toList();

    return ProfilData(
      namaLengkap: json['namaLengkap'] ?? '',
      email: json['email'] ?? '',
      role: Role.values.byName(json['role']),
      aksesCabang: aksesCabangList,
    );
  }
}
