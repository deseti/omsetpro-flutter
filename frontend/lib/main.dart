import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:intl/date_symbol_data_local.dart'; // Import untuk locale data
import 'features/auth/auth_page.dart';
import 'features/cabang/cabang_page.dart';
import 'navigation/main_navigator.dart'; // Update import
import 'providers/providers.dart';
import 'features/produk/import_produk_page.dart'; // Import halaman import produk
import 'features/tim/tim_page.dart'; // Import halaman tim
// import 'features/laporan/screens/laporan_dashboard_screen.dart'; // DINONAKTIFKAN - Import halaman laporan
// import 'features/laporan/screens/detail_laporan_screen.dart'; // DINONAKTIFKAN - Import detail laporan
import 'pages/insight_dashboard_page.dart'; // Import insight dashboard
import 'services/offline_database_proxy.dart'
    as OfflineDatabase; // Import offline database
import 'features/pelanggan/pelanggan_page.dart';
import 'features/loyalty/loyalty_settings_page.dart'; // <-- IMPORT HALAMAN BARU
import 'features/promo/promo_page.dart'; // <-- IMPORT HALAMAN BARU
import 'features/pengaturan/pengaturan_akun_page.dart'; // <-- IMPORT HALAMAN PENGATURAN AKUN
import 'features/pengaturan/pengaturan_umum_page.dart'; // <-- IMPORT HALAMAN PENGATURAN UMUM
import 'features/profil/profil_page.dart'; // <-- IMPORT HALAMAN PROFIL
import 'features/riwayat/riwayat_transaksi_page.dart'; // <-- IMPORT HALAMAN RIWAYAT TRANSAKSI
import 'theme/app_theme.dart'; // Import tema baru
import 'services/hardware/hardware_manager_service.dart'; // Import hardware manager

// Ubah fungsi main menjadi async
Future<void> main() async {
  // Pastikan semua binding Flutter sudah siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale data untuk mencegah LocaleDataException
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    // Fallback jika locale id_ID tidak tersedia
    print('Warning: Failed to initialize id_ID locale, using default');
  }

  // Inisialisasi database offline hanya untuk mobile
  if (!kIsWeb) {
    await OfflineDatabase.OfflineDatabase.database;
  }

  // Initialize hardware manager for POS functionality
  try {
    final hardwareManager = HardwareManagerService();
    await hardwareManager.initialize();
    print('✅ Hardware Manager initialized in main');
  } catch (e) {
    print('⚠️ Hardware Manager initialization failed in main: $e');
    // Continue app startup even if hardware fails
  }

  // Buat instance SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Baca token dari penyimpanan
  final token = prefs.getString('accessToken');

  runApp(
    ProviderScope(
      // Ganti nilai awal provider berdasarkan token yang ditemukan
      overrides: [
        accessTokenProvider.overrideWith((ref) => token),
        authStateProvider.overrideWith((ref) => token != null),
      ],
      child: const OmsetProApp(),
    ),
  );
}

class OmsetProApp extends StatelessWidget {
  const OmsetProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmsetPro',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Mengikuti sistem device
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const AuthChecker(),
        '/home': (context) => const MainNavigator(),
        '/cabang': (context) => const CabangPage(),
        '/import-produk': (context) => const ImportProdukPage(),
        '/tim': (context) => const TimPage(),
        '/insights': (context) => const InsightDashboardPage(),
        '/pelanggan': (context) => const PelangganPage(),
        '/loyalty-settings': (context) => const LoyaltySettingsPage(),
        '/promo': (context) => const PromoPage(), // <-- DAFTARKAN RUTE BARU
        '/riwayat-transaksi': (context) => const RiwayatTransaksiPage(), // <-- RUTE RIWAYAT TRANSAKSI
        '/pengaturan-akun': (context) =>
            const PengaturanAkunPage(), // <-- RUTE PENGATURAN AKUN
        '/profil': (context) => const ProfilPage(), // <-- RUTE PROFIL
      },
      initialRoute: '/',
    );
  }
}

class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authStateProvider);
    return isLoggedIn ? const MainNavigator() : const AuthPage();
  }
}
