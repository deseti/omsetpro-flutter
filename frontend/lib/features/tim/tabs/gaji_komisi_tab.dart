import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../providers/providers.dart';

// Provider untuk gaji tim
final gajiTimListProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/gaji/tim');
  return response.data;
});

final laporanGajiProvider = FutureProvider.autoDispose
    .family<List<dynamic>, Map<String, dynamic>>((ref, params) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/gaji/laporan', queryParameters: params);
  return response.data;
});

class GajiKomisiTab extends ConsumerStatefulWidget {
  const GajiKomisiTab({super.key});

  @override
  ConsumerState<GajiKomisiTab> createState() => _GajiKomisiTabState();
}

class _GajiKomisiTabState extends ConsumerState<GajiKomisiTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int selectedBulan = DateTime.now().month;
  int selectedTahun = DateTime.now().year;

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

  Future<void> _showPengaturanGajiDialog(
      [Map<String, dynamic>? existingGaji]) async {
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

    final gajiPokokController = TextEditingController(
      text: existingGaji?['gajiPokok']?.toString() ?? '',
    );
    final komisiPersenController = TextEditingController(
      text: existingGaji?['komisiPersen']?.toString() ?? '',
    );
    final komisiNominalController = TextEditingController(
      text: existingGaji?['komisiNominal']?.toString() ?? '',
    );
    final tunjanganController = TextEditingController(
      text: existingGaji?['tunjangan']?.toString() ?? '',
    );

    int selectedUserId = existingGaji?['user']['id'] ?? timList.first.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingGaji != null
            ? 'Edit Pengaturan Gaji'
            : 'Pengaturan Gaji Baru'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (existingGaji == null)
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
                if (existingGaji != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Anggota: ${existingGaji['user']['namaLengkap']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: gajiPokokController,
                  decoration: const InputDecoration(
                    labelText: 'Gaji Pokok (Rp)',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: komisiPersenController,
                  decoration: const InputDecoration(
                    labelText: 'Komisi Persen (%)',
                    suffixText: '%',
                    helperText:
                        'Komisi berdasarkan persentase dari total penjualan',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: komisiNominalController,
                  decoration: const InputDecoration(
                    labelText: 'Komisi per Transaksi (Rp)',
                    prefixText: 'Rp ',
                    helperText: 'Komisi tetap per transaksi yang berhasil',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tunjanganController,
                  decoration: const InputDecoration(
                    labelText: 'Tunjangan (Rp)',
                    prefixText: 'Rp ',
                    helperText: 'Tunjangan tetap bulanan',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              try {
                final dio = ref.read(dioProvider);
                final data = {
                  if (existingGaji == null) 'userId': selectedUserId,
                  'gajiPokok': int.tryParse(gajiPokokController.text) ?? 0,
                  'komisiPersen':
                      double.tryParse(komisiPersenController.text) ?? 0.0,
                  'komisiNominal':
                      int.tryParse(komisiNominalController.text) ?? 0,
                  'tunjangan': int.tryParse(tunjanganController.text) ?? 0,
                };

                if (existingGaji != null) {
                  await dio.put('/gaji/${existingGaji['user']['id']}',
                      data: data);
                } else {
                  await dio.post('/gaji', data: data);
                }

                Navigator.of(context).pop();
                ref.invalidate(gajiTimListProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(existingGaji != null
                        ? 'Pengaturan gaji berhasil diupdate!'
                        : 'Pengaturan gaji berhasil dibuat!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menyimpan: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(existingGaji != null ? 'Update' : 'Buat'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Pengaturan'),
            Tab(icon: Icon(Icons.assessment), text: 'Laporan'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPengaturanTab(),
              _buildLaporanTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPengaturanTab() {
    final gajiList = ref.watch(gajiTimListProvider);

    return gajiList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (gajiList) {
        return Scaffold(
          body: gajiList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_money, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada pengaturan gaji'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(gajiTimListProvider),
                  child: ListView.builder(
                    itemCount: gajiList.length,
                    itemBuilder: (context, index) {
                      final gaji = gajiList[index];
                      final user = gaji['user'];
                      final totalGaji = (gaji['gajiPokok'] as int) +
                          (gaji['tunjangan'] as int);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(user['namaLengkap'][0]),
                          ),
                          title:
                              Text('${user['namaLengkap']} (${user['role']})'),
                          subtitle: Text(
                              'Total Gaji Dasar: ${_formatCurrency(totalGaji)}'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('Gaji Pokok',
                                      _formatCurrency(gaji['gajiPokok'])),
                                  _buildDetailRow('Komisi Persen',
                                      '${gaji['komisiPersen']}%'),
                                  _buildDetailRow('Komisi per Transaksi',
                                      _formatCurrency(gaji['komisiNominal'])),
                                  _buildDetailRow('Tunjangan',
                                      _formatCurrency(gaji['tunjangan'])),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _showPengaturanGajiDialog(gaji),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit'),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Konfirmasi'),
                                              content: Text(
                                                  'Hapus pengaturan gaji untuk ${user['namaLengkap']}?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: const Text('Batal'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red),
                                                  child: const Text('Hapus'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            try {
                                              final dio = ref.read(dioProvider);
                                              await dio.delete(
                                                  '/gaji/${user['id']}');
                                              ref.invalidate(
                                                  gajiTimListProvider);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Pengaturan gaji berhasil dihapus'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Gagal menghapus: ${e.toString()}'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Hapus'),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showPengaturanGajiDialog(),
            tooltip: 'Tambah Pengaturan Gaji',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildLaporanTab() {
    final laporanParams = {
      'bulan': selectedBulan,
      'tahun': selectedTahun,
    };

    final laporanGaji = ref.watch(laporanGajiProvider(laporanParams));

    return Column(
      children: [
        // Header filter periode
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.date_range, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Periode: '),
              DropdownButton<int>(
                value: selectedBulan,
                items: List.generate(12, (index) {
                  final month = index + 1;
                  const monthNames = [
                    'Januari',
                    'Februari',
                    'Maret',
                    'April',
                    'Mei',
                    'Juni',
                    'Juli',
                    'Agustus',
                    'September',
                    'Oktober',
                    'November',
                    'Desember'
                  ];
                  return DropdownMenuItem(
                    value: month,
                    child: Text(monthNames[index]),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    selectedBulan = value!;
                  });
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: selectedTahun,
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - 2 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    selectedTahun = value!;
                  });
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: laporanGaji.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (laporan) {
              if (laporan.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assessment, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Tidak ada data laporan gaji untuk periode ini'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(laporanGajiProvider(laporanParams)),
                child: ListView.builder(
                  itemCount: laporan.length,
                  itemBuilder: (context, index) {
                    final data = laporan[index];
                    final user = data['user'];
                    final performa = data['performa'];
                    final absensi = data['absensi'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(user['namaLengkap'][0]),
                        ),
                        title: Text('${user['namaLengkap']} (${user['role']})'),
                        subtitle: Text(
                            'Total Gaji: ${_formatCurrency(data['totalGaji'])}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Gaji Dasar',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow('Gaji Pokok',
                                    _formatCurrency(data['gajiPokok'])),
                                _buildDetailRow('Tunjangan',
                                    _formatCurrency(data['tunjangan'])),
                                const Divider(height: 24),
                                const Text(
                                  'Performa & Komisi',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow('Total Transaksi',
                                    '${performa['totalTransaksi']} transaksi'),
                                _buildDetailRow(
                                    'Total Penjualan',
                                    _formatCurrency(
                                        performa['totalPenjualan'])),
                                _buildDetailRow(
                                    'Komisi (${data['komisiPersen']}%)',
                                    _formatCurrency(
                                        performa['komisiPersen'].round())),
                                _buildDetailRow('Komisi Nominal',
                                    _formatCurrency(performa['komisiNominal'])),
                                _buildDetailRow(
                                    'Total Komisi',
                                    _formatCurrency(
                                        performa['totalKomisi'].round())),
                                const Divider(height: 24),
                                const Text(
                                  'Absensi',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow(
                                    'Hadir', '${absensi['HADIR'] ?? 0} hari'),
                                _buildDetailRow(
                                    'Izin', '${absensi['IZIN'] ?? 0} hari'),
                                _buildDetailRow(
                                    'Sakit', '${absensi['SAKIT'] ?? 0} hari'),
                                _buildDetailRow(
                                    'Cuti', '${absensi['CUTI'] ?? 0} hari'),
                                const Divider(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.green[200]!),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'TOTAL GAJI',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(data['totalGaji']),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
