class RingkasanPenjualan {
  final double totalOmzet;
  final double totalLaba;
  final int totalTransaksi;
  final int totalBarangTerjual;
  final double rataRataTransaksi;
  final Periode periode;

  RingkasanPenjualan({
    required this.totalOmzet,
    required this.totalLaba,
    required this.totalTransaksi,
    required this.totalBarangTerjual,
    required this.rataRataTransaksi,
    required this.periode,
  });

  factory RingkasanPenjualan.fromJson(Map<String, dynamic> json) {
    return RingkasanPenjualan(
      totalOmzet: (json['totalOmzet'] as num).toDouble(),
      totalLaba: (json['totalLaba'] as num).toDouble(),
      totalTransaksi: json['totalTransaksi'] as int,
      totalBarangTerjual: json['totalBarangTerjual'] as int,
      rataRataTransaksi: (json['rataRataTransaksi'] as num).toDouble(),
      periode: Periode.fromJson(json['periode']),
    );
  }
}

class ProdukTerlaris {
  final int produkId;
  final String namaProduk;
  final int totalTerjual;
  final double totalOmzet;
  final double totalLaba;

  ProdukTerlaris({
    required this.produkId,
    required this.namaProduk,
    required this.totalTerjual,
    required this.totalOmzet,
    required this.totalLaba,
  });

  factory ProdukTerlaris.fromJson(Map<String, dynamic> json) {
    return ProdukTerlaris(
      produkId: json['produkId'] as int,
      namaProduk: json['namaProduk'] as String,
      totalTerjual: json['totalTerjual'] as int,
      totalOmzet: (json['totalOmzet'] as num).toDouble(),
      totalLaba: (json['totalLaba'] as num).toDouble(),
    );
  }
}

class StatistikTransaksi {
  final String tanggal;
  final int jumlahTransaksi;
  final double totalOmzet;
  final double totalLaba;

  StatistikTransaksi({
    required this.tanggal,
    required this.jumlahTransaksi,
    required this.totalOmzet,
    required this.totalLaba,
  });

  factory StatistikTransaksi.fromJson(Map<String, dynamic> json) {
    return StatistikTransaksi(
      tanggal: json['tanggal'] as String,
      jumlahTransaksi: json['jumlahTransaksi'] as int,
      totalOmzet: (json['totalOmzet'] as num).toDouble(),
      totalLaba: (json['totalLaba'] as num).toDouble(),
    );
  }

  DateTime get dateTime => DateTime.parse(tanggal);
}

class LaporanLabaRugi {
  final double totalPendapatan;
  final double totalPenjualan;
  final double totalHPP;
  final double totalLaba;
  final double margin;
  final Periode periode;

  LaporanLabaRugi({
    required this.totalPendapatan,
    required this.totalPenjualan,
    required this.totalHPP,
    required this.totalLaba,
    required this.margin,
    required this.periode,
  });

  factory LaporanLabaRugi.fromJson(Map<String, dynamic> json) {
    return LaporanLabaRugi(
      totalPendapatan: (json['totalPendapatan'] as num).toDouble(),
      totalPenjualan: (json['totalPenjualan'] as num).toDouble(),
      totalHPP: (json['totalHPP'] as num).toDouble(),
      totalLaba: (json['totalLaba'] as num).toDouble(),
      margin: (json['margin'] as num).toDouble(),
      periode: Periode.fromJson(json['periode']),
    );
  }
}

class DashboardData {
  final RingkasanPenjualan ringkasan;
  final List<ProdukTerlaris> produkTerlaris;
  final List<StatistikTransaksi> statistikTransaksi;
  final LaporanLabaRugi labaRugi;
  final DateTime generatedAt;

  DashboardData({
    required this.ringkasan,
    required this.produkTerlaris,
    required this.statistikTransaksi,
    required this.labaRugi,
    required this.generatedAt,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      ringkasan: RingkasanPenjualan.fromJson(json['ringkasan']),
      produkTerlaris: (json['produkTerlaris'] as List)
          .map((item) => ProdukTerlaris.fromJson(item))
          .toList(),
      statistikTransaksi: (json['statistikTransaksi'] as List)
          .map((item) => StatistikTransaksi.fromJson(item))
          .toList(),
      labaRugi: LaporanLabaRugi.fromJson(json['labaRugi']),
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }
}

class Periode {
  final DateTime startDate;
  final DateTime endDate;

  Periode({
    required this.startDate,
    required this.endDate,
  });

  factory Periode.fromJson(Map<String, dynamic> json) {
    return Periode(
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}
