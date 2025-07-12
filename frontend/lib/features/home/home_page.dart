import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omsetpro/models/user_model.dart'; // Import model baru
import '../../providers/providers.dart';
import '../kasir/kasir_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    if (ref.read(userProfileProvider) != null) return;
    try {
      final dio = ref.read(dioProvider);
      await Future.wait([
        dio.get('/auth/profile').then((response) {
          if (mounted) {
            ref.read(userProfileProvider.notifier).state = response.data['user'];
          }
        }),
        dio.get('/cabang').then((response) {
          if (mounted) {
            ref.read(cabangListProvider.notifier).state = response.data;
          }
        }),
      ]);
    } on DioException catch (e) {
      print('Gagal memuat data awal: $e');
    }
  }

  // --- FUNGSI BARU UNTUK MENAMPILKAN DIALOG PILIH CABANG ---
  void _showPilihCabangDialog() {
    final cabangList = ref.read(cabangListProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Cabang'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cabangList.length,
              itemBuilder: (context, index) {
                final cabang = cabangList[index];
                return ListTile(
                  title: Text(cabang['nama']),
                  onTap: () {
                    // Tutup dialog dulu
                    Navigator.of(context).pop();
                    // Buka halaman kasir untuk cabang yang dipilih
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => KasirPage(
                          cabangId: cabang['id'],
                          cabangNama: cabang['nama'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    // Konversi peran dari String ke Enum
    final userRole = profile != null ? Role.values.byName(profile['role']) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('accessToken');
              ref.read(userProfileProvider.notifier).state = null;
              ref.read(accessTokenProvider.notifier).state = null;
              ref.read(authStateProvider.notifier).state = false;
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Selamat Datang,',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (profile != null)
                Text(
                  profile['namaLengkap'] ?? 'Pengguna',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.store),
                label: const Text('Manajemen Cabang'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/cabang');
                },
              ),
              const SizedBox(height: 20),

              // --- TAMBAHKAN TOMBOL INI DENGAN LOGIKA PENGECEKAN PERAN ---
              if (userRole == Role.OWNER)
                ElevatedButton.icon(
                  icon: const Icon(Icons.people),
                  label: const Text('Manajemen Tim'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    backgroundColor: Colors.teal,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/tim');
                  },
                ),
              const SizedBox(height: 20),

              // === MENU LAPORAN & ANALISIS (OWNER & ADMIN) ===
              if (userRole == Role.OWNER || userRole == Role.ADMIN)
                ElevatedButton.icon(
                  icon: const Icon(Icons.analytics),
                  label: const Text('Laporan & Analisis'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    backgroundColor: Colors.purple,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/laporan');
                  },
                ),
              if (userRole == Role.OWNER || userRole == Role.ADMIN) const SizedBox(height: 20),

              // === SMART AI INSIGHTS (OWNER & ADMIN) ===
              if (userRole == Role.OWNER || userRole == Role.ADMIN)
                ElevatedButton.icon(
                  icon: const Icon(Icons.lightbulb),
                  label: const Text('Smart AI Insights'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    backgroundColor: Colors.indigo,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/insights');
                  },
                ),
              if (userRole == Role.OWNER || userRole == Role.ADMIN) const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.point_of_sale),
                label: const Text('Buka Kasir'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: Colors.orange,
                ),
                // --- LOGIKA BARU DI SINI ---
                onPressed: () {
                  final cabangList = ref.read(cabangListProvider);
                  if (cabangList.isNotEmpty) {
                    // Panggil dialog untuk memilih cabang
                    _showPilihCabangDialog();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Anda belum punya cabang. Silakan buat dulu.')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}