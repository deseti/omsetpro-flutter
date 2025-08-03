import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../providers/providers.dart';
import '../../produk/produk_page.dart';
import '../../kasir/kasir_page.dart';

class HomeDialogs {
  static void showPilihCabangDialog(
    BuildContext context,
    WidgetRef ref, {
    String mode = 'produk',
  }) {
    final profile = ref.read(userProfileProvider);
    final userRole =
        profile != null ? Role.values.byName(profile['role']) : null;
    final cabangList = ref.read(cabangListProvider);

    // DEBUG: Print data user profile
    print('[_showPilihCabangDialog] User profile: $profile');
    print('[_showPilihCabangDialog] User role: $userRole');
    print('[_showPilihCabangDialog] Cabang list: $cabangList');
    print('[_showPilihCabangDialog] Mode: $mode');

    // Filter cabang berdasarkan role
    List<dynamic> cabangTersedia = [];
    if (userRole == Role.OWNER) {
      // Owner bisa akses semua cabang miliknya
      cabangTersedia = cabangList;
      print(
          '[_showPilihCabangDialog] Owner - semua cabang tersedia: ${cabangTersedia.length}');
    } else if ((userRole == Role.ADMIN || userRole == Role.KASIR) &&
        profile != null) {
      // Admin dan Kasir hanya bisa akses cabang yang di-assign
      final userAkses = profile['aksesCabang'] as List? ?? [];
      print('[_showPilihCabangDialog] Admin/Kasir - akses cabang: $userAkses');
      final cabangIdsYangBisaDiakses =
          userAkses.map((akses) => akses['cabangId']).toSet();
      print(
          '[_showPilihCabangDialog] Admin/Kasir - cabang IDs yang bisa diakses: $cabangIdsYangBisaDiakses');
      cabangTersedia = cabangList
          .where((cabang) => cabangIdsYangBisaDiakses.contains(cabang['id']))
          .toList();
    }

    if (cabangTersedia.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tidak Ada Akses'),
          content: Text(mode == 'kasir'
              ? 'Anda tidak memiliki akses ke cabang manapun untuk menggunakan kasir.'
              : 'Anda tidak memiliki akses ke cabang manapun untuk mengelola produk.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Cabang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: cabangTersedia.map<Widget>((cabang) {
            return ListTile(
              leading: const Icon(Icons.store_mall_directory),
              title: Text(cabang['nama']),
              subtitle: Text(cabang['alamat']),
              onTap: () {
                Navigator.of(context).pop();
                if (mode == 'kasir') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => KasirPage(
                        cabangId: cabang['id'],
                        cabangNama: cabang['nama'],
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProdukPage(
                        cabangId: cabang['id'],
                        cabangNama: cabang['nama'],
                      ),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}
