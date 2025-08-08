import 'package:flutter/material.dart';
import '../models/data_toko_model.dart';

class StoreInfoForm extends StatelessWidget {
  final TextEditingController namaController;
  final TextEditingController alamatController;
  final TextEditingController teleponController;
  final TextEditingController emailController;
  final String selectedKategori;
  final ValueChanged<String?> onKategoriChanged;

  const StoreInfoForm({
    super.key,
    required this.namaController,
    required this.alamatController,
    required this.teleponController,
    required this.emailController,
    required this.selectedKategori,
    required this.onKategoriChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Toko',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Toko *',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama toko tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: alamatController,
              decoration: const InputDecoration(
                labelText: 'Alamat Toko *',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alamat toko tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: teleponController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor telepon tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Toko *',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedKategori,
              decoration: const InputDecoration(
                labelText: 'Kategori Bisnis *',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: kategoriBisnisList.map((kategori) {
                return DropdownMenuItem(
                  value: kategori,
                  child: Text(kategori),
                );
              }).toList(),
              onChanged: onKategoriChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kategori bisnis harus dipilih';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
