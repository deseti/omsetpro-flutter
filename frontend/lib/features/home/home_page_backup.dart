import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';
import '../../widgets/home/dashboard_widgets.dart';
import '../../widgets/home/modern_home_sections.dart';
import '../../widgets/responsive_widgets.dart';
import '../../theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../produk/produk_page.dart';
import '../kasir/kasir_page.dart';
import '../pelanggan/pelanggan_page.dart';

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
    final userRole =
        profile != null ? Role.values.byName(profile['role']) : null;

    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context, profile, userRole),
        tablet: _buildTabletLayout(context, profile, userRole),
        desktop: _buildDesktopLayout(context, profile, userRole),
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, Map<String, dynamic>? profile, Role? userRole) {
    return Scaffold(
      appBar: _buildAppBar(context, profile),
      body: _buildScrollableContent(context, profile, userRole),
    );
  }

  Widget _buildTabletLayout(
      BuildContext context, Map<String, dynamic>? profile, Role? userRole) {
    return Scaffold(
      appBar: _buildAppBar(context, profile),
      body: _buildScrollableContent(context, profile, userRole),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, Map<String, dynamic>? profile, Role? userRole) {
    return Scaffold(
      appBar: _buildAppBar(context, profile),
      body: Row(
        children: [
          // Sidebar untuk desktop
          Container(
            width: 280,
            color: Theme.of(context).colorScheme.surface,
            child: _buildSidebar(context, profile, userRole),
          ),
          const VerticalDivider(width: 1),
          // Main content
          Expanded(
            child: _buildScrollableContent(context, profile, userRole),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, Map<String, dynamic>? profile) {
    final theme = Theme.of(context);

    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.point_of_sale,
              color: theme.colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'OmsetPro',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (profile != null)
                Text(
                  'Hi, ${profile['namaLengkap']?.split(' ').first ?? 'User'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitur notifikasi sedang dalam pengembangan'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              profile != null ? profile['namaLengkap'][0].toUpperCase() : 'U',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Profil'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Pengaturan'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Keluar', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'profile':
                Navigator.of(context).pushNamed('/profil');
                break;
              case 'settings':
                if (profile != null) {
                  final userRole = Role.values.byName(profile['role']);
                  if (userRole == Role.OWNER) {
                    Navigator.of(context).pushNamed('/pengaturan-akun');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hanya pemilik yang dapat mengakses pengaturan akun toko'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur pengaturan sedang dalam pengembangan'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                break;
              case 'logout':
                _handleLogout(context);
                break;
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSidebar(
      BuildContext context, Map<String, dynamic>? profile, Role? userRole) {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildWelcomeSection(context, profile),
        const SizedBox(height: 32),
        Expanded(
          child: _buildNavigationMenu(context, userRole),
        ),
      ],
    );
  }

  Widget _buildScrollableContent(
      BuildContext context, Map<String, dynamic>? profile, Role? userRole) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return ResponsiveContainer(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 16 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ResponsiveBreakpoints.isMobile(context)) ...[
              _buildWelcomeSection(context, profile),
              SizedBox(height: isMobile ? 20 : 24),
            ],

            // Quick Stats - Lebih compact
            _buildQuickStats(context, userRole),
            SizedBox(height: isMobile ? 20 : 24),

            // Recent Activity atau Quick Info
            _buildRecentActivity(context, userRole),
            SizedBox(
                height:
                    isMobile ? 100 : 24), // Extra bottom space untuk bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(
      BuildContext context, Map<String, dynamic>? profile) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    String greeting = 'Selamat Datang';

    if (now.hour < 12) {
      greeting = 'Selamat Pagi';
    } else if (now.hour < 15) {
      greeting = 'Selamat Siang';
    } else if (now.hour < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (profile != null) ...[
            const SizedBox(height: 4),
            Text(
              profile['namaLengkap'] ?? 'User',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Mari kelola bisnis Anda dengan lebih baik',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, Role? userRole) {
    return Consumer(
      builder: (context, ref, _) {
        final statsAsync = ref.watch(dashboardStatsProvider);

        return statsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) {
            // Jika error, tampilkan stats kosong
            final emptyStats = <StatsItem>[
              const StatsItem(
                title: 'Penjualan Hari Ini',
                value: 'Rp 0',
                icon: Icons.trending_up,
                iconColor: Colors.green,
                trend: '0%',
                isPositiveTrend: true,
              ),
              const StatsItem(
                title: 'Transaksi',
                value: '0',
                subtitle: 'Hari ini',
                icon: Icons.receipt_long,
                iconColor: Colors.blue,
                trend: '0',
                isPositiveTrend: true,
              ),
              const StatsItem(
                title: 'Produk Terjual',
                value: '0',
                subtitle: 'Item',
                icon: Icons.inventory_2,
                iconColor: Colors.orange,
                trend: '0',
                isPositiveTrend: true,
              ),
              const StatsItem(
                title: 'Keuntungan',
                value: 'Rp 0',
                subtitle: 'Margin 0%',
                icon: Icons.account_balance_wallet,
                iconColor: Colors.purple,
                trend: '0%',
                isPositiveTrend: true,
              ),
            ];

            return ModernStatsGrid(
              title: 'Ringkasan Hari Ini',
              stats: emptyStats,
            );
          },
          data: (dashboardStats) {
            final stats = <StatsItem>[
              StatsItem(
                title: 'Penjualan Hari Ini',
                value: dashboardStats.penjualanHariIni,
                icon: Icons.trending_up,
                iconColor: Colors.green,
                trend: dashboardStats.trendPenjualan,
                isPositiveTrend: dashboardStats.isPositiveTrendPenjualan,
              ),
              StatsItem(
                title: 'Transaksi',
                value: dashboardStats.transaksiHariIni,
                subtitle: 'Hari ini',
                icon: Icons.receipt_long,
                iconColor: Colors.blue,
                trend: dashboardStats.trendTransaksi,
                isPositiveTrend: dashboardStats.isPositiveTrendTransaksi,
              ),
              StatsItem(
                title: 'Produk Terjual',
                value: dashboardStats.produkTerjual,
                subtitle: 'Item',
                icon: Icons.inventory_2,
                iconColor: Colors.orange,
                trend: dashboardStats.trendProduk,
                isPositiveTrend: dashboardStats.isPositiveTrendProduk,
              ),
              StatsItem(
                title: 'Keuntungan',
                value: dashboardStats.keuntungan,
                subtitle: 'Margin',
                icon: Icons.account_balance_wallet,
                iconColor: Colors.purple,
                trend: dashboardStats.trendKeuntungan,
                isPositiveTrend: dashboardStats.isPositiveTrendKeuntungan,
              ),
            ];

            return ModernStatsGrid(
              title: 'Ringkasan Hari Ini',
              stats: stats,
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivity(BuildContext context, Role? userRole) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 8),
          child: Text(
            'Aktivitas Terbaru',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildActivityItem(
                context,
                icon: Icons.point_of_sale_rounded,
                title: 'Kasir siap digunakan',
                subtitle: 'Mulai transaksi penjualan',
                color: Colors.green,
                onTap: () => _showPilihCabangDialog(context, mode: 'kasir'),
              ),
              const Divider(height: 24),
              _buildActivityItem(
                context,
                icon: Icons.trending_up_rounded,
                title: 'Lihat performa hari ini',
                subtitle: 'Cek statistik penjualan',
                color: Colors.blue,
                onTap: () {
                  if (userRole == Role.OWNER || userRole == Role.ADMIN) {
                    Navigator.of(context).pushNamed('/insights');
                  }
                },
              ),
              if (userRole == Role.OWNER) ...[
                const Divider(height: 24),
                _buildActivityItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'Kelola toko Anda',
                  subtitle: 'Pengaturan akun dan cabang',
                  color: Colors.purple,
                  onTap: () =>
                      Navigator.of(context).pushNamed('/pengaturan-akun'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Role? userRole) {
    final actions = <QuickActionItem>[
      QuickActionItem(
        title: 'Kasir',
        subtitle: 'Mulai penjualan',
        icon: Icons.point_of_sale_rounded,
        color: Colors.green,
        onTap: () {
          print('DEBUG: Quick Action - Opening kasir');
          _showPilihCabangDialog(context, mode: 'kasir');
        },
      ),
      QuickActionItem(
        title: 'Produk',
        subtitle: 'Kelola inventori',
        icon: Icons.inventory_2_rounded,
        color: Colors.blue,
        onTap: () {
          print('DEBUG: Quick Action - Navigating to produk');
          _handleProdukAction(context);
        },
      ),
      QuickActionItem(
        title: 'Pelanggan',
        subtitle: 'Data pelanggan',
        icon: Icons.people_rounded,
        color: Colors.orange,
        onTap: () {
          print('DEBUG: Quick Action - Navigating to pelanggan');
          Navigator.of(context).pushNamed('/pelanggan');
        },
      ),
      if (userRole == Role.OWNER || userRole == Role.ADMIN)
        QuickActionItem(
          title: 'Laporan',
          subtitle: 'Analisis bisnis',
          icon: Icons.analytics_rounded,
          color: Colors.purple,
          onTap: () {
            print('DEBUG: Quick Action - Navigating to laporan');
            _navigateToLaporan(context);
          },
        ),
      if (userRole == Role.OWNER)
        QuickActionItem(
          title: 'Tim',
          subtitle: 'Kelola tim',
          icon: Icons.groups_rounded,
          color: Colors.red,
          onTap: () {
            print('DEBUG: Quick Action - Navigating to tim');
            _navigateToTim(context);
          },
        ),
    ];

    return ModernQuickActions(
      title: 'Aksi Cepat',
      actions: actions,
    );
  }

  Widget _buildMainMenu(BuildContext context, Role? userRole) {
    final menuItems = <MenuItem>[];

    // Add menu items based on user role
    if (userRole == Role.OWNER) {
      menuItems.addAll([
        MenuItem(
          title: 'Manajemen Pelanggan',
          subtitle: 'Kelola data pelanggan',
          icon: Icons.contacts,
          iconColor: Colors.purple,
          onTap: () {
            print('DEBUG: Navigating to /pelanggan');
            Navigator.of(context).pushNamed('/pelanggan');
          },
        ),
        MenuItem(
          title: 'Manajemen Cabang',
          subtitle: 'Kelola cabang bisnis',
          icon: Icons.store,
          iconColor: Colors.blue,
          onTap: () {
            print('DEBUG: Navigating to /cabang');
            Navigator.of(context).pushNamed('/cabang');
          },
        ),
        MenuItem(
          title: 'Manajemen Promo',
          subtitle: 'Buat dan kelola promo',
          icon: Icons.discount,
          iconColor: Colors.red,
          onTap: () {
            print('DEBUG: Navigating to /promo');
            Navigator.of(context).pushNamed('/promo');
          },
        ),
      ]);
    }

    if (userRole == Role.OWNER || userRole == Role.ADMIN) {
      menuItems.addAll([
        MenuItem(
          title: 'Manajemen Produk',
          subtitle: 'Kelola inventori',
          icon: Icons.inventory,
          iconColor: Colors.green,
          onTap: () {
            print('DEBUG: Navigating to product management');
            _handleProdukAction(context);
          },
        ),
      ]);
    }

    // Add menu items for all roles
    menuItems.addAll([
      MenuItem(
        title: 'Loyalty Program',
        subtitle: 'Pengaturan poin pelanggan',
        icon: Icons.card_giftcard,
        iconColor: Colors.amber,
        onTap: () {
          print('DEBUG: Navigating to /loyalty-settings');
          Navigator.of(context).pushNamed('/loyalty-settings');
        },
      ),
    ]);

    // Add owner-only settings menu
    if (userRole == Role.OWNER) {
      menuItems.add(
        MenuItem(
          title: 'Pengaturan Akun Toko',
          subtitle: 'Logo, nama, alamat, kontak',
          icon: Icons.settings,
          iconColor: Colors.grey,
          onTap: () {
            print('DEBUG: Navigating to /pengaturan-akun');
            Navigator.of(context).pushNamed('/pengaturan-akun');
          },
        ),
      );
    }

    return ModernMenuGrid(
      title: 'Menu Utama',
      menuItems: menuItems,
    );
  }

  Widget _buildNavigationMenu(BuildContext context, Role? userRole) {
    return ListView(
      children: [
        if (userRole == Role.OWNER) ...[
          _buildNavItem(context, Icons.contacts, 'Pelanggan', () {
            print('DEBUG: Sidebar - Navigating to /pelanggan');
            Navigator.of(context).pushNamed('/pelanggan');
          }),
          _buildNavItem(context, Icons.store, 'Cabang', () {
            print('DEBUG: Sidebar - Navigating to /cabang');
            Navigator.of(context).pushNamed('/cabang');
          }),
          _buildNavItem(context, Icons.discount, 'Promo', () {
            print('DEBUG: Sidebar - Navigating to /promo');
            Navigator.of(context).pushNamed('/promo');
          }),
          _buildNavItem(context, Icons.people, 'Tim', () {
            print('DEBUG: Sidebar - Navigating to /tim');
            Navigator.of(context).pushNamed('/tim');
          }),
          _buildNavItem(context, Icons.settings, 'Pengaturan Akun', () {
            print('DEBUG: Sidebar - Navigating to /pengaturan-akun');
            Navigator.of(context).pushNamed('/pengaturan-akun');
          }),
        ],
        if (userRole == Role.OWNER || userRole == Role.ADMIN) ...[
          _buildNavItem(context, Icons.inventory, 'Produk', () {
            print('DEBUG: Sidebar - Navigating to product management');
            _handleProdukAction(context);
          }),
          _buildNavItem(context, Icons.analytics, 'Laporan', () {
            print('DEBUG: Sidebar - Navigating to /insights');
            Navigator.of(context).pushNamed('/insights');
          }),
        ],
        _buildNavItem(context, Icons.point_of_sale, 'Kasir', () {
          print('DEBUG: Sidebar - Navigating to kasir');
          _handleKasirAction(context);
        }),
        _buildNavItem(context, Icons.card_giftcard, 'Loyalty', () {
          print('DEBUG: Sidebar - Navigating to /loyalty-settings');
          Navigator.of(context).pushNamed('/loyalty-settings');
        }),
        const Divider(),
        _buildNavItem(context, Icons.person, 'Profil Saya', () {
          print('DEBUG: Sidebar - Navigating to /profil');
          Navigator.of(context).pushNamed('/profil');
        }),
      ],
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _handleKasirAction(BuildContext context) {
    final cabangList = ref.read(cabangListProvider);
    if (cabangList.isNotEmpty) {
      _showPilihCabangDialog(context, mode: 'kasir');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda belum punya cabang. Silakan buat dulu.'),
        ),
      );
    }
  }

  void _handleProdukAction(BuildContext context) {
    final cabangList = ref.read(cabangListProvider);
    if (cabangList.isNotEmpty) {
      _showPilihCabangDialog(context, mode: 'produk');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda belum punya cabang. Silakan buat dulu.'),
        ),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    ref.read(userProfileProvider.notifier).state = null;
    ref.read(accessTokenProvider.notifier).state = null;
    ref.read(authStateProvider.notifier).state = false;
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  void _navigateToLaporan(BuildContext context) {
    Navigator.of(context).pushNamed('/insights');
  }

  void _navigateToTim(BuildContext context) {
    Navigator.of(context).pushNamed('/tim');
  }
}
