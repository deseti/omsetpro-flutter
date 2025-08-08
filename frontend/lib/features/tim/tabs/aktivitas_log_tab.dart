import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../providers/providers.dart';

// Provider untuk audit log
final auditLogListProvider = FutureProvider.autoDispose
    .family<List<dynamic>, Map<String, dynamic>>((ref, params) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/audit-log', queryParameters: params);
  return response.data;
});

final aktivitasTimProvider = FutureProvider.autoDispose
    .family<List<dynamic>, Map<String, dynamic>>((ref, params) async {
  final dio = ref.read(dioProvider);
  final response =
      await dio.get('/audit-log/user-activity', queryParameters: params);
  return response.data;
});

class AktivitasLogTab extends ConsumerStatefulWidget {
  const AktivitasLogTab({super.key});

  @override
  ConsumerState<AktivitasLogTab> createState() => _AktivitasLogTabState();
}

class _AktivitasLogTabState extends ConsumerState<AktivitasLogTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String selectedAction = 'ALL';
  DateTime selectedDate = DateTime.now();
  int? selectedUserId;

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

  List<String> get availableActions => [
        'ALL',
        'LOGIN',
        'LOGOUT',
        'CREATE_USER',
        'UPDATE_USER',
        'DELETE_USER',
        'CREATE_PRODUK',
        'UPDATE_PRODUK',
        'DELETE_PRODUK',
        'CREATE_TRANSAKSI',
        'UPDATE_TRANSAKSI',
        'DELETE_TRANSAKSI',
        'APPROVE_IZIN',
        'REJECT_IZIN',
        'CREATE_SHIFT',
        'UPDATE_SHIFT',
        'DELETE_SHIFT'
      ];

  String _getActionDisplayName(String action) {
    switch (action) {
      case 'ALL':
        return 'Semua Aktivitas';
      case 'LOGIN':
        return 'Login';
      case 'LOGOUT':
        return 'Logout';
      case 'CREATE_USER':
        return 'Buat User';
      case 'UPDATE_USER':
        return 'Update User';
      case 'DELETE_USER':
        return 'Hapus User';
      case 'CREATE_PRODUK':
        return 'Buat Produk';
      case 'UPDATE_PRODUK':
        return 'Update Produk';
      case 'DELETE_PRODUK':
        return 'Hapus Produk';
      case 'CREATE_TRANSAKSI':
        return 'Buat Transaksi';
      case 'UPDATE_TRANSAKSI':
        return 'Update Transaksi';
      case 'DELETE_TRANSAKSI':
        return 'Hapus Transaksi';
      case 'APPROVE_IZIN':
        return 'Setujui Izin';
      case 'REJECT_IZIN':
        return 'Tolak Izin';
      case 'CREATE_SHIFT':
        return 'Buat Shift';
      case 'UPDATE_SHIFT':
        return 'Update Shift';
      case 'DELETE_SHIFT':
        return 'Hapus Shift';
      default:
        return action;
    }
  }

  Color _getActionColor(String action) {
    if (action.startsWith('CREATE')) return Colors.green;
    if (action.startsWith('UPDATE')) return Colors.orange;
    if (action.startsWith('DELETE')) return Colors.red;
    if (action == 'LOGIN') return Colors.blue;
    if (action == 'LOGOUT') return Colors.grey;
    if (action.contains('APPROVE')) return Colors.green;
    if (action.contains('REJECT')) return Colors.red;
    return Colors.blue;
  }

  Icon _getActionIcon(String action) {
    if (action.startsWith('CREATE'))
      return const Icon(Icons.add_circle, color: Colors.green);
    if (action.startsWith('UPDATE'))
      return const Icon(Icons.edit, color: Colors.orange);
    if (action.startsWith('DELETE'))
      return const Icon(Icons.delete, color: Colors.red);
    if (action == 'LOGIN') return const Icon(Icons.login, color: Colors.blue);
    if (action == 'LOGOUT') return const Icon(Icons.logout, color: Colors.grey);
    if (action.contains('APPROVE'))
      return const Icon(Icons.check_circle, color: Colors.green);
    if (action.contains('REJECT'))
      return const Icon(Icons.cancel, color: Colors.red);
    return const Icon(Icons.info, color: Colors.blue);
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
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

  Map<String, dynamic> _getFilterParams() {
    final params = <String, dynamic>{
      'date': selectedDate.toIso8601String().split('T')[0],
      'limit': 100,
    };

    if (selectedAction != 'ALL') {
      params['action'] = selectedAction;
    }

    if (selectedUserId != null) {
      params['userId'] = selectedUserId;
    }

    return params;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Log Aktivitas'),
            Tab(icon: Icon(Icons.analytics), text: 'Analisis'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLogAktivitasTab(),
              _buildAnalisisTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogAktivitasTab() {
    final auditLogs = ref.watch(auditLogListProvider(_getFilterParams()));

    return Column(
      children: [
        // Filter Section
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Date and User Filter Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(_formatDate(selectedDate)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final timList =
                            ref.watch(timListFutureProvider).value ?? [];
                        return DropdownButtonFormField<int?>(
                          value: selectedUserId,
                          decoration: const InputDecoration(
                            labelText: 'Filter User',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Semua User'),
                            ),
                            ...timList.map<DropdownMenuItem<int?>>((user) {
                              return DropdownMenuItem(
                                value: user.id,
                                child: Text(user.namaLengkap),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedUserId = value;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Filter
              DropdownButtonFormField<String>(
                value: selectedAction,
                decoration: const InputDecoration(
                  labelText: 'Filter Aktivitas',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: availableActions.map<DropdownMenuItem<String>>((action) {
                  return DropdownMenuItem(
                    value: action,
                    child: Text(_getActionDisplayName(action)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAction = value!;
                  });
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: auditLogs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (logs) {
              if (logs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Tidak ada aktivitas pada periode ini'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(auditLogListProvider(_getFilterParams())),
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final user = log['user'];
                    final action = log['action'];
                    final createdAt = DateTime.parse(log['createdAt']);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: _getActionIcon(action),
                        title: Text(
                            '${user['namaLengkap']} - ${_getActionDisplayName(action)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (log['description'] != null)
                              Text(log['description']),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _formatDateTime(createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                if (log['ipAddress'] != null)
                                  Text(
                                    'IP: ${log['ipAddress']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getActionColor(action).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            action,
                            style: TextStyle(
                              color: _getActionColor(action),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: log['metadata'] != null
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                        'Detail ${_getActionDisplayName(action)}'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('User: ${user['namaLengkap']}'),
                                          Text(
                                              'Waktu: ${createdAt.toString().split('.')[0]}'),
                                          if (log['ipAddress'] != null)
                                            Text(
                                                'IP Address: ${log['ipAddress']}'),
                                          if (log['userAgent'] != null)
                                            Text(
                                                'User Agent: ${log['userAgent']}'),
                                          const SizedBox(height: 16),
                                          const Text('Metadata:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              log['metadata'].toString(),
                                              style: const TextStyle(
                                                  fontFamily: 'monospace'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Tutup'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
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

  Widget _buildAnalisisTab() {
    final aktivitasParams = {
      'startDate': DateTime(selectedDate.year, selectedDate.month, 1)
          .toIso8601String()
          .split('T')[0],
      'endDate': DateTime(selectedDate.year, selectedDate.month + 1, 0)
          .toIso8601String()
          .split('T')[0],
    };

    final aktivitas = ref.watch(aktivitasTimProvider(aktivitasParams));

    return Column(
      children: [
        // Header dengan periode
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.analytics, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Analisis Periode: ${_formatMonthYear(selectedDate)}'),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = DateTime(date.year, date.month, 1);
                    });
                  }
                },
                icon: const Icon(Icons.calendar_month),
              ),
            ],
          ),
        ),

        Expanded(
          child: aktivitas.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (data) {
              if (data.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Tidak ada data aktivitas untuk periode ini'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(aktivitasTimProvider(aktivitasParams)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final userActivity = data[index];
                    final user = userActivity['user'];
                    final stats = userActivity['stats'];
                    final totalActivities = (stats as Map<String, dynamic>)
                        .values
                        .fold<int>(0, (sum, value) => sum + (value as int));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(user['namaLengkap'][0]),
                        ),
                        title: Text('${user['namaLengkap']} (${user['role']})'),
                        subtitle: Text('Total aktivitas: $totalActivities'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Breakdown Aktivitas:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),

                                // Aktivitas breakdown
                                ...stats.entries.map<Widget>((entry) {
                                  final action = entry.key;
                                  final count = entry.value as int;
                                  final percentage = totalActivities > 0
                                      ? (count / totalActivities * 100).round()
                                      : 0;

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _getActionColor(action),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                              _getActionDisplayName(action)),
                                        ),
                                        Text('$count ($percentage%)'),
                                      ],
                                    ),
                                  );
                                }),

                                const SizedBox(height: 16),

                                // Activity level indicator
                                Row(
                                  children: [
                                    const Text('Tingkat Aktivitas: '),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getActivityLevelColor(
                                                totalActivities)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _getActivityLevelText(totalActivities),
                                        style: TextStyle(
                                          color: _getActivityLevelColor(
                                              totalActivities),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
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
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatMonthYear(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.year}';
  }

  Color _getActivityLevelColor(int totalActivities) {
    if (totalActivities >= 50) return Colors.green;
    if (totalActivities >= 20) return Colors.orange;
    return Colors.red;
  }

  String _getActivityLevelText(int totalActivities) {
    if (totalActivities >= 50) return 'Sangat Aktif';
    if (totalActivities >= 20) return 'Aktif';
    if (totalActivities >= 5) return 'Cukup Aktif';
    return 'Kurang Aktif';
  }
}
