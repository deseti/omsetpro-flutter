import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../providers/providers.dart';
import 'home_dialogs.dart';
import 'home_welcome_section.dart';

class HomeSidebar extends ConsumerWidget {
  const HomeSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final userRole =
        profile != null ? Role.values.byName(profile['role']) : null;

    return Column(
      children: [
        const SizedBox(height: 20),
        const HomeWelcomeSection(),
        const SizedBox(height: 32),
        Expanded(
          child: _buildNavigationMenu(context, ref, userRole),
        ),
      ],
    );
  }

  Widget _buildNavigationMenu(BuildContext context, WidgetRef ref, Role? userRole) {
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
            _handleProdukAction(context, ref);
          }),
          _buildNavItem(context, Icons.analytics, 'Laporan', () {
            print('DEBUG: Sidebar - Navigating to /insights');
            Navigator.of(context).pushNamed('/insights');
          }),
        ],
        _buildNavItem(context, Icons.point_of_sale, 'Kasir', () {
          print('DEBUG: Sidebar - Navigating to kasir');
          _handleKasirAction(context, ref);
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

  void _handleKasirAction(BuildContext context, WidgetRef ref) {
    final cabangList = ref.read(cabangListProvider);
    if (cabangList.isNotEmpty) {
      HomeDialogs.showPilihCabangDialog(context, ref, mode: 'kasir');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda belum punya cabang. Silakan buat dulu.'),
        ),
      );
    }
  }

  void _handleProdukAction(BuildContext context, WidgetRef ref) {
    final cabangList = ref.read(cabangListProvider);
    if (cabangList.isNotEmpty) {
      HomeDialogs.showPilihCabangDialog(context, ref, mode: 'produk');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda belum punya cabang. Silakan buat dulu.'),
        ),
      );
    }
  }
}
