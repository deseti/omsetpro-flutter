// lib/pages/hardware_settings_page.dart
// Halaman pengaturan dan manajemen hardware POS

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hardware_providers.dart';
import 'hardware_settings/tabs/printers_tab.dart';
import 'hardware_settings/tabs/scanners_tab.dart';
import 'hardware_settings/tabs/cash_drawer_tab.dart';
import 'hardware_settings/tabs/settings_tab.dart';
import 'hardware_settings/dialogs/hardware_dialogs.dart';

class HardwareSettingsPage extends ConsumerStatefulWidget {
  const HardwareSettingsPage({super.key});

  @override
  ConsumerState<HardwareSettingsPage> createState() =>
      _HardwareSettingsPageState();
}

class _HardwareSettingsPageState extends ConsumerState<HardwareSettingsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize hardware manager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHardware();
    });
  }

  Future<void> _initializeHardware() async {
    final manager = ref.read(hardwareManagerProvider);
    if (!manager.isInitialized) {
      await manager.initialize();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware Settings'),
        actions: [
          IconButton(
            icon: _isScanning
                ? const CircularProgressIndicator()
                : const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _scanForDevices,
            tooltip: 'Scan for devices',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.print), text: 'Printers'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scanners'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Cash Drawer'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PrintersTab(onRefresh: _scanForDevices),
          ScannersTab(onRefresh: _scanForDevices),
          const CashDrawerTab(),
          SettingsTab(
            onExportConfiguration: _exportConfiguration,
            onShowHardwareInfo: _showHardwareInfo,
          ),
        ],
      ),
    );
  }

  Future<void> _scanForDevices() async {
    setState(() => _isScanning = true);
    try {
      final manager = ref.read(hardwareManagerProvider);
      await manager.scanForDevices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device scan completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _exportConfiguration() {
    final manager = ref.read(hardwareManagerProvider);
    manager.exportConfiguration();

    // Here you would typically save to file or share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration exported')),
    );
  }

  void _showHardwareInfo() {
    final manager = ref.read(hardwareManagerProvider);
    final status = manager.getHardwareStatus();

    HardwareDialogs.showHardwareInfo(context, status);
  }

  void _showHelpDialog() {
    HardwareDialogs.showHelpDialog(context);
  }
}
