import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';
import '../produk/produk_page.dart';
import '../kasir/kasir_page.dart';
import '../pelanggan/pelanggan_page.dart'; // <-- IMPORT HALAMAN BARU

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

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
            ref.read(userProfileProvider.notifier).state =
                response.data['user'];
          }
        }),
        dio.get('/cabang').then((response) {
          if (mounted) {
            ref.read(cabangListProvider.notifier).state = response.data;
          }
        }),
      ]);
    } catch (e) {
      print('Gagal memuat data awal: $e');
    }
  }

  // --- FUNGSI BARU UNTUK MENAMPILKAN DIALOG PILIH CABANG ---
  void _showPilihCabangDialog(BuildContext context, {String mode = 'produk'}) {
    final profile = ref.read(userProfileProvider);
    final userRole =
        profile != null ? Role.values.byName(profile['role']) : null;
    final cabangList = ref.read(cabangListProvider);

    // DEBUG: Print data user profile
    print('[_showPilihCabangDialog] User profile: $profile');
    print('[_showPilihCabangDialog] User role: $userRole');
    print('[_showPilihCabangDialog] Cabang list: $cabangList');
    print('[_showPilihCabangDialog] Mode: $mode');

    // Filter cabang berdasarkan role
    List<dynamic> cabangTersedia = [];
    if (userRole == Role.OWNER) {
      // Owner bisa akses semua cabang miliknya
      cabangTersedia = cabangList;
      print(
          '[_showPilihCabangDialog] Owner - semua cabang tersedia: ${cabangTersedia.length}');
    } else if ((userRole == Role.ADMIN || userRole == Role.KASIR) &&
        profile != null) {
      // Admin dan Kasir hanya bisa akses cabang yang di-assign
      final userAkses = profile['aksesCabang'] as List? ?? [];
      print('[_showPilihCabangDialog] Admin/Kasir - akses cabang: $userAkses');
      final cabangIdsYangBisaDiakses =
          userAkses.map((akses) => akses['cabangId']).toSet();
      print(
          '[_showPilihCabangDialog] Admin/Kasir - cabang IDs yang bisa diakses: $cabangIdsYangBisaDiakses');
      cabangTersedia = cabangList
          .where((cabang) => cabangIdsYangBisaDiakses.contains(cabang['id']))
          .toList();
    }

    if (cabangTersedia.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tidak Ada Akses'),
          content: Text(mode == 'kasir'
              ? 'Anda tidak memiliki akses ke cabang manapun untuk menggunakan kasir.'
              : 'Anda tidak memiliki akses ke cabang manapun untuk mengelola produk.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Cabang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: cabangTersedia.map<Widget>((cabang) {
            return ListTile(
              leading: const Icon(Icons.store_mall_directory),
              title: Text(cabang['nama']),
              subtitle: Text(cabang['alamat']),
              onTap: () {
                Navigator.of(context).pop();
                if (mode == 'kasir') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => KasirPage(
                        cabangId: cabang['id'],
                        cabangNama: cabang['nama'],
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProdukPage(
                        cabangId: cabang['id'],
                        cabangNama: cabang['nama'],
                      ),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    // Konversi peran dari String ke Enum
    final userRole =
        profile != null ? Role.values.byName(profile['role']) : null;

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
          child: SingleChildScrollView(
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
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 40),

                // === MANAJEMEN PELANGGAN (HANYA OWNER) ===
                if (userRole == Role.OWNER)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.contacts),
                    label: const Text('Manajemen Pelanggan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      backgroundColor: Colors.purple,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                          '/pelanggan'); // <-- NAVIGASI KE HALAMAN BARU
                    },
                  ),
                if (userRole == Role.OWNER) const SizedBox(height: 20),

                // === MANAJEMEN CABANG (HANYA OWNER) ===
                if (userRole == Role.OWNER)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.store),
                    label: const Text('Manajemen Cabang'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/cabang');
                    },
                  ),
                if (userRole == Role.OWNER) const SizedBox(height: 20),

                // === MANAJEMEN PROMO (HANYA OWNER) ===
                if (userRole == Role.OWNER)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.discount),
                    label: const Text('Manajemen Promo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed('/promo'); // <-- NAVIGASI KE HALAMAN BARU
                    },
                  ),
                if (userRole == Role.OWNER) const SizedBox(height: 20),

                // === MANAJEMEN PRODUK (OWNER & ADMIN) ===
                if (userRole == Role.OWNER || userRole == Role.ADMIN)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.inventory),
                    label: const Text('Manajemen Produk'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      _showPilihCabangDialog(context, mode: 'produk');
                    },
                  ),
                if (userRole == Role.OWNER || userRole == Role.ADMIN)
                  const SizedBox(height: 20),

                // === MANAJEMEN TIM (HANYA OWNER) ===
                if (userRole == Role.OWNER)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.people),
                    label: const Text('Manajemen Tim'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      backgroundColor: Colors.teal,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/tim');
                    },
                  ),
                if (userRole == Role.OWNER) const SizedBox(height: 20),

                // === SMART AI INSIGHTS (OWNER & ADMIN) ===
                if (userRole == Role.OWNER || userRole == Role.ADMIN)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lightbulb),
                    label: const Text('Smart AI Insights'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      backgroundColor: Colors.indigo,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/insights');
                    },
                  ),
                if (userRole == Role.OWNER || userRole == Role.ADMIN)
                  const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text('Buka Kasir'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    backgroundColor: Colors.orange,
                  ),
                  // --- LOGIKA BARU DI SINI ---
                  onPressed: () {
                    final cabangList = ref.read(cabangListProvider);
                    if (cabangList.isNotEmpty) {
                      // Panggil dialog untuk memilih cabang untuk kasir
                      _showPilihCabangDialog(context, mode: 'kasir');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Anda belum punya cabang. Silakan buat dulu.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
