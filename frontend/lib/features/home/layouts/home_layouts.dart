import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../widgets/responsive_widgets.dart';
import '../components/home_app_bar.dart';
import '../components/home_content.dart';
import '../components/home_sidebar.dart';

class HomeLayouts {
  static Widget buildMobileLayout(BuildContext context) {
    return const Scaffold(
      appBar: HomeAppBar(),
      body: HomeContent(),
    );
  }

  static Widget buildTabletLayout(BuildContext context) {
    return const Scaffold(
      appBar: HomeAppBar(),
      body: HomeContent(),
    );
  }

  static Widget buildDesktopLayout(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      body: Row(
        children: [
          // Sidebar untuk desktop
          Container(
            width: 280,
            color: Theme.of(context).colorScheme.surface,
            child: const HomeSidebar(),
          ),
          const VerticalDivider(width: 1),
          // Main content
          const Expanded(
            child: HomeContent(),
          ),
        ],
      ),
    );
  }
}
