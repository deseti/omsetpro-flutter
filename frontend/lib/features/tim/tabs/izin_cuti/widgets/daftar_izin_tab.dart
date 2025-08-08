import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/izin_models.dart';
import '../providers/izin_providers.dart';
import '../services/izin_service.dart';
import '../widgets/pengajuan_izin_dialog.dart';
import '../widgets/approval_dialog.dart';
import '../../../../../providers/providers.dart';

class DaftarIzinTab extends ConsumerStatefulWidget {
  const DaftarIzinTab({super.key});

  @override
  ConsumerState<DaftarIzinTab> createState() => _DaftarIzinTabState();
}

class _DaftarIzinTabState extends ConsumerState<DaftarIzinTab> {
  int _selectedFilterIndex = 0;

  Widget _buildFilterChip(String label, int index, int count) {
    final isSelected = _selectedFilterIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final izinList = ref.watch(izinTimListProvider);

    return izinList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (izinList) {
        final filteredList =
            IzinService.filterIzin(izinList, _selectedFilterIndex);

        return Scaffold(
          body: Column(
            children: [
              // Filter chips
              Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', 0, izinList.length),
                      _buildFilterChip(
                          'Pending',
                          1,
                          izinList
                              .where((i) => i['status'] == 'PENDING')
                              .length),
                      _buildFilterChip(
                          'Disetujui',
                          2,
                          izinList
                              .where((i) => i['status'] == 'APPROVED')
                              .length),
                      _buildFilterChip(
                          'Ditolak',
                          3,
                          izinList
                              .where((i) => i['status'] == 'REJECTED')
                              .length),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: filteredList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy,
                                size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Belum ada pengajuan izin/cuti'),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(izinTimListProvider),
                        child: ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final izin = filteredList[index];
                            final user = izin['user'];
                            final status = izin['status'];
                            final jenis = izin['jenis'];
                            final tanggalMulai =
                                DateTime.parse(izin['tanggalMulai']);
                            final tanggalSelesai =
                                DateTime.parse(izin['tanggalSelesai']);
                            final durasi =
                                tanggalSelesai.difference(tanggalMulai).inDays +
                                    1;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: ExpansionTile(
                                leading: IzinService.getJenisIzinIcon(jenis),
                                title: Text(
                                    '${user['namaLengkap']} - ${IzinUtils.getJenisIzinText(JenisIzin.values.byName(jenis))}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${IzinUtils.formatDate(tanggalMulai)} - ${IzinUtils.formatDate(tanggalSelesai)} ($durasi hari)'),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            IzinService.getStatusColor(status)
                                                .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: IzinService.getStatusColor(
                                              status),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Alasan:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(izin['alasan']),
                                        const SizedBox(height: 8),
                                        if (izin['catatan'] != null) ...[
                                          const Text(
                                            'Catatan:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(izin['catatan']),
                                          const SizedBox(height: 8),
                                        ],
                                        Text(
                                          'Diajukan: ${IzinUtils.formatDate(DateTime.parse(izin['createdAt']))}',
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
                                        if (status == 'PENDING') ...[
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () =>
                                                    ApprovalDialog.show(
                                                        context, ref, izin),
                                                icon: const Icon(Icons.check),
                                                label: const Text('Proses'),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue),
                                              ),
                                              ElevatedButton.icon(
                                                onPressed: () async {
                                                  final confirm =
                                                      await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title: const Text(
                                                          'Konfirmasi'),
                                                      content: Text(
                                                          'Hapus pengajuan izin ${user['namaLengkap']}?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(false),
                                                          child: const Text(
                                                              'Batal'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(true),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red),
                                                          child: const Text(
                                                              'Hapus'),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirm == true) {
                                                    try {
                                                      final dio =
                                                          ref.read(dioProvider);
                                                      await dio.delete(
                                                          '/izin/${izin['id']}');
                                                      ref.invalidate(
                                                          izinTimListProvider);
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Pengajuan izin berhasil dihapus'),
                                                          backgroundColor:
                                                              Colors.green,
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Gagal menghapus: ${e.toString()}'),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                icon: const Icon(Icons.delete),
                                                label: const Text('Hapus'),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => PengajuanIzinDialog.show(context, ref),
            tooltip: 'Tambah Pengajuan Izin',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
