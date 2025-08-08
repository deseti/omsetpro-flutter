import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/izin_models.dart';
import '../providers/izin_providers.dart';
import '../../../../../providers/providers.dart';

class PengajuanIzinDialog {
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final timList = ref.read(timListFutureProvider).value ?? [];

    if (timList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada anggota tim tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final alasanController = TextEditingController();
    int selectedUserId = timList.first.id;
    JenisIzin jenisIzin = JenisIzin.IZIN;
    DateTime tanggalMulai = DateTime.now();
    DateTime tanggalSelesai = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengajuan Izin/Cuti'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedUserId,
                  decoration:
                      const InputDecoration(labelText: 'Pilih Anggota Tim'),
                  items: timList.map<DropdownMenuItem<int>>((user) {
                    return DropdownMenuItem(
                      value: user.id,
                      child: Text('${user.namaLengkap} (${user.role.name})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedUserId = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<JenisIzin>(
                  value: jenisIzin,
                  decoration: const InputDecoration(labelText: 'Jenis Izin'),
                  items: JenisIzin.values.map((jenis) {
                    return DropdownMenuItem(
                      value: jenis,
                      child: Text(IzinUtils.getJenisIzinText(jenis)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      jenisIzin = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal Mulai'),
                  subtitle: Text(IzinUtils.formatDate(tanggalMulai)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: tanggalMulai,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        tanggalMulai = date;
                        if (tanggalSelesai.isBefore(tanggalMulai)) {
                          tanggalSelesai = tanggalMulai;
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal Selesai'),
                  subtitle: Text(IzinUtils.formatDate(tanggalSelesai)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: tanggalSelesai,
                      firstDate: tanggalMulai,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        tanggalSelesai = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: alasanController,
                  decoration: const InputDecoration(
                    labelText: 'Alasan',
                    hintText: 'Jelaskan alasan izin/cuti...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (alasanController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan harus diisi'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final dio = ref.read(dioProvider);
                final data = {
                  'userId': selectedUserId,
                  'jenis': jenisIzin.name,
                  'tanggalMulai': tanggalMulai.toIso8601String(),
                  'tanggalSelesai': tanggalSelesai.toIso8601String(),
                  'alasan': alasanController.text.trim(),
                };

                await dio.post('/izin', data: data);

                Navigator.of(context).pop();
                ref.invalidate(izinTimListProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pengajuan izin berhasil dibuat!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal membuat pengajuan: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ajukan'),
          ),
        ],
      ),
    );
  }
}
