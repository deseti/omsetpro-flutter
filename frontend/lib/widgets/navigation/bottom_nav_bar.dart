import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Role? userRole;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Items yang selalu ada untuk semua role
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded),
        label: 'Beranda',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.point_of_sale_rounded),
        label: 'Kasir',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_rounded),
        label: 'Produk',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_rounded),
        label: 'Pelanggan',
      ),
    ];

    // Tambahkan item khusus untuk OWNER
    if (userRole == Role.OWNER) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz_rounded),
          label: 'Lainnya',
        ),
      );
    } else {
      // Untuk ADMIN/KASIR, ganti dengan Laporan
      if (userRole == Role.ADMIN) {
        items.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Laporan',
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.surface,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurfaceVariant,
          selectedLabelStyle: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: items,
          elevation: 0,
        ),
      ),
    );
  }
}
