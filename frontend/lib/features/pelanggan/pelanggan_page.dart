import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../models/pelanggan_model.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';
import '../../utils/role_guard.dart';

// Provider untuk mengambil daftar pelanggan dari API
final pelangganListFutureProvider = FutureProvider.autoDispose<List<Pelanggan>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/pelanggan');
  final List<dynamic> data = response.data;
  return data.map((json) => Pelanggan.fromJson(json)).toList();
});

class PelangganPage extends ConsumerWidget {
  const PelangganPage({Key? key}) : super(key: key);

  void _showPelangganDialog(BuildContext context, WidgetRef ref) {
    final namaController = TextEditingController();
    final noHpController = TextEditingController();
    final emailController = TextEditingController();
    final alamatController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Pelanggan Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Pelanggan')),
                TextField(controller: noHpController, decoration: const InputDecoration(labelText: 'Nomor HP'), keyboardType: TextInputType.phone),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (Opsional)'), keyboardType: TextInputType.emailAddress),
                TextField(controller: alamatController, decoration: const InputDecoration(labelText: 'Alamat (Opsional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (namaController.text.isEmpty || noHpController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama dan No. HP tidak boleh kosong'), backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/pelanggan', data: {
                    'nama': namaController.text,
                    'noHp': noHpController.text,
                    'email': emailController.text.isEmpty ? null : emailController.text,
                    'alamat': alamatController.text.isEmpty ? null : alamatController.text,
                  });
                  Navigator.of(context).pop();
                  ref.invalidate(pelangganListFutureProvider); // Refresh daftar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pelanggan berhasil ditambahkan!'), backgroundColor: Colors.green),
                  );
                } on DioException catch (e) {
                  final errorMessage = e.response?.data['message'] ?? 'Gagal menambah pelanggan';
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGuard.protect(
      allowedRoles: [Role.OWNER],
      ref: ref,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Pelanggan (CRM)'),
          // [BARU] Tambahkan tombol aksi ini
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Pengaturan Loyalitas',
              onPressed: () {
                Navigator.of(context).pushNamed('/loyalty-settings');
              },
            ),
          ],
        ),
        body: Consumer(
          builder: (context, ref, _) {
            final pelangganAsync = ref.watch(pelangganListFutureProvider);
            return pelangganAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (pelangganList) {
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(pelangganListFutureProvider),
                  child: pelangganList.isEmpty
                      ? const Center(child: Text('Belum ada data pelanggan.'))
                      : ListView.builder(
                          itemCount: pelangganList.length,
                          itemBuilder: (context, index) {
                            final pelanggan = pelangganList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(pelanggan.nama.substring(0, 1)),
                                ),
                                title: Text(pelanggan.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('No HP: ${pelanggan.noHp}\nEmail: ${pelanggan.email ?? '-'}'),
                                trailing: Text(
                                  '${pelanggan.totalPoin} Poin',
                                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showPelangganDialog(context, ref),
          child: const Icon(Icons.add),
          tooltip: 'Tambah Pelanggan',
        ),
      ),
    );
  }
}