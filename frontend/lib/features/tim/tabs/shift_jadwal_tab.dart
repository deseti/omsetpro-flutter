import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../providers/providers.dart';

// Provider untuk shift dan jadwal
final shiftListProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/shift');
  return response.data;
});

final jadwalTimProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/shift/jadwal');
  return response.data;
});

class ShiftJadwalTab extends ConsumerStatefulWidget {
  const ShiftJadwalTab({super.key});

  @override
  ConsumerState<ShiftJadwalTab> createState() => _ShiftJadwalTabState();
}

class _ShiftJadwalTabState extends ConsumerState<ShiftJadwalTab>
    with TickerProviderStateMixin {
  late TabController _tabController;

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

  Future<void> _createShift() async {
    final namaController = TextEditingController();
    final jamMulaiController = TextEditingController();
    final jamSelesaiController = TextEditingController();
    final cabangList = ref.read(cabangListProvider);
    int selectedCabangId = cabangList.isNotEmpty ? cabangList.first['id'] : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Shift Baru'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama Shift'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: jamMulaiController,
                  decoration: const InputDecoration(
                    labelText: 'Jam Mulai (HH:MM)',
                    hintText: '08:00',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: jamSelesaiController,
                  decoration: const InputDecoration(
                    labelText: 'Jam Selesai (HH:MM)',
                    hintText: '17:00',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCabangId,
                  decoration: const InputDecoration(labelText: 'Cabang'),
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
                await dio.post('/shift', data: {
                  'nama': namaController.text,
                  'jamMulai': jamMulaiController.text,
                  'jamSelesai': jamSelesaiController.text,
                  'cabangId': selectedCabangId,
                });

                Navigator.of(context).pop();
                ref.invalidate(shiftListProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shift berhasil dibuat!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal membuat shift: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  Future<void> _createJadwal() async {
    final timList = ref.read(timListFutureProvider).value ?? [];
    final shiftList = ref.read(shiftListProvider).value ?? [];

    if (timList.isEmpty || shiftList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada tim atau shift tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int selectedUserId = timList.first.id;
    int selectedShiftId = shiftList.first['id'];
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Jadwal Tim'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
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
              DropdownButtonFormField<int>(
                value: selectedShiftId,
                decoration: const InputDecoration(labelText: 'Pilih Shift'),
                items: shiftList.map<DropdownMenuItem<int>>((shift) {
                  return DropdownMenuItem(
                    value: shift['id'],
                    child: Text(
                        '${shift['nama']} (${shift['jamMulai']} - ${shift['jamSelesai']})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedShiftId = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Tanggal'),
                subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = date;
                    });
                  }
                },
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
              try {
                final dio = ref.read(dioProvider);
                await dio.post('/shift/jadwal', data: {
                  'userId': selectedUserId,
                  'shiftId': selectedShiftId,
                  'tanggal':
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                });

                Navigator.of(context).pop();
                ref.invalidate(jadwalTimProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jadwal berhasil dibuat!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal membuat jadwal: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Shift'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Jadwal'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildShiftTab(),
              _buildJadwalTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShiftTab() {
    final shiftList = ref.watch(shiftListProvider);

    return shiftList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (shifts) {
        return Scaffold(
          body: shifts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada shift yang dibuat'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(shiftListProvider),
                  child: ListView.builder(
                    itemCount: shifts.length,
                    itemBuilder: (context, index) {
                      final shift = shifts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading:
                              const Icon(Icons.access_time, color: Colors.blue),
                          title: Text(shift['nama']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Waktu: ${shift['jamMulai']} - ${shift['jamSelesai']}'),
                              Text('Cabang: ${shift['cabang']['nama']}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Hapus',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Konfirmasi'),
                                    content:
                                        Text('Hapus shift "${shift['nama']}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    final dio = ref.read(dioProvider);
                                    await dio.delete('/shift/${shift['id']}');
                                    ref.invalidate(shiftListProvider);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Shift berhasil dihapus'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Gagal menghapus shift: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _createShift,
            tooltip: 'Tambah Shift',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildJadwalTab() {
    final jadwalList = ref.watch(jadwalTimProvider);

    return jadwalList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (jadwals) {
        return Scaffold(
          body: jadwals.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada jadwal yang dibuat'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(jadwalTimProvider),
                  child: ListView.builder(
                    itemCount: jadwals.length,
                    itemBuilder: (context, index) {
                      final jadwal = jadwals[index];
                      final tanggal = DateTime.parse(jadwal['tanggal']);
                      final isToday =
                          DateTime.now().difference(tanggal).inDays == 0;
                      final isPast = tanggal.isBefore(
                          DateTime.now().subtract(const Duration(days: 1)));

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: isToday
                            ? Colors.blue[50]
                            : (isPast ? Colors.grey[100] : null),
                        child: ListTile(
                          leading: Icon(
                            isToday ? Icons.today : Icons.calendar_today,
                            color: isToday
                                ? Colors.blue
                                : (isPast ? Colors.grey : Colors.green),
                          ),
                          title: Text(
                              '${jadwal['user']['namaLengkap']} (${jadwal['user']['role']})'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${tanggal.day}/${tanggal.month}/${tanggal.year}${isToday ? ' (Hari ini)' : ''}',
                                style: TextStyle(
                                  fontWeight: isToday ? FontWeight.bold : null,
                                  color: isToday ? Colors.blue : null,
                                ),
                              ),
                              Text(
                                  'Shift: ${jadwal['shift']['nama']} (${jadwal['shift']['jamMulai']} - ${jadwal['shift']['jamSelesai']})'),
                              Text(
                                  'Cabang: ${jadwal['shift']['cabang']['nama']}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Hapus',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Konfirmasi'),
                                    content: const Text('Hapus jadwal ini?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    final dio = ref.read(dioProvider);
                                    await dio.delete(
                                        '/shift/jadwal/${jadwal['id']}');
                                    ref.invalidate(jadwalTimProvider);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Jadwal berhasil dihapus'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Gagal menghapus jadwal: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _createJadwal,
            tooltip: 'Tambah Jadwal',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
