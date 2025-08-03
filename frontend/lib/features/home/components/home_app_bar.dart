import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/providers.dart';

class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
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
          onSelected: (value) => _handleMenuSelection(context, ref, value, profile),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _handleMenuSelection(
    BuildContext context,
    WidgetRef ref,
    String value,
    Map<String, dynamic>? profile,
  ) {
    switch (value) {
      case 'profile':
        Navigator.of(context).pushNamed('/profil');
        break;
      case 'settings':
        if (profile != null) {
          Navigator.of(context).pushNamed('/pengaturan-akun');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile tidak ditemukan'),
            ),
          );
        }
        break;
      case 'logout':
        _handleLogout(context, ref);
        break;
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    ref.read(userProfileProvider.notifier).state = null;
    ref.read(accessTokenProvider.notifier).state = null;
    ref.read(authStateProvider.notifier).state = false;
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }
}
