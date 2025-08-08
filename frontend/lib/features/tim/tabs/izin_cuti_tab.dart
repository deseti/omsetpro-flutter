import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../providers/providers.dart';

// Provider untuk izin tim
final izinTimListProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/izin');
  return response.data;
});

final izinTimByUserProvider =
    FutureProvider.autoDispose.family<List<dynamic>, int>((ref, userId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/izin/user/$userId');
  return response.data;
});

enum JenisIzin { IZIN, SAKIT, CUTI }

enum StatusIzin { PENDING, APPROVED, REJECTED }

class IzinCutiTab extends ConsumerStatefulWidget {
  const IzinCutiTab({super.key});

  @override
  ConsumerState<IzinCutiTab> createState() => _IzinCutiTabState();
}

class _IzinCutiTabState extends ConsumerState<IzinCutiTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFilterIndex =
      0; // 0: Semua, 1: Pending, 2: Approved, 3: Rejected

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showPengajuanIzinDialog() async {
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
                      child: Text(_getJenisIzinText(jenis)),
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
                  subtitle: Text(_formatDate(tanggalMulai)),
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
                  subtitle: Text(_formatDate(tanggalSelesai)),
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

  Future<void> _showApprovalDialog(Map<String, dynamic> izin) async {
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
                        'Jenis: ${_getJenisIzinText(JenisIzin.values.byName(izin['jenis']))}'),
                    const SizedBox(height: 4),
                    Text(
                        'Periode: ${_formatDate(DateTime.parse(izin['tanggalMulai']))} - ${_formatDate(DateTime.parse(izin['tanggalSelesai']))}'),
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

  String _getJenisIzinText(JenisIzin jenis) {
    switch (jenis) {
      case JenisIzin.IZIN:
        return 'Izin';
      case JenisIzin.SAKIT:
        return 'Sakit';
      case JenisIzin.CUTI:
        return 'Cuti';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Icon _getJenisIzinIcon(String jenis) {
    switch (jenis) {
      case 'IZIN':
        return const Icon(Icons.person_off, color: Colors.blue);
      case 'SAKIT':
        return const Icon(Icons.local_hospital, color: Colors.red);
      case 'CUTI':
        return const Icon(Icons.beach_access, color: Colors.green);
      default:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }

  List<dynamic> _filterIzin(List<dynamic> izinList) {
    switch (_selectedFilterIndex) {
      case 1:
        return izinList.where((izin) => izin['status'] == 'PENDING').toList();
      case 2:
        return izinList.where((izin) => izin['status'] == 'APPROVED').toList();
      case 3:
        return izinList.where((izin) => izin['status'] == 'REJECTED').toList();
      default:
        return izinList;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Daftar Izin'),
            Tab(icon: Icon(Icons.assessment), text: 'Statistik'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDaftarIzinTab(),
              _buildStatistikTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaftarIzinTab() {
    final izinList = ref.watch(izinTimListProvider);

    return izinList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (izinList) {
        final filteredList = _filterIzin(izinList);

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
                                leading: _getJenisIzinIcon(jenis),
                                title: Text(
                                    '${user['namaLengkap']} - ${_getJenisIzinText(JenisIzin.values.byName(jenis))}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${_formatDate(tanggalMulai)} - ${_formatDate(tanggalSelesai)} ($durasi hari)'),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: _getStatusColor(status),
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
                                        Text(
                                          'Alasan:',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(izin['alasan']),
                                        const SizedBox(height: 8),
                                        if (izin['catatan'] != null) ...[
                                          Text(
                                            'Catatan:',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(izin['catatan']),
                                          const SizedBox(height: 8),
                                        ],
                                        Text(
                                          'Diajukan: ${_formatDate(DateTime.parse(izin['createdAt']))}',
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
                                                    _showApprovalDialog(izin),
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
            onPressed: _showPengajuanIzinDialog,
            tooltip: 'Tambah Pengajuan Izin',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildStatistikTab() {
    final izinList = ref.watch(izinTimListProvider);

    return izinList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (izinList) {
        final stats = _calculateStatistics(izinList);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(izinTimListProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard('Total Izin',
                          stats['total'].toString(), Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildStatCard('Pending',
                          stats['pending'].toString(), Colors.orange)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard('Disetujui',
                          stats['approved'].toString(), Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildStatCard(
                          'Ditolak', stats['rejected'].toString(), Colors.red)),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Statistik per Jenis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Jenis izin statistics
              ...JenisIzin.values.map((jenis) {
                final jenisStats =
                    stats['byJenis'][jenis.name] ?? {'total': 0, 'approved': 0};
                return Card(
                  child: ListTile(
                    leading: _getJenisIzinIcon(jenis.name),
                    title: Text(_getJenisIzinText(jenis)),
                    subtitle: Text('${jenisStats['total']} pengajuan'),
                    trailing: Text(
                      '${jenisStats['approved']} disetujui',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                );
              }),

              if (stats['byUser'].isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Statistik per Anggota Tim',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // User statistics
                ...(stats['byUser'] as Map<String, dynamic>)
                    .entries
                    .map((entry) {
                  final userStats = entry.value;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(entry.key[0]),
                      ),
                      title: Text(entry.key),
                      subtitle: Text('${userStats['total']} pengajuan total'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${userStats['approved']} disetujui',
                            style: const TextStyle(
                                color: Colors.green, fontSize: 12),
                          ),
                          Text(
                            '${userStats['pending']} pending',
                            style: const TextStyle(
                                color: Colors.orange, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

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

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateStatistics(List<dynamic> izinList) {
    final byJenis = <String, Map<String, int>>{};
    final byUser = <String, Map<String, int>>{};

    final stats = {
      'total': izinList.length,
      'pending': izinList.where((i) => i['status'] == 'PENDING').length,
      'approved': izinList.where((i) => i['status'] == 'APPROVED').length,
      'rejected': izinList.where((i) => i['status'] == 'REJECTED').length,
      'byJenis': byJenis,
      'byUser': byUser,
    };

    // Statistics by jenis
    for (final jenis in JenisIzin.values) {
      final jenisIzin =
          izinList.where((i) => i['jenis'] == jenis.name).toList();
      byJenis[jenis.name] = {
        'total': jenisIzin.length,
        'approved': jenisIzin.where((i) => i['status'] == 'APPROVED').length,
      };
    }

    // Statistics by user
    for (final izin in izinList) {
      final userName = izin['user']['namaLengkap'];
      if (!byUser.containsKey(userName)) {
        byUser[userName] = {
          'total': 0,
          'pending': 0,
          'approved': 0,
          'rejected': 0,
        };
      }
      byUser[userName]!['total'] = (byUser[userName]!['total'] ?? 0) + 1;
      final status = izin['status'].toLowerCase();
      byUser[userName]![status] = (byUser[userName]![status] ?? 0) + 1;
    }

    return stats;
  }
}
