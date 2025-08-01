import 'package:flutter/material.dart';

class RiwayatTransaksi {
  final int id;
  final int total;
  final int potongan;
  final String metodeBayar;
  final DateTime createdAt;
  final List<DetailTransaksi> detail;
  final KasirInfo kasir;
  final CabangInfo cabang;
  final PelangganInfo? pelanggan;

  RiwayatTransaksi({
    required this.id,
    required this.total,
    required this.potongan,
    required this.metodeBayar,
    required this.createdAt,
    required this.detail,
    required this.kasir,
    required this.cabang,
    this.pelanggan,
  });

  factory RiwayatTransaksi.fromJson(Map<String, dynamic> json) {
    return RiwayatTransaksi(
      id: json['id'] as int,
      total: json['total'] as int,
      potongan: json['potongan'] as int? ?? 0,
      metodeBayar: json['metodeBayar'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      detail: (json['detail'] as List)
          .map((item) => DetailTransaksi.fromJson(item))
          .toList(),
      kasir: KasirInfo.fromJson(json['kasir']),
      cabang: CabangInfo.fromJson(json['cabang']),
      pelanggan: json['pelanggan'] != null 
          ? PelangganInfo.fromJson(json['pelanggan'])
          : null,
    );
  }

  int get totalSebelumDiskon => total + potongan;
  int get totalItem => detail.fold(0, (sum, item) => sum + item.jumlah);
}

class DetailTransaksi {
  final int jumlah;
  final int hargaSaatItu;
  final int potonganItem;
  final ProdukInfo produk;

  DetailTransaksi({
    required this.jumlah,
    required this.hargaSaatItu,
    required this.potonganItem,
    required this.produk,
  });

  factory DetailTransaksi.fromJson(Map<String, dynamic> json) {
    return DetailTransaksi(
      jumlah: json['jumlah'] as int,
      hargaSaatItu: json['hargaSaatItu'] as int,
      potonganItem: json['potonganItem'] as int? ?? 0,
      produk: ProdukInfo.fromJson(json['produk']),
    );
  }

  int get subtotal => hargaSaatItu * jumlah;
  int get subtotalSetelahDiskon => subtotal - potonganItem;
}

class KasirInfo {
  final int id;
  final String namaLengkap;

  KasirInfo({
    required this.id,
    required this.namaLengkap,
  });

  factory KasirInfo.fromJson(Map<String, dynamic> json) {
    return KasirInfo(
      id: json['id'] as int,
      namaLengkap: json['namaLengkap'] as String,
    );
  }
}

class CabangInfo {
  final int id;
  final String nama;

  CabangInfo({
    required this.id,
    required this.nama,
  });

  factory CabangInfo.fromJson(Map<String, dynamic> json) {
    return CabangInfo(
      id: json['id'] as int,
      nama: json['nama'] as String,
    );
  }
}

class ProdukInfo {
  final int id;
  final String nama;
  final String? fotoUrl;

  ProdukInfo({
    required this.id,
    required this.nama,
    this.fotoUrl,
  });

  factory ProdukInfo.fromJson(Map<String, dynamic> json) {
    return ProdukInfo(
      id: json['id'] as int,
      nama: json['nama'] as String,
      fotoUrl: json['fotoUrl'] as String?,
    );
  }
}

class PelangganInfo {
  final int id;
  final String nama;
  final String? noHp;

  PelangganInfo({
    required this.id,
    required this.nama,
    this.noHp,
  });

  factory PelangganInfo.fromJson(Map<String, dynamic> json) {
    return PelangganInfo(
      id: json['id'] as int,
      nama: json['nama'] as String,
      noHp: json['noHp'] as String?,
    );
  }
}

class RiwayatTransaksiResponse {
  final List<RiwayatTransaksi> data;
  final PaginationInfo pagination;

  RiwayatTransaksiResponse({
    required this.data,
    required this.pagination,
  });

  factory RiwayatTransaksiResponse.fromJson(Map<String, dynamic> json) {
    return RiwayatTransaksiResponse(
      data: (json['data'] as List)
          .map((item) => RiwayatTransaksi.fromJson(item))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
    );
  }
}

class PaginationInfo {
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  PaginationInfo({
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
      hasMore: json['hasMore'] as bool,
    );
  }
}

enum FilterPeriode {
  hariIni('Hari Ini'),
  satuBulan('1 Bulan Terakhir'),
  satuTahun('1 Tahun Terakhir');

  const FilterPeriode(this.label);
  final String label;

  DateRange get dateRange {
    final now = DateTime.now();
    switch (this) {
      case FilterPeriode.hariIni:
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateRange(start: startOfDay, end: endOfDay);
      
      case FilterPeriode.satuBulan:
        final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
        return DateRange(start: oneMonthAgo, end: now);
      
      case FilterPeriode.satuTahun:
        final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
        return DateRange(start: oneYearAgo, end: now);
    }
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}
