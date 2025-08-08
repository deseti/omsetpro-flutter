import 'package:flutter/material.dart';
import '../models/profil_data_model.dart';

class PersonalInfoSection extends StatelessWidget {
  final ProfilData profilData;
  final TextEditingController namaController;
  final bool isEditingNama;
  final bool isLoading;
  final VoidCallback onEditPressed;
  final VoidCallback onCancelPressed;
  final VoidCallback onSavePressed;

  const PersonalInfoSection({
    super.key,
    required this.profilData,
    required this.namaController,
    required this.isEditingNama,
    required this.isLoading,
    required this.onEditPressed,
    required this.onCancelPressed,
    required this.onSavePressed,
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
              'Informasi Personal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Nama Lengkap
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: namaController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    enabled: isEditingNama,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama lengkap tidak boleh kosong';
                      }
                      if (value.trim().length < 2) {
                        return 'Nama lengkap minimal 2 karakter';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (!isEditingNama)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEditPressed,
                    tooltip: 'Edit Nama',
                  ),
              ],
            ),

            if (isEditingNama) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancelPressed,
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSavePressed,
                      child: isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Email (Read-only)
            TextFormField(
              initialValue: profilData.email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.lock, color: Colors.grey),
              ),
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}
