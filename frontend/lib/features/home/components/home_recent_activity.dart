import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../providers/providers.dart';
import '../../../widgets/responsive_widgets.dart';
import '../../../theme/app_theme.dart';
import 'home_dialogs.dart';

class HomeRecentActivity extends ConsumerWidget {
  const HomeRecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final profile = ref.watch(userProfileProvider);
    final userRole =
        profile != null ? Role.values.byName(profile['role']) : null;

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
                onTap: () => HomeDialogs.showPilihCabangDialog(context, ref, mode: 'kasir'),
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
}
