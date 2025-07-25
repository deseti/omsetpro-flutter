import 'package:flutter/material.dart';
import '../../widgets/responsive_widgets.dart';
import '../../theme/app_theme.dart';
import 'dashboard_widgets.dart';

class ModernQuickActions extends StatelessWidget {
  final List<QuickActionItem> actions;
  final String title;

  const ModernQuickActions({
    super.key,
    required this.actions,
    this.title = 'Aksi Cepat',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        // Grid dengan spacing yang lebih app-like
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              crossAxisSpacing: isMobile ? 12 : 16,
              mainAxisSpacing: isMobile ? 12 : 16,
              childAspectRatio: isMobile ? 1.1 : 1.2,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return ModernActionButton(
                title: action.title,
                subtitle: action.subtitle,
                icon: action.icon,
                color: action.color,
                onTap: action.onTap,
                isExpanded: false,
              );
            },
          ),
        ),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 4;
    if (ResponsiveBreakpoints.isTablet(context)) return 3;
    return ResponsiveBreakpoints.isSmallMobile(context) ? 2 : 3;
  }
}

class ModernStatsGrid extends StatelessWidget {
  final List<StatsItem> stats;
  final String title;

  const ModernStatsGrid({
    super.key,
    required this.stats,
    this.title = 'Statistik',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          mobileColumns: ResponsiveBreakpoints.isSmallMobile(context) ? 1 : 2,
          tabletColumns: 2,
          desktopColumns: 4,
          spacing: AppTheme.spaceMD,
          runSpacing: AppTheme.spaceMD,
          children: stats.map((stat) {
            return ModernStatsCard(
              title: stat.title,
              value: stat.value,
              subtitle: stat.subtitle,
              icon: stat.icon,
              iconColor: stat.iconColor,
              trend: stat.trend,
              isPositiveTrend: stat.isPositiveTrend,
              onTap: stat.onTap,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ModernMenuGrid extends StatelessWidget {
  final List<MenuItem> menuItems;
  final String title;

  const ModernMenuGrid({
    super.key,
    required this.menuItems,
    this.title = 'Menu Utama',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          mobileColumns: ResponsiveBreakpoints.isSmallMobile(context) ? 1 : 2,
          tabletColumns: 2,
          desktopColumns: 3,
          spacing: AppTheme.spaceMD,
          runSpacing: AppTheme.spaceMD,
          children: menuItems.map((item) {
            return ModernDashboardCard(
              title: item.title,
              subtitle: item.subtitle,
              icon: item.icon,
              iconColor: item.iconColor,
              onTap: item.onTap,
              height: 80,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class QuickActionItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const QuickActionItem({
    required this.title,
    this.subtitle,
    required this.icon,
    this.color,
    this.onTap,
  });
}

class StatsItem {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final String? trend;
  final bool? isPositiveTrend;
  final VoidCallback? onTap;

  const StatsItem({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.trend,
    this.isPositiveTrend,
    this.onTap,
  });
}

class MenuItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const MenuItem({
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.onTap,
  });
}
