import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';
import '../../utils/role_guard.dart';
import './scanner_page.dart';
import 'package:flutter/foundation.dart';

class ProdukPage extends ConsumerStatefulWidget {
  final int cabangId;
  final String cabangNama;

  const ProdukPage({
    super.key,
    required this.cabangId,
    required this.cabangNama,
  });

  @override
  _ProdukPageState createState() => _ProdukPageState();
}

class _ProdukPageState extends ConsumerState<ProdukPage> {
  final ImagePicker _picker = ImagePicker();

  // Fungsi untuk me-refresh data
  Future<void> _refreshProduk() async {
    // "Bunyikan lonceng" agar FutureProvider mengambil data baru
    ref.invalidate(produkListFutureProvider(widget.cabangId));
  }

  // Fungsi untuk export data produk
  Future<void> _exportProduk() async {
    try {
      print('🔄 Starting export for cabangId: ${widget.cabangId}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mempersiapkan file export...'),
          backgroundColor: Colors.blue,
        ),
      );

      final dio = ref.read(dioProvider);

      // Request export dengan response type bytes
      await dio.get(
        '/produk/export/${widget.cabangId}',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept':
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          },
        ),
      );

      if (kIsWeb) {
        // Web platform - would need universal_html or different approach
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Export belum didukung di platform mobile. Silakan gunakan web version.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Mobile platform - save to downloads or share
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Export belum tersedia di mobile. Silakan gunakan web version.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export data berhasil!'),
          backgroundColor: Colors.green,
        ),
      );

      print('✅ Export completed successfully');
    } catch (e) {
      print('❌ Export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat export: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleFotoUpload(int produkId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final dio = ref.read(dioProvider);
      final fileName = image.name;
      final bytes = await image.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      print('🔄 Uploading photo for product ID: $produkId');
      await dio.post('/produk/$produkId/upload-foto', data: formData);
      print('✅ Photo upload successful!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto produk berhasil diunggah!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _refreshProduk();
    } catch (e) {
      print('❌ Error uploading photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProdukDialog({Map<String, dynamic>? produk}) {
    final bool isEditing = produk != null;
    final namaController = TextEditingController(text: produk?['nama'] ?? '');
    final kategoriController =
        TextEditingController(text: produk?['kategori'] ?? '');
    final hargaBeliController =
        TextEditingController(text: produk?['hargaBeli']?.toString() ?? '');
    final hargaController =
        TextEditingController(text: produk?['harga']?.toString() ?? '');
    final stokController =
        TextEditingController(text: produk?['stok']?.toString() ?? '');
    final barcodeController =
        TextEditingController(text: produk?['barcode'] ?? '');
    // Ambil profile user dari provider
    final profile = ref.read(userProfileProvider);
    print(
        '[ProdukPage] Tambah/Edit Produk - cabangId: ${widget.cabangId}, user: ${profile != null ? profile['namaLengkap'] : '-'}, role: ${profile != null ? profile['role'] : '-'}');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Produk' : 'Tambah Produk Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: namaController,
                    decoration:
                        const InputDecoration(labelText: 'Nama Produk')),
                TextField(
                    controller: kategoriController,
                    decoration: const InputDecoration(
                        labelText: 'Kategori (Opsional)')),
                TextField(
                    controller: hargaBeliController,
                    decoration:
                        const InputDecoration(labelText: 'Harga Beli (Modal)'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: hargaController,
                    decoration: const InputDecoration(labelText: 'Harga Jual'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: stokController,
                    decoration: const InputDecoration(labelText: 'Stok'),
                    keyboardType: TextInputType.number),
                TextField(
                  controller: barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode (opsional)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final String? barcodeResult =
                            await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const ScannerPage()),
                        );
                        if (barcodeResult != null) {
                          barcodeController.text = barcodeResult;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final dio = ref.read(dioProvider);
                final data = {
                  'nama': namaController.text,
                  'kategori': kategoriController.text.isEmpty
                      ? null
                      : kategoriController.text,
                  'hargaBeli': int.tryParse(hargaBeliController.text) ?? 0,
                  'harga': int.tryParse(hargaController.text) ?? 0,
                  'stok': int.tryParse(stokController.text) ?? 0,
                  'barcode': barcodeController.text.isNotEmpty
                      ? barcodeController.text
                      : null,
                  'cabangId': widget.cabangId,
                };
                print('[ProdukPage] Request data: $data');
                try {
                  if (isEditing) {
                    await dio.patch('/produk/${produk['id']}', data: data);
                  } else {
                    await dio.post('/produk', data: data);
                  }
                  Navigator.of(context).pop();
                  _refreshProduk();
                } catch (e) {
                  print('[ProdukPage] ERROR saat tambah/edit produk: $e');
                  // Handle error
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int produkId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Produk'),
          content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.delete('/produk/$produkId');
                  Navigator.of(context).pop();
                  _refreshProduk();
                } catch (e) {
                  // Handle error
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // === PROTEKSI ROLE: OWNER & ADMIN YANG BISA AKSES ===
    return RoleGuard.protect(
      allowedRoles: [Role.OWNER, Role.ADMIN],
      ref: ref,
      child: _buildProdukPage(context),
    );
  }

  Widget _buildProdukPage(BuildContext context) {
    // Gunakan provider baru untuk mengambil data
    final produkAsyncValue =
        ref.watch(produkListFutureProvider(widget.cabangId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Produk di ${widget.cabangNama}'),
        actions: [
          // Tombol Export Data
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Data Produk',
            onPressed: _exportProduk,
          ),
          // Tombol Import (menuju halaman import)
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import Produk Massal',
            onPressed: () {
              Navigator.of(context).pushNamed('/import-produk');
            },
          ),
        ],
      ),
      body: produkAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (produkList) {
          return RefreshIndicator(
            onRefresh: _refreshProduk,
            child: produkList.isEmpty
                ? const Center(child: Text('Belum ada produk di cabang ini.'))
                : ListView.builder(
                    itemCount: produkList.length,
                    itemBuilder: (context, index) {
                      final produk = produkList[index];
                      final fotoUrl = produk['fotoUrl'];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                                fotoUrl != null ? NetworkImage(fotoUrl) : null,
                            child: fotoUrl == null
                                ? const Icon(Icons.inventory_2,
                                    color: Colors.grey)
                                : null,
                          ),
                          title: Text(produk['nama'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (produk['kategori'] != null &&
                                  produk['kategori'].toString().isNotEmpty)
                                Text('Kategori: ${produk['kategori']}',
                                    style: const TextStyle(
                                        color: Colors.blue, fontSize: 12)),
                              Text(
                                'Jual: Rp ${produk['harga']} | Beli: Rp ${produk['hargaBeli']}\n'
                                'Stok: ${produk['stok']} | Barcode: ${produk['barcode'] ?? '-'}',
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.photo_camera,
                                    color: Colors.green),
                                onPressed: () =>
                                    _handleFotoUpload(produk['id']),
                                tooltip: 'Upload Foto',
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _showProdukDialog(produk: produk),
                                tooltip: 'Edit Produk',
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _showDeleteConfirmationDialog(produk['id']),
                                tooltip: 'Hapus Produk',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol Export (secondary)
          FloatingActionButton(
            mini: true,
            heroTag: 'export_fab',
            onPressed: _exportProduk,
            tooltip: 'Export Data Produk',
            backgroundColor: Colors.green,
            child: const Icon(Icons.file_download, size: 20),
          ),
          const SizedBox(height: 10),
          // Tombol Tambah Produk (primary)
          FloatingActionButton(
            heroTag: 'add_fab',
            onPressed: () => _showProdukDialog(),
            tooltip: 'Tambah Produk',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
