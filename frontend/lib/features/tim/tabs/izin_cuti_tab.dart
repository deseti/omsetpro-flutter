import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'izin_cuti/widgets/daftar_izin_tab.dart';
import 'izin_cuti/widgets/statistik_tab.dart';

class IzinCutiTab extends ConsumerStatefulWidget {
  const IzinCutiTab({super.key});

  @override
  ConsumerState<IzinCutiTab> createState() => _IzinCutiTabState();
}

class _IzinCutiTabState extends ConsumerState<IzinCutiTab>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Daftar Izin'),
            Tab(icon: Icon(Icons.assessment), text: 'Statistik'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              DaftarIzinTab(),
              StatistikTab(),
            ],
          ),
        ),
      ],
    );
  }
}
