import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../providers/providers.dart';

// Provider untuk absensi
final absensiListProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/absensi/riwayat');

    // Validate response data type
    if (response.data is List) {
      return response.data as List<dynamic>;
    }

    // Handle unexpected response type
    print(
        '⚠️ Unexpected response type from /absensi/riwayat: ${response.data.runtimeType}');
    return <dynamic>[];
  } catch (e) {
    if (e is DioException) {
      print('❌ Absensi List API Error - Status: ${e.response?.statusCode}');
      print('❌ Response Data Type: ${e.response?.data.runtimeType}');
      print('❌ Response Data: ${e.response?.data}');
    }

    print('❌ Error fetching absensi riwayat: $e');
    rethrow;
  }
});

final absensiHariIniProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, int>((ref, cabangId) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/absensi/hari-ini/$cabangId');

    // Validate response data type
    if (response.data == null) {
      return null;
    }

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    // Handle case where response.data is not the expected type
    print(
        '⚠️ Unexpected response type from /absensi/hari-ini: ${response.data.runtimeType}');
    return null;
  } catch (e) {
    if (e is DioException) {
      if (e.response?.statusCode == 404) {
        return null; // Belum absen hari ini
      }

      // Log detailed error information
      print('❌ Absensi API Error - Status: ${e.response?.statusCode}');
      print('❌ Response Data Type: ${e.response?.data.runtimeType}');
      print('❌ Response Data: ${e.response?.data}');
    }

    print('❌ Error fetching absensi hari ini: $e');
    rethrow;
  }
});

class AbsensiTab extends ConsumerStatefulWidget {
  const AbsensiTab({super.key});

  @override
  ConsumerState<AbsensiTab> createState() => _AbsensiTabState();
}

class _AbsensiTabState extends ConsumerState<AbsensiTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int selectedCabangId = 0;

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

  Future<void> _checkIn(int cabangId, String? catatan) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/absensi/check-in', data: {
        'cabangId': cabangId,
        'catatan': catatan,
      });

      ref.invalidate(absensiHariIniProvider(cabangId));
      ref.invalidate(absensiListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal check-in: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkOut(int absensiId, String? catatan) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/absensi/check-out', data: {
        'absensiId': absensiId,
        'catatan': catatan,
      });

      ref.invalidate(absensiHariIniProvider(selectedCabangId));
      ref.invalidate(absensiListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-out berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal check-out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCheckInDialog() {
    final cabangList = ref.read(cabangListProvider);
    final catatanController = TextEditingController();
    int selectedCabang = cabangList.isNotEmpty ? cabangList.first['id'] : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check-In'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCabang,
                decoration: const InputDecoration(labelText: 'Pilih Cabang'),
                items: cabangList.map<DropdownMenuItem<int>>((cabang) {
                  return DropdownMenuItem(
                    value: cabang['id'],
                    child: Text(cabang['nama']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCabang = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: catatanController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Masukkan catatan check-in',
                ),
                maxLines: 2,
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
            onPressed: () {
              Navigator.of(context).pop();
              _checkIn(
                  selectedCabang,
                  catatanController.text.isEmpty
                      ? null
                      : catatanController.text);
            },
            child: const Text('Check-In'),
          ),
        ],
      ),
    );
  }

  void _showCheckOutDialog(int absensiId) {
    final catatanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check-Out'),
        content: TextField(
          controller: catatanController,
          decoration: const InputDecoration(
            labelText: 'Catatan (opsional)',
            hintText: 'Masukkan catatan check-out',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkOut(
                  absensiId,
                  catatanController.text.isEmpty
                      ? null
                      : catatanController.text);
            },
            child: const Text('Check-Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cabangList = ref.watch(cabangListProvider);

    if (cabangList.isEmpty) {
      return const Center(
        child: Text('Tidak ada cabang tersedia untuk absensi'),
      );
    }

    if (selectedCabangId == 0) {
      selectedCabangId = cabangList.first['id'];
    }

    return Column(
      children: [
        // Header dengan pilihan cabang
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.business, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Cabang: '),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedCabangId,
                  items: cabangList.map<DropdownMenuItem<int>>((cabang) {
                    return DropdownMenuItem(
                      value: cabang['id'],
                      child: Text(cabang['nama']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCabangId = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tab bar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Hari Ini'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat'),
          ],
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTodayTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTab() {
    final absensiHariIni = ref.watch(absensiHariIniProvider(selectedCabangId));

    return absensiHariIni.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        print('❌ Error in _buildTodayTab: $err');
        print('❌ Stack trace: $stack');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat data absensi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $err',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(absensiHariIniProvider(selectedCabangId));
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
      },
      data: (absensi) {
        if (absensi == null) {
          // Belum check-in
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Belum Check-In Hari Ini',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tanggal: ${DateTime.now().toString().split(' ')[0]}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showCheckInDialog,
                  icon: const Icon(Icons.login),
                  label: const Text('Check-In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        // Sudah check-in - with safe parsing
        try {
          final checkIn = absensi['checkIn'] != null
              ? DateTime.parse(absensi['checkIn'].toString())
              : DateTime.now();
          final checkOut = absensi['checkOut'] != null
              ? DateTime.parse(absensi['checkOut'].toString())
              : null;
          final status = absensi['status']?.toString() ?? 'HADIR';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          checkOut != null
                              ? Icons.check_circle
                              : Icons.access_time,
                          color:
                              checkOut != null ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          checkOut != null
                              ? 'Sudah Check-Out'
                              : 'Sedang Bekerja',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                        'Tanggal', absensi['tanggal'].toString().split('T')[0]),
                    _buildInfoRow('Check-In',
                        '${checkIn.hour.toString().padLeft(2, '0')}:${checkIn.minute.toString().padLeft(2, '0')}'),
                    if (checkOut != null)
                      _buildInfoRow('Check-Out',
                          '${checkOut.hour.toString().padLeft(2, '0')}:${checkOut.minute.toString().padLeft(2, '0')}'),
                    _buildInfoRow('Status', status),
                    if (absensi['catatan'] != null &&
                        absensi['catatan'].isNotEmpty)
                      _buildInfoRow('Catatan', absensi['catatan']),
                    if (checkOut != null)
                      _buildInfoRow('Total Jam Kerja',
                          _calculateWorkingHours(checkIn, checkOut)),
                    if (checkOut == null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCheckOutDialog(absensi['id']),
                          icon: const Icon(Icons.logout),
                          label: const Text('Check-Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        } catch (e) {
          print('❌ Error parsing absensi data: $e');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Gagal memuat data absensi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Format data tidak valid: $e',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(absensiHariIniProvider(selectedCabangId));
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildHistoryTab() {
    final absensiList = ref.watch(absensiListProvider);

    return absensiList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        print('❌ Error in _buildHistoryTab: $err');
        print('❌ Stack trace: $stack');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat riwayat absensi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $err',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(absensiListProvider);
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
      },
      data: (absensiList) {
        if (absensiList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('Belum ada riwayat absensi'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(absensiListProvider),
          child: ListView.builder(
            itemCount: absensiList.length,
            itemBuilder: (context, index) {
              final absensi = absensiList[index];

              try {
                final tanggal = absensi['tanggal'] != null
                    ? DateTime.parse(absensi['tanggal'].toString())
                    : DateTime.now();
                final checkIn = absensi['checkIn'] != null
                    ? DateTime.parse(absensi['checkIn'].toString())
                    : null;
                final checkOut = absensi['checkOut'] != null
                    ? DateTime.parse(absensi['checkOut'].toString())
                    : null;
                final status = absensi['status']?.toString() ?? 'HADIR';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                    ),
                    title:
                        Text('${tanggal.day}/${tanggal.month}/${tanggal.year}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cabang: ${absensi['cabang']?['nama'] ?? 'N/A'}'),
                        if (checkIn != null)
                          Text(
                              'In: ${checkIn.hour.toString().padLeft(2, '0')}:${checkIn.minute.toString().padLeft(2, '0')}'),
                        if (checkOut != null)
                          Text(
                              'Out: ${checkOut.hour.toString().padLeft(2, '0')}:${checkOut.minute.toString().padLeft(2, '0')}'),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (checkIn != null && checkOut != null)
                          Text(
                            _calculateWorkingHours(checkIn, checkOut),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                print('❌ Error parsing absensi item at index $index: $e');
                print('❌ Absensi data: $absensi');

                // Return a card with error information
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.error_outline, color: Colors.red),
                    title: const Text('Data Error'),
                    subtitle: Text('Item #${index + 1} - Format tidak valid'),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _calculateWorkingHours(DateTime checkIn, DateTime checkOut) {
    final duration = checkOut.difference(checkIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}j ${minutes}m';
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'HADIR':
        return Icons.check_circle;
      case 'IZIN':
        return Icons.info;
      case 'SAKIT':
        return Icons.local_hospital;
      case 'CUTI':
        return Icons.beach_access;
      default:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'HADIR':
        return Colors.green;
      case 'IZIN':
        return Colors.blue;
      case 'SAKIT':
        return Colors.orange;
      case 'CUTI':
        return Colors.purple;
      default:
        return Colors.red;
    }
  }
}
