import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import '../../providers/providers.dart';
import '../../models/user_model.dart';
import '../../utils/role_guard.dart';

class ImportProdukPage extends ConsumerStatefulWidget {
  const ImportProdukPage({super.key});

  @override
  _ImportProdukPageState createState() => _ImportProdukPageState();
}

class _ImportProdukPageState extends ConsumerState<ImportProdukPage> {
  dynamic _selectedCabang;
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedFile == null || _selectedCabang == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harap pilih cabang dan file Excel.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final dio = ref.read(dioProvider);
      final bytes = _selectedFile!.bytes;
      final fileName = _selectedFile!.name;

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes!, filename: fileName),
        'cabangId': _selectedCabang['id'],
      });

      final response = await dio.post('/produk/upload-massal', data: formData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response.data['message'] ?? 'Upload berhasil!'),
            backgroundColor: Colors.green),
      );

      // Kembali ke halaman sebelumnya setelah sukses
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Terjadi kesalahan saat upload.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $errorMessage'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // === PROTEKSI ROLE: OWNER & ADMIN YANG BISA AKSES ===
    return RoleGuard.protect(
      allowedRoles: [Role.OWNER, Role.ADMIN],
      ref: ref,
      child: _buildImportPage(context),
    );
  }

  Widget _buildImportPage(BuildContext context) {
    final cabangList = ref.watch(cabangListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Produk Massal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Dropdown untuk memilih cabang
            DropdownButtonFormField<dynamic>(
              value: _selectedCabang,
              hint: const Text('Pilih Cabang Tujuan'),
              items: cabangList.map<DropdownMenuItem<dynamic>>((cabang) {
                return DropdownMenuItem<dynamic>(
                  value: cabang,
                  child: Text(cabang['nama']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCabang = value;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // 2. Tombol untuk memilih file
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(_selectedFile?.name ?? 'Pilih File Excel (.xlsx)'),
              onPressed: _pickFile,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pastikan file Excel Anda memiliki kolom: nama, harga, stok (opsional), barcode (opsional).',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Spacer(),

            // 3. Tombol Upload
            ElevatedButton.icon(
              icon: _isUploading ? Container() : const Icon(Icons.upload_file),
              label: _isUploading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Upload Sekarang'),
              onPressed: _isUploading ? null : _handleUpload,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
