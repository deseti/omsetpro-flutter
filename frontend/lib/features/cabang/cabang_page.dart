import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../providers/providers.dart';
import '../../utils/role_guard.dart';
import '../../models/user_model.dart';
import '../produk/produk_page.dart'; // Import halaman produk

class CabangPage extends ConsumerStatefulWidget {
  const CabangPage({Key? key}) : super(key: key);

  @override
  _CabangPageState createState() => _CabangPageState();
}

class _CabangPageState extends ConsumerState<CabangPage> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCabang();
    });
  }

  Future<void> _fetchCabang() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/cabang');
      if (mounted) {
        ref.read(cabangListProvider.notifier).state = response.data;
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.response?.data['message'] ?? 'Gagal memuat data cabang';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEditCabangDialog(Map<String, dynamic> cabang) {
    final namaController = TextEditingController(text: cabang['nama']);
    final alamatController = TextEditingController(text: cabang['alamat']);
    final industriController = TextEditingController(text: cabang['industri'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Cabang'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Cabang')),
              TextField(controller: alamatController, decoration: const InputDecoration(labelText: 'Alamat')),
              TextField(controller: industriController, decoration: const InputDecoration(labelText: 'Industri (Opsional)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.patch('/cabang/${cabang['id']}', data: {
                    'nama': namaController.text,
                    'alamat': alamatController.text,
                    'industri': industriController.text.isEmpty ? null : industriController.text,
                  });
                  Navigator.of(context).pop();
                  _fetchCabang();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal mengupdate cabang'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int cabangId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Cabang'),
          content: const Text('Apakah Anda yakin ingin menghapus cabang ini? Tindakan ini tidak bisa dibatalkan.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.delete('/cabang/$cabangId');
                  Navigator.of(context).pop();
                  _fetchCabang();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus cabang'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCabangDialog() {
    final namaController = TextEditingController();
    final alamatController = TextEditingController();
    final industriController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Cabang Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Cabang')),
              TextField(controller: alamatController, decoration: const InputDecoration(labelText: 'Alamat')),
              TextField(controller: industriController, decoration: const InputDecoration(labelText: 'Industri (Opsional)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (namaController.text.isEmpty || alamatController.text.isEmpty) return;
                
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/cabang', data: {
                    'nama': namaController.text,
                    'alamat': alamatController.text,
                    'industri': industriController.text.isEmpty ? null : industriController.text,
                  });
                  Navigator.of(context).pop();
                  _fetchCabang();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menambah cabang'), backgroundColor: Colors.red),
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
  Widget build(BuildContext context) {
    // === PROTEKSI ROLE: HANYA OWNER YANG BISA AKSES ===
    return RoleGuard.protect(
      allowedRoles: [Role.OWNER],
      ref: ref,
      child: _buildCabangPage(context),
    );
  }

  Widget _buildCabangPage(BuildContext context) {
    final cabangList = ref.watch(cabangListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Cabang'),
        // --- TAMBAHKAN TOMBOL INI ---
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Navigator.of(context).pushNamed('/import-produk');
            },
            tooltip: 'Import Produk Massal',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchCabang,
                  child: cabangList.isEmpty
                      ? const Center(child: Text('Anda belum memiliki cabang. Silakan tambahkan.'))
                      : ListView.builder(
                          itemCount: cabangList.length,
                          itemBuilder: (context, index) {
                            final cabang = cabangList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: const Icon(Icons.store_mall_directory, color: Colors.indigo),
                                title: Text(cabang['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cabang['alamat']),
                                    if (cabang['industri'] != null && cabang['industri'].toString().isNotEmpty)
                                      Text('Industri: ${cabang['industri']}', 
                                           style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showEditCabangDialog(cabang),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _showDeleteConfirmationDialog(cabang['id']),
                                      tooltip: 'Hapus',
                                    ),
                                  ],
                                ),
                                // --- BUAT LISTTILE BISA DIKLIK ---
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ProdukPage(
                                        cabangId: cabang['id'],
                                        cabangNama: cabang['nama'],
                                      ),
                                    ),
                                  );
                                  // Setelah kembali dari ProdukPage, refresh produk di kasir
                                  ref.invalidate(produkListFutureProvider(cabang['id']));
                                },
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCabangDialog,
        child: const Icon(Icons.add),
        tooltip: 'Tambah Cabang',
      ),
    );
  }
}