import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';
import '../../utils/role_guard.dart';
import 'tabs/anggota_tim_tab.dart';
import 'tabs/absensi_tab.dart';
import 'tabs/shift_jadwal_tab.dart';
import 'tabs/gaji_komisi_tab.dart';
import 'tabs/izin_cuti_tab.dart';
import 'tabs/aktivitas_log_tab.dart';

class TimPage extends ConsumerStatefulWidget {
  const TimPage({super.key});

  @override
  ConsumerState<TimPage> createState() => _TimPageState();
}

class _TimPageState extends ConsumerState<TimPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // === PROTEKSI ROLE: HANYA OWNER YANG BISA AKSES ===
    return RoleGuard.protect(
      allowedRoles: [Role.OWNER],
      ref: ref,
      child: _buildTimPage(context, ref),
    );
  }

  Widget _buildTimPage(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Tim & Karyawan'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Anggota Tim',
            ),
            Tab(
              icon: Icon(Icons.access_time),
              text: 'Absensi',
            ),
            Tab(
              icon: Icon(Icons.schedule),
              text: 'Shift & Jadwal',
            ),
            Tab(
              icon: Icon(Icons.attach_money),
              text: 'Gaji & Komisi',
            ),
            Tab(
              icon: Icon(Icons.event_busy),
              text: 'Izin & Cuti',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Aktivitas & Log',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AnggotaTimTab(),
          AbsensiTab(),
          ShiftJadwalTab(),
          GajiKomisiTab(),
          IzinCutiTab(),
          AktivitasLogTab(),
        ],
      ),
    );
  }
}
