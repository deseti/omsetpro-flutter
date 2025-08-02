import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';
import '../../widgets/responsive_widgets.dart';

// Model untuk pengaturan umum
class PengaturanUmum {
  final bool notifikasiTransaksi;
  final bool notifikasiStok;
  final bool notifikasiLaporan;
  final String tema; // 'system', 'light', 'dark'
  final String bahasa; // 'id', 'en'

  PengaturanUmum({
    required this.notifikasiTransaksi,
    required this.notifikasiStok,
    required this.notifikasiLaporan,
    required this.tema,
    required this.bahasa,
  });

  factory PengaturanUmum.defaultSettings() {
    return PengaturanUmum(
      notifikasiTransaksi: true,
      notifikasiStok: true,
      notifikasiLaporan: false,
      tema: 'system',
      bahasa: 'id',
    );
  }

  factory PengaturanUmum.fromJson(Map<String, dynamic> json) {
    return PengaturanUmum(
      notifikasiTransaksi: json['notifikasiTransaksi'] ?? true,
      notifikasiStok: json['notifikasiStok'] ?? true,
      notifikasiLaporan: json['notifikasiLaporan'] ?? false,
      tema: json['tema'] ?? 'system',
      bahasa: json['bahasa'] ?? 'id',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifikasiTransaksi': notifikasiTransaksi,
      'notifikasiStok': notifikasiStok,
      'notifikasiLaporan': notifikasiLaporan,
      'tema': tema,
      'bahasa': bahasa,
    };
  }

  PengaturanUmum copyWith({
    bool? notifikasiTransaksi,
    bool? notifikasiStok,
    bool? notifikasiLaporan,
    String? tema,
    String? bahasa,
  }) {
    return PengaturanUmum(
      notifikasiTransaksi: notifikasiTransaksi ?? this.notifikasiTransaksi,
      notifikasiStok: notifikasiStok ?? this.notifikasiStok,
      notifikasiLaporan: notifikasiLaporan ?? this.notifikasiLaporan,
      tema: tema ?? this.tema,
      bahasa: bahasa ?? this.bahasa,
    );
  }
}

// Provider untuk pengaturan umum
final pengaturanUmumProvider = StateNotifierProvider<PengaturanUmumNotifier, PengaturanUmum>((ref) {
  return PengaturanUmumNotifier();
});

class PengaturanUmumNotifier extends StateNotifier<PengaturanUmum> {
  PengaturanUmumNotifier() : super(PengaturanUmum.defaultSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('pengaturan_umum');
      if (settingsJson != null) {
        // Parse JSON jika ada settings tersimpan
        final Map<String, dynamic> settings = {};
        // Untuk sederhana, kita load dari SharedPreferences individual keys
        settings['notifikasiTransaksi'] = prefs.getBool('notif_transaksi') ?? true;
        settings['notifikasiStok'] = prefs.getBool('notif_stok') ?? true;
        settings['notifikasiLaporan'] = prefs.getBool('notif_laporan') ?? false;
        settings['tema'] = prefs.getString('tema') ?? 'system';
        settings['bahasa'] = prefs.getString('bahasa') ?? 'id';
        
        state = PengaturanUmum.fromJson(settings);
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> updateSettings(PengaturanUmum newSettings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Simpan individual settings
      await prefs.setBool('notif_transaksi', newSettings.notifikasiTransaksi);
      await prefs.setBool('notif_stok', newSettings.notifikasiStok);
      await prefs.setBool('notif_laporan', newSettings.notifikasiLaporan);
      await prefs.setString('tema', newSettings.tema);
      await prefs.setString('bahasa', newSettings.bahasa);
      
      state = newSettings;
    } catch (e) {
      print('Error saving settings: $e');
    }
  }
}

class PengaturanUmumPage extends ConsumerStatefulWidget {
  const PengaturanUmumPage({super.key});

  @override
  ConsumerState<PengaturanUmumPage> createState() => _PengaturanUmumPageState();
}

class _PengaturanUmumPageState extends ConsumerState<PengaturanUmumPage> {
  bool _isLoading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('rememberMe');
      await prefs.remove('email');
      
      ref.read(userProfileProvider.notifier).state = null;
      ref.read(accessTokenProvider.notifier).state = null;
      ref.read(authStateProvider.notifier).state = false;
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      _showSnackBar('Gagal logout: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(pengaturanUmumProvider);
    final profile = ref.watch(userProfileProvider);
    final userRole = profile != null ? Role.values.byName(profile['role']) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        elevation: 0,
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(settings, userRole),
        tablet: _buildTabletLayout(settings, userRole),
        desktop: _buildDesktopLayout(settings, userRole),
      ),
    );
  }

  Widget _buildMobileLayout(PengaturanUmum settings, Role? userRole) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNotificationSection(settings),
          const SizedBox(height: 24),
          _buildDisplaySection(settings),
          const SizedBox(height: 24),
          _buildQuickActionsSection(userRole),
          const SizedBox(height: 24),
          _buildLogoutSection(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(PengaturanUmum settings, Role? userRole) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNotificationSection(settings),
              const SizedBox(height: 32),
              _buildDisplaySection(settings),
              const SizedBox(height: 32),
              _buildQuickActionsSection(userRole),
              const SizedBox(height: 32),
              _buildLogoutSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(PengaturanUmum settings, Role? userRole) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolom kiri - Notifikasi & Display
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildNotificationSection(settings),
                    const SizedBox(height: 32),
                    _buildDisplaySection(settings),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Kolom kanan - Quick Actions & Logout
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildQuickActionsSection(userRole),
                    const SizedBox(height: 32),
                    _buildLogoutSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection(PengaturanUmum settings) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifikasi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Atur preferensi notifikasi Anda',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Notifikasi Transaksi
            SwitchListTile(
              title: const Text('Notifikasi Transaksi'),
              subtitle: const Text('Terima notifikasi untuk setiap transaksi'),
              value: settings.notifikasiTransaksi,
              onChanged: (value) {
                final newSettings = settings.copyWith(notifikasiTransaksi: value);
                ref.read(pengaturanUmumProvider.notifier).updateSettings(newSettings);
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Notifikasi Stok
            SwitchListTile(
              title: const Text('Notifikasi Stok'),
              subtitle: const Text('Terima notifikasi saat stok menipis'),
              value: settings.notifikasiStok,
              onChanged: (value) {
                final newSettings = settings.copyWith(notifikasiStok: value);
                ref.read(pengaturanUmumProvider.notifier).updateSettings(newSettings);
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Notifikasi Laporan (khusus Owner/Admin)
            Consumer(
              builder: (context, ref, _) {
                final profile = ref.watch(userProfileProvider);
                final userRole = profile != null ? Role.values.byName(profile['role']) : null;
                
                if (userRole == Role.OWNER || userRole == Role.ADMIN) {
                  return SwitchListTile(
                    title: const Text('Notifikasi Laporan'),
                    subtitle: const Text('Terima laporan harian otomatis'),
                    value: settings.notifikasiLaporan,
                    onChanged: (value) {
                      final newSettings = settings.copyWith(notifikasiLaporan: value);
                      ref.read(pengaturanUmumProvider.notifier).updateSettings(newSettings);
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySection(PengaturanUmum settings) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tampilan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sesuaikan tampilan aplikasi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Tema
            ListTile(
              title: const Text('Tema'),
              subtitle: Text(_getThemeDisplayName(settings.tema)),
              leading: const Icon(Icons.palette),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => _showThemeDialog(settings),
            ),

            const Divider(),

            // Bahasa
            ListTile(
              title: const Text('Bahasa'),
              subtitle: Text(_getLanguageDisplayName(settings.bahasa)),
              leading: const Icon(Icons.language),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => _showLanguageDialog(settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(Role? userRole) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Akses Cepat',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Akses fitur-fitur penting',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Profil
            ListTile(
              title: const Text('Profil Saya'),
              subtitle: const Text('Edit nama dan password'),
              leading: const Icon(Icons.person),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.of(context).pushNamed('/profil');
              },
            ),

            const Divider(),

            // Pengaturan Akun Toko (khusus Owner)
            if (userRole == Role.OWNER) ...[
              ListTile(
                title: const Text('Pengaturan Toko'),
                subtitle: const Text('Logo, nama, alamat, kontak'),
                leading: const Icon(Icons.store),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.of(context).pushNamed('/pengaturan-akun');
                },
              ),
              const Divider(),
            ],

            // Bantuan & Dukungan
            ListTile(
              title: const Text('Bantuan & Dukungan'),
              subtitle: const Text('FAQ dan hubungi support'),
              leading: const Icon(Icons.help),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                _showSnackBar('Fitur bantuan akan segera hadir');
              },
            ),

            const Divider(),

            // Tentang Aplikasi
            ListTile(
              title: const Text('Tentang OmsetPro'),
              subtitle: const Text('Versi aplikasi dan informasi'),
              leading: const Icon(Icons.info),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => _showAboutDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Akun',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _showLogoutDialog(),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: const Text('Keluar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'light':
        return 'Terang';
      case 'dark':
        return 'Gelap';
      case 'system':
      default:
        return 'Ikuti Sistem';
    }
  }

  String _getLanguageDisplayName(String language) {
    switch (language) {
      case 'en':
        return 'English';
      case 'id':
      default:
        return 'Bahasa Indonesia';
    }
  }

  void _showThemeDialog(PengaturanUmum settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Tema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Ikuti Sistem'),
                value: 'system',
                groupValue: settings.tema,
                onChanged: (value) {
                  if (value != null) {
                    final newSettings = settings.copyWith(tema: value);
                    ref.read(pengaturanUmumProvider.notifier).updateSettings(newSettings);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Terang'),
                value: 'light',
                groupValue: settings.tema,
                onChanged: (value) {
                  if (value != null) {
                    final newSettings = settings.copyWith(tema: value);
                    ref.read(pengaturanUmumProvider.notifier).updateSettings(newSettings);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Gelap'),
                value: 'dark',
                groupValue: settings.tema,
                onChanged: (value) {
                  if (value != null) {
                    final newSettings = settings.copyWith(tema: value);
                    ref.read(pengaturanUmumProvider.notifier).updateSettings(newSettings);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog(PengaturanUmum settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Bahasa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Bahasa Indonesia'),
                value: 'id',
                groupValue: settings.bahasa,
                onChanged: (value) {
                  if (value != null) {
                    final newSettings = settings.copyWith(bahasa: value);
                    ref.read(pengaturanUmumProvider.notifier).updateSettings(newSettings);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
                groupValue: settings.bahasa,
                onChanged: (value) {
                  if (value != null) {
                    final newSettings = settings.copyWith(bahasa: value);
                    ref.read(pengaturanUmumProvider.notifier).updateSettings(newSettings);
                    Navigator.of(context).pop();
                    _showSnackBar('Fitur bahasa Inggris akan segera hadir');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'OmsetPro',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.point_of_sale,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text('SuperApp UMKM Indonesia'),
        const SizedBox(height: 16),
        const Text(
          'OmsetPro membantu UMKM mengelola bisnis mereka dengan lebih efisien dan profesional.',
        ),
        const SizedBox(height: 16),
        const Text('© 2024 OmsetPro Team'),
      ],
    );
  }
}
