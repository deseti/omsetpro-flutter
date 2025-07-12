import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../models/pelanggan_model.dart';
import '../../../providers/providers.dart';

class PilihPelangganDialog extends ConsumerStatefulWidget {
  const PilihPelangganDialog({Key? key}) : super(key: key);

  @override
  _PilihPelangganDialogState createState() => _PilihPelangganDialogState();
}

class _PilihPelangganDialogState extends ConsumerState<PilihPelangganDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Pelanggan> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPelanggan(_searchController.text);
    });
  }

  Future<void> _searchPelanggan(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/pelanggan/search', queryParameters: {'q': query});
      final List<dynamic> data = response.data;
      setState(() {
        _searchResults = data.map((json) => Pelanggan.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  void _showTambahPelangganDialog() {
    final namaController = TextEditingController();
    final noHpController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Pelanggan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama')),
            TextField(controller: noHpController, decoration: const InputDecoration(labelText: 'No. HP'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                final response = await dio.post('/pelanggan', data: {
                  'nama': namaController.text,
                  'noHp': noHpController.text,
                });
                final newPelanggan = Pelanggan.fromJson(response.data);
                ref.read(selectedPelangganProvider.notifier).state = newPelanggan;
                Navigator.of(dialogContext).pop(); // Tutup dialog tambah
                Navigator.of(context).pop(); // Tutup dialog utama
              } catch (e) {
                // Handle error
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cari atau Tambah Pelanggan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari berdasarkan Nama atau No. HP',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(_searchController.text.isEmpty
                              ? 'Mulai ketik untuk mencari...'
                              : 'Pelanggan tidak ditemukan.'),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final pelanggan = _searchResults[index];
                            return ListTile(
                              title: Text(pelanggan.nama),
                              subtitle: Text(pelanggan.noHp),
                              onTap: () {
                                ref.read(selectedPelangganProvider.notifier).state = pelanggan;
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showTambahPelangganDialog,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Pelanggan Baru'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
