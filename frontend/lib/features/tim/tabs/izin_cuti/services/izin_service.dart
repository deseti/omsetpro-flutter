import 'package:flutter/material.dart';
import '../models/izin_models.dart';

class IzinService {
  static Color getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static Icon getJenisIzinIcon(String jenis) {
    switch (jenis) {
      case 'IZIN':
        return const Icon(Icons.person_off, color: Colors.blue);
      case 'SAKIT':
        return const Icon(Icons.local_hospital, color: Colors.red);
      case 'CUTI':
        return const Icon(Icons.beach_access, color: Colors.green);
      default:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }

  static List<dynamic> filterIzin(List<dynamic> izinList, int filterIndex) {
    switch (filterIndex) {
      case 1:
        return izinList.where((izin) => izin['status'] == 'PENDING').toList();
      case 2:
        return izinList.where((izin) => izin['status'] == 'APPROVED').toList();
      case 3:
        return izinList.where((izin) => izin['status'] == 'REJECTED').toList();
      default:
        return izinList;
    }
  }

  static Map<String, dynamic> calculateStatistics(List<dynamic> izinList) {
    final byJenis = <String, Map<String, int>>{};
    final byUser = <String, Map<String, int>>{};

    final stats = {
      'total': izinList.length,
      'pending': izinList.where((i) => i['status'] == 'PENDING').length,
      'approved': izinList.where((i) => i['status'] == 'APPROVED').length,
      'rejected': izinList.where((i) => i['status'] == 'REJECTED').length,
      'byJenis': byJenis,
      'byUser': byUser,
    };

    // Statistics by jenis
    for (final jenis in JenisIzin.values) {
      final jenisIzin =
          izinList.where((i) => i['jenis'] == jenis.name).toList();
      byJenis[jenis.name] = {
        'total': jenisIzin.length,
        'approved': jenisIzin.where((i) => i['status'] == 'APPROVED').length,
      };
    }

    // Statistics by user
    for (final izin in izinList) {
      final userName = izin['user']['namaLengkap'];
      if (!byUser.containsKey(userName)) {
        byUser[userName] = {
          'total': 0,
          'pending': 0,
          'approved': 0,
          'rejected': 0,
        };
      }
      byUser[userName]!['total'] = (byUser[userName]!['total'] ?? 0) + 1;
      final status = izin['status'].toLowerCase();
      byUser[userName]![status] = (byUser[userName]![status] ?? 0) + 1;
    }

    return stats;
  }
}
