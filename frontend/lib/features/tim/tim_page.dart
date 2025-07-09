import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';

class TimPage extends ConsumerWidget {
  const TimPage({Key? key}) : super(key: key);

  void _showUndangUserDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final namaController = TextEditingController();
    final passwordController = TextEditingController();
    Role selectedRole = Role.KASIR;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Undang Pengguna Baru'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
                    TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password Sementara'), obscureText: true),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Role>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Peran (Role)'),
                      items: const [
                        DropdownMenuItem(value: Role.ADMIN, child: Text('Admin')),
                        DropdownMenuItem(value: Role.KASIR, child: Text('Kasir')),
                      ],
                      onChanged: (Role? newValue) {
                        setState(() {
                          selectedRole = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/tim/undang', data: {
                    'email': emailController.text,
                    'namaLengkap': namaController.text,
                    'password': passwordController.text,
                    'role': selectedRole.name,
                  });
                  Navigator.of(context).pop();
                  ref.invalidate(timListFutureProvider); // Refresh daftar tim
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pengguna baru berhasil diundang!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal mengundang pengguna'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Undang'),
            ),
          ],
        );
      },
    );
  }

  void _showKelolaAksesDialog(BuildContext context, WidgetRef ref, User user) {
    final semuaCabang = ref.read(cabangListProvider);
    // Buat daftar cabang yang sudah diakses oleh user ini
    final Set<int> cabangYangSudahDiakses = user.aksesCabang.map((akses) => akses.cabangId).toSet();
    
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Kelola Akses untuk ${user.namaLengkap}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: semuaCabang.length,
                itemBuilder: (context, index) {
                  final cabang = semuaCabang[index];
                  return CheckboxListTile(
                    title: Text(cabang['nama']),
                    value: cabangYangSudahDiakses.contains(cabang['id']),
                    onChanged: (bool? value) async {
                      try {
                        final dio = ref.read(dioProvider);
                        if (value == true) {
                          // Tambah akses
                          await dio.post('/tim/tugaskan-akses', data: {
                            'userId': user.id,
                            'cabangId': cabang['id'],
                          });
                        } else {
                          // Hapus akses
                          await dio.delete('/tim/hapus-akses', data: {
                            'userId': user.id,
                            'cabangId': cabang['id'],
                          });
                        }
                        // Tutup dialog dan refresh daftar tim
                        Navigator.of(context).pop();
                        ref.invalidate(timListFutureProvider);
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gagal mengubah akses'), backgroundColor: Colors.red),
                        );
                      }
                    },
                  );
                },
              ),
            ),
             actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timAsyncValue = ref.watch(timListFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Tim'),
      ),
      body: timAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (timList) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(timListFutureProvider),
            child: ListView.builder(
              itemCount: timList.length,
              itemBuilder: (context, index) {
                final user = timList[index];
                // Buat teks untuk daftar cabang yang diakses
                final aksesCabangText = user.aksesCabang.isEmpty
                    ? 'Belum ada akses cabang'
                    : user.aksesCabang.map((akses) => akses.namaCabang).join(', ');

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(user.namaLengkap[0])),
                    title: Text('${user.namaLengkap} (${user.role.name})'),
                    subtitle: Text('Akses: $aksesCabangText'),
                    trailing: IconButton(
                      icon: const Icon(Icons.key),
                      onPressed: () => _showKelolaAksesDialog(context, ref, user),
                      tooltip: 'Kelola Akses Cabang',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUndangUserDialog(context, ref),
        child: const Icon(Icons.add),
        tooltip: 'Undang Pengguna',
      ),
    );
  }
}