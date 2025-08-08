import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';
import '../features/home/home_page.dart';
import '../features/kasir/kasir_page.dart';
import '../features/produk/produk_page.dart';
import '../features/pelanggan/pelanggan_page.dart';
import '../widgets/navigation/bottom_nav_bar.dart';

class MainNavigator extends ConsumerStatefulWidget {
  const MainNavigator({super.key});

  @override
  ConsumerState<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends ConsumerState<MainNavigator> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    final profile = ref.read(userProfileProvider);
    final userRole =
        profile != null ? Role.values.byName(profile['role']) : null;

    // Handle navigation berdasarkan index
    switch (index) {
      case 0: // Beranda
        setState(() {
          _currentIndex = 0;
        });
        _pageController.jumpToPage(0);
        break;

      case 1: // Kasir
        _showPilihCabangDialog(context, mode: 'kasir');
        break;

      case 2: // Produk
        _showPilihCabangDialog(context, mode: 'produk');
        break;

      case 3: // Pelanggan
        Navigator.of(context).pushNamed('/pelanggan');
        break;

      case 4: // Lainnya (Owner) atau Laporan (Admin)
        if (userRole == Role.OWNER) {
          _showMenuLainnya(context);
        } else if (userRole == Role.ADMIN) {
          Navigator.of(context).pushNamed('/insights');
        }
        break;
    }
  }

  void _showPilihCabangDialog(BuildContext context, {String mode = 'produk'}) {
    final profile = ref.read(userProfileProvider);
    final userRole =
        profile != null ? Role.values.byName(profile['role']) : null;
    final cabangList = ref.read(cabangListProvider);

    // Filter cabang berdasarkan role
    List<dynamic> cabangTersedia = [];
    if (userRole == Role.OWNER) {
      cabangTersedia = cabangList;
    } else if ((userRole == Role.ADMIN || userRole == Role.KASIR) &&
        profile != null) {
      final userAkses = profile['aksesCabang'] as List? ?? [];
      final cabangIdsYangBisaDiakses =
          userAkses.map((akses) => akses['cabangId']).toSet();
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pilih Cabang',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...cabangTersedia.map((cabang) => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.store_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(cabang['nama']),
                  subtitle: Text(cabang['alamat']),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showMenuLainnya(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Menu Lainnya',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildMenuTile(
              context,
              icon: Icons.receipt_long_rounded,
              title: 'Riwayat Transaksi',
              subtitle: 'Lihat histori transaksi',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/riwayat-transaksi');
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.analytics_rounded,
              title: 'Laporan',
              subtitle: 'Analisis bisnis dan performa',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/insights');
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.store_rounded,
              title: 'Cabang',
              subtitle: 'Kelola cabang bisnis',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/cabang');
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.groups_rounded,
              title: 'Tim',
              subtitle: 'Manajemen pengguna',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/tim');
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.discount_rounded,
              title: 'Promo',
              subtitle: 'Buat dan kelola promo',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/promo');
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.card_giftcard_rounded,
              title: 'Loyalty',
              subtitle: 'Program loyalitas pelanggan',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/loyalty-settings');
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.storefront_rounded,
              title: 'Toko Online',
              subtitle: 'Kelola toko online',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/toko-online');
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.settings_rounded,
              title: 'Pengaturan',
              subtitle: 'Pengaturan akun toko',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/pengaturan-akun');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final userRole =
        profile != null ? Role.values.byName(profile['role']) : null;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: const [
          HomePage(), // Index 0 - Beranda
          // Halaman lain bisa ditambahkan di sini jika perlu
        ],
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        userRole: userRole,
      ),
    );
  }
}
