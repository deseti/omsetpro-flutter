import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/izin_models.dart';
import '../providers/izin_providers.dart';
import '../../../../../providers/providers.dart';

class ApprovalDialog {
  static Future<void> show(
      BuildContext context, WidgetRef ref, Map<String, dynamic> izin) async {
    final catatanController = TextEditingController();
    bool isApproved = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Persetujuan Izin - ${izin['user']['namaLengkap']}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Jenis: ${IzinUtils.getJenisIzinText(JenisIzin.values.byName(izin['jenis']))}'),
                    const SizedBox(height: 4),
                    Text(
                        'Periode: ${IzinUtils.formatDate(DateTime.parse(izin['tanggalMulai']))} - ${IzinUtils.formatDate(DateTime.parse(izin['tanggalSelesai']))}'),
                    const SizedBox(height: 4),
                    Text('Alasan: ${izin['alasan']}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Setuju'),
                      value: true,
                      groupValue: isApproved,
                      onChanged: (value) {
                        setState(() {
                          isApproved = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Tolak'),
                      value: false,
                      groupValue: isApproved,
                      onChanged: (value) {
                        setState(() {
                          isApproved = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: catatanController,
                decoration: InputDecoration(
                  labelText:
                      isApproved ? 'Catatan (Opsional)' : 'Alasan Penolakan',
                  hintText: isApproved
                      ? 'Catatan tambahan...'
                      : 'Jelaskan alasan penolakan...',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!isApproved && catatanController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan penolakan harus diisi'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final dio = ref.read(dioProvider);
                final data = {
                  'status': isApproved ? 'APPROVED' : 'REJECTED',
                  if (catatanController.text.trim().isNotEmpty)
                    'catatan': catatanController.text.trim(),
                };

                await dio.put('/izin/${izin['id']}/approval', data: data);

                Navigator.of(context).pop();
                ref.invalidate(izinTimListProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isApproved
                        ? 'Pengajuan izin disetujui!'
                        : 'Pengajuan izin ditolak!'),
                    backgroundColor: isApproved ? Colors.green : Colors.orange,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal memproses approval: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved ? Colors.green : Colors.red,
            ),
            child: Text(isApproved ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
  }
}
