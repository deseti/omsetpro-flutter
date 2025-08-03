import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../widgets/responsive_widgets.dart';
import '../../../theme/app_theme.dart';
import 'home_welcome_section.dart';
import 'home_quick_stats.dart';
import 'home_recent_activity.dart';

class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const HomeWelcomeSection(),
              SizedBox(height: isMobile ? 20 : 24),
            ],

            // Quick Stats - Lebih compact
            const HomeQuickStats(),
            SizedBox(height: isMobile ? 20 : 24),

            // Recent Activity atau Quick Info
            const HomeRecentActivity(),
            SizedBox(
                height:
                    isMobile ? 100 : 24), // Extra bottom space untuk bottom nav
          ],
        ),
      ),
    );
  }
}
