import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';
import '../../utils/role_guard.dart';
import 'package:flutter/foundation.dart';

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

  void _downloadTemplate() {
    // Buat CSV template sederhana
    const csvContent = '''nama,harga,hargabeli,stok,barcode
Contoh Produk A,10000,8000,50,1234567890
Contoh Produk B,15000,12000,30,0987654321
Contoh Produk C,5000,3500,100,1122334455''';

    // Convert to bytes for download
    Uint8List.fromList(csvContent.codeUnits);

    if (kIsWeb) {
      // Web platform - would need universal_html or different approach
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Download template belum didukung di platform mobile. Silakan gunakan web version.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      // Mobile platform - save to downloads or share
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Template download belum tersedia di mobile. Silakan gunakan web version.'),
          backgroundColor: Colors.orange,
        ),
      );
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

      print('🔍 Debug: Sending upload request');
      print('📁 File name: $fileName');
      print('🏢 Cabang ID: ${_selectedCabang['id']}');
      print('📄 File size: ${bytes!.length} bytes');

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        'cabangId': _selectedCabang['id'].toString(),
      });

      final response = await dio.post('/produk/upload-massal', data: formData);

      print('✅ Upload success: ${response.data}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response.data['message'] ?? 'Upload berhasil!'),
            backgroundColor: Colors.green),
      );

      // Kembali ke halaman sebelumnya setelah sukses
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      print('❌ DioException occurred');
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('Error Message: ${e.message}');

      String errorMessage = 'Terjadi kesalahan saat upload.';

      if (e.response?.data != null) {
        try {
          if (e.response!.data is Map<String, dynamic>) {
            errorMessage = e.response!.data['message'] ?? errorMessage;
          } else if (e.response!.data is String) {
            errorMessage = e.response!.data;
          }
        } catch (parseError) {
          print('Error parsing response: $parseError');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $errorMessage'), backgroundColor: Colors.red),
      );
    } catch (e) {
      print('❌ General error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: Terjadi kesalahan yang tidak terduga'),
            backgroundColor: Colors.red),
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF23272F), // full dark
                border: Border.all(color: const Color(0xFF353A40)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Format File Excel (.xlsx):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kolom Wajib:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const Text('• nama (Nama Produk)',
                      style: TextStyle(color: Colors.white)),
                  const Text('• harga (Harga Jual)',
                      style: TextStyle(color: Colors.white)),
                  const Text('• hargaBeli atau hargabeli (Harga Beli/Modal)',
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text(
                    'Kolom Opsional:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const Text('• stok (Stok Awal, default: 0)',
                      style: TextStyle(color: Colors.white70)),
                  const Text('• barcode (Barcode Produk)',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.download,
                          size: 16, color: Color(0xFF4ADE80)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _downloadTemplate,
                        child: const Text(
                          'Download Template Excel',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
