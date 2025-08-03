import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';
import '../../widgets/responsive_widgets.dart';
import 'services/home_data_service.dart';
import 'layouts/home_layouts.dart';

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
      HomeDataService.fetchInitialData(ref, mounted);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: HomeLayouts.buildMobileLayout(context),
        tablet: HomeLayouts.buildTabletLayout(context),
        desktop: HomeLayouts.buildDesktopLayout(context),
      ),
    );
  }
}
