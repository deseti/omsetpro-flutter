import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import './scanner_page.dart';

class ProdukPage extends ConsumerStatefulWidget {
  final int cabangId;
  final String cabangNama;

  const ProdukPage({
    Key? key,
    required this.cabangId,
    required this.cabangNama,
  }) : super(key: key);

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
      await dio.post('/produk/$produkId/upload-foto', data: formData);
      _refreshProduk();
    } catch (e) {
      // Handle error
    }
  }

  void _showProdukDialog({Map<String, dynamic>? produk}) {
    final bool isEditing = produk != null;
    final namaController = TextEditingController(text: produk?['nama'] ?? '');
    final hargaBeliController = TextEditingController(text: produk?['hargaBeli']?.toString() ?? '');
    final hargaController = TextEditingController(text: produk?['harga']?.toString() ?? '');
    final stokController = TextEditingController(text: produk?['stok']?.toString() ?? '');
    final barcodeController = TextEditingController(text: produk?['barcode'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Produk' : 'Tambah Produk Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Produk')),
                TextField(controller: hargaBeliController, decoration: const InputDecoration(labelText: 'Harga Beli (Modal)'), keyboardType: TextInputType.number),
                TextField(controller: hargaController, decoration: const InputDecoration(labelText: 'Harga Jual'), keyboardType: TextInputType.number),
                TextField(controller: stokController, decoration: const InputDecoration(labelText: 'Stok'), keyboardType: TextInputType.number),
                TextField(
                  controller: barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode (opsional)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final String? barcodeResult = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ScannerPage()),
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
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final dio = ref.read(dioProvider);
                final data = {
                  'nama': namaController.text,
                  'hargaBeli': int.tryParse(hargaBeliController.text) ?? 0,
                  'harga': int.tryParse(hargaController.text) ?? 0,
                  'stok': int.tryParse(stokController.text) ?? 0,
                  'barcode': barcodeController.text.isNotEmpty ? barcodeController.text : null,
                  'cabangId': widget.cabangId,
                };

                try {
                  if (isEditing) {
                    await dio.patch('/produk/${produk['id']}', data: data);
                  } else {
                    await dio.post('/produk', data: data);
                  }
                  Navigator.of(context).pop();
                  _refreshProduk();
                } catch (e) {
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
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
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
    // Gunakan provider baru untuk mengambil data
    final produkAsyncValue = ref.watch(produkListFutureProvider(widget.cabangId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Produk di ${widget.cabangNama}'),
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
                      final barcode = produk['barcode'];

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                            child: fotoUrl == null ? const Icon(Icons.inventory_2, color: Colors.grey) : null,
                          ),
                          title: Text(produk['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Jual: Rp ${produk['harga']} | Beli: Rp ${produk['hargaBeli']}\n'
                            'Stok: ${produk['stok']} | Barcode: ${barcode ?? '-'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.photo_camera, color: Colors.green),
                                onPressed: () => _handleFotoUpload(produk['id']),
                                tooltip: 'Upload Foto',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showProdukDialog(produk: produk),
                                tooltip: 'Edit Produk',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmationDialog(produk['id']),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProdukDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Tambah Produk',
      ),
    );
  }
}