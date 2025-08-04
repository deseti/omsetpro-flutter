// lib/pages/hardware_settings_page.dart
// Halaman pengaturan dan manajemen hardware POS

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hardware_providers.dart';
import '../services/hardware/hardware_detection_service.dart';
import '../services/hardware/thermal_printer_service.dart';
import '../services/hardware/barcode_scanner_service.dart';
import '../theme/app_theme.dart';

class HardwareSettingsPage extends ConsumerStatefulWidget {
  const HardwareSettingsPage({super.key});

  @override
  ConsumerState<HardwareSettingsPage> createState() => _HardwareSettingsPageState();
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
            icon: _isScanning ? const CircularProgressIndicator() : const Icon(Icons.refresh),
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
          _buildPrintersTab(),
          _buildScannersTab(),
          _buildCashDrawerTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildPrintersTab() {
    return Consumer(
      builder: (context, ref, child) {
        final printers = ref.watch(printersProvider);
        final printerStatus = ref.watch(printerStatusProvider);
        final connectedDevices = ref.watch(connectedDevicesProvider);

        return Column(
          children: [
            // Status Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.print,
                          color: _getPrinterStatusColor(printerStatus.value),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Printer Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    printerStatus.when(
                      data: (status) => Text(
                        _getPrinterStatusText(status),
                        style: TextStyle(
                          color: _getPrinterStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const Text('Loading...'),
                      error: (error, _) => Text('Error: $error'),
                    ),
                    if (connectedDevices[HardwareType.thermalPrinter] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Connected: ${connectedDevices[HardwareType.thermalPrinter]!.name}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Printers List
            Expanded(
              child: printers.isEmpty
                  ? _buildEmptyState('No printers found', Icons.print)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: printers.length,
                      itemBuilder: (context, index) => _buildPrinterCard(printers[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScannersTab() {
    return Consumer(
      builder: (context, ref, child) {
        final scanners = ref.watch(scannersProvider);
        final scannerStatus = ref.watch(scannerStatusProvider);
        final connectedDevices = ref.watch(connectedDevicesProvider);

        return Column(
          children: [
            // Status Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: _getScannerStatusColor(scannerStatus.value),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Scanner Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    scannerStatus.when(
                      data: (status) => Text(
                        _getScannerStatusText(status),
                        style: TextStyle(
                          color: _getScannerStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const Text('Loading...'),
                      error: (error, _) => Text('Error: $error'),
                    ),
                    if (connectedDevices[HardwareType.barcodeScanner] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Connected: ${connectedDevices[HardwareType.barcodeScanner]!.name}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Recent Scans
            _buildRecentScansCard(),
            
            // Scanners List
            Expanded(
              child: scanners.isEmpty
                  ? _buildEmptyState('No scanners found', Icons.qr_code_scanner)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: scanners.length,
                      itemBuilder: (context, index) => _buildScannerCard(scanners[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCashDrawerTab() {
    return Consumer(
      builder: (context, ref, child) {
        final isPrinterConnected = ref.watch(isPrinterConnectedProvider);
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: isPrinterConnected ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cash Drawer',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPrinterConnected ? 'Available via printer' : 'Requires printer connection',
                        style: TextStyle(
                          color: isPrinterConnected ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isPrinterConnected ? _openCashDrawer : null,
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Open Cash Drawer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildCashDrawerInfo(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final hardwareStatus = ref.watch(hardwareStatusProvider);
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hardware Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Total Devices: ${hardwareStatus['totalDevices']}'),
                    Text('Printer: ${hardwareStatus['printer']['status']}'),
                    Text('Scanner: ${hardwareStatus['scanner']['status']}'),
                    Text('Cash Drawer: ${hardwareStatus['cashDrawer']['available'] ? 'Available' : 'Not Available'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.auto_mode),
                    title: const Text('Auto-connect devices'),
                    subtitle: const Text('Automatically connect to saved devices on startup'),
                    trailing: Switch(
                      value: true, // This should be from shared preferences
                      onChanged: (value) {
                        // Implement auto-connect setting
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Hardware notifications'),
                    subtitle: const Text('Show notifications for hardware events'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // Implement notification setting
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Export Configuration'),
                    subtitle: const Text('Export hardware settings and device list'),
                    onTap: _exportConfiguration,
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Hardware Info'),
                    subtitle: const Text('View detailed hardware information'),
                    onTap: _showHardwareInfo,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrinterCard(HardwareDevice device) {
    return Card(
      child: ListTile(
        leading: Icon(
          _getConnectionIcon(device.connectionType),
          color: device.isConnected ? Colors.green : Colors.grey,
        ),
        title: Text(device.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${device.manufacturer} • ${device.connectionType.toString().split('.').last.toUpperCase()}'),
            Text('Address: ${device.address}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => _testPrinter(device),
              tooltip: 'Test Print',
            ),
            IconButton(
              icon: Icon(device.isConnected ? Icons.link_off : Icons.link),
              onPressed: () => _togglePrinterConnection(device),
              tooltip: device.isConnected ? 'Disconnect' : 'Connect',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildScannerCard(HardwareDevice device) {
    return Card(
      child: ListTile(
        leading: Icon(
          _getConnectionIcon(device.connectionType),
          color: device.isConnected ? Colors.green : Colors.grey,
        ),
        title: Text(device.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${device.manufacturer} • ${device.connectionType.toString().split('.').last.toUpperCase()}'),
            Text('Address: ${device.address}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _testScanner(device),
              tooltip: 'Test Scanner',
            ),
            IconButton(
              icon: Icon(device.isConnected ? Icons.link_off : Icons.link),
              onPressed: () => _toggleScannerConnection(device),
              tooltip: device.isConnected ? 'Disconnect' : 'Connect',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildRecentScansCard() {
    return Consumer(
      builder: (context, ref, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Scans',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                // Listen to barcode stream and show recent scans
                ref.watch(barcodeStreamProvider).when(
                  data: (barcode) => Text(
                    'Last: ${barcode.data} (${barcode.symbology})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  loading: () => const Text('Waiting for scan...'),
                  error: (error, _) => Text('Scanner error: $error'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCashDrawerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cash Drawer Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cash drawers are typically controlled through thermal printers using ESC/POS commands. '
              'Ensure your cash drawer is properly connected to your thermal printer.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supported connections:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const Text('• RJ11/RJ12 to printer', style: TextStyle(fontSize: 12)),
            const Text('• Direct USB (with compatible models)', style: TextStyle(fontSize: 12)),
            const Text('• Network-enabled smart drawers', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _scanForDevices,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan for Devices'),
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

  Future<void> _togglePrinterConnection(HardwareDevice device) async {
    final manager = ref.read(hardwareManagerProvider);
    if (device.isConnected) {
      await manager.disconnectDevice(HardwareType.thermalPrinter);
    } else {
      await manager.connectDevice(device.id);
    }
  }

  Future<void> _toggleScannerConnection(HardwareDevice device) async {
    final manager = ref.read(hardwareManagerProvider);
    if (device.isConnected) {
      await manager.disconnectDevice(HardwareType.barcodeScanner);
    } else {
      await manager.connectDevice(device.id);
    }
  }

  Future<void> _testPrinter(HardwareDevice device) async {
    final manager = ref.read(hardwareManagerProvider);
    if (!device.isConnected) {
      await manager.connectDevice(device.id);
    }
    
    final result = await manager.printerService.printTestPage();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _testScanner(HardwareDevice device) async {
    final manager = ref.read(hardwareManagerProvider);
    if (!device.isConnected) {
      await manager.connectDevice(device.id);
    }
    
    final result = await manager.scannerService.testScanner();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Scanner test successful' : 'Scanner test failed'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _openCashDrawer() async {
    final manager = ref.read(hardwareManagerProvider);
    final result = await manager.openCashDrawer();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _testAllHardware() async {
    final manager = ref.read(hardwareManagerProvider);
    final results = await manager.testAllHardware();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hardware Test Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: results.entries.map((entry) {
              return ListTile(
                leading: Icon(
                  entry.value ? Icons.check_circle : Icons.error,
                  color: entry.value ? Colors.green : Colors.red,
                ),
                title: Text(entry.key.toString().split('.').last),
                subtitle: Text(entry.value ? 'Pass' : 'Fail'),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _exportConfiguration() {
    final manager = ref.read(hardwareManagerProvider);
    final config = manager.exportConfiguration();
    
    // Here you would typically save to file or share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration exported')),
    );
  }

  void _showHardwareInfo() {
    final manager = ref.read(hardwareManagerProvider);
    final status = manager.getHardwareStatus();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hardware Information'),
        content: SingleChildScrollView(
          child: Text(status.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hardware Setup Help'),
        content: const SingleChildScrollView(
          child: Text(
            'Hardware Setup Guide:\n\n'
            '1. Thermal Printers:\n'
            '   • Connect via USB, Bluetooth, or WiFi\n'
            '   • Supported: Epson, Star, Citizen, Bixolon, Sunmi\n'
            '   • Test print to verify functionality\n\n'
            '2. Barcode Scanners:\n'
            '   • USB HID scanners work automatically\n'
            '   • Bluetooth scanners need pairing first\n'
            '   • Test scan to verify functionality\n\n'
            '3. Cash Drawers:\n'
            '   • Connect to thermal printer (RJ11/RJ12)\n'
            '   • Opens automatically with printer commands\n\n'
            'For technical support, contact OmsetPro team.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getConnectionIcon(ConnectionType type) {
    switch (type) {
      case ConnectionType.usb:
        return Icons.usb;
      case ConnectionType.bluetooth:
        return Icons.bluetooth;
      case ConnectionType.wifi:
      case ConnectionType.ethernet:
        return Icons.wifi;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getPrinterStatusColor(PrinterStatus? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case PrinterStatus.connected:
      case PrinterStatus.printing:
        return Colors.green;
      case PrinterStatus.connecting:
        return Colors.orange;
      case PrinterStatus.error:
      case PrinterStatus.paperOut:
      case PrinterStatus.coverOpen:
        return Colors.red;
      case PrinterStatus.disconnected:
        return Colors.grey;
    }
  }

  Color _getScannerStatusColor(ScannerStatus? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case ScannerStatus.connected:
      case ScannerStatus.scanning:
        return Colors.green;
      case ScannerStatus.connecting:
        return Colors.orange;
      case ScannerStatus.error:
        return Colors.red;
      case ScannerStatus.disconnected:
        return Colors.grey;
    }
  }

  String _getPrinterStatusText(PrinterStatus status) {
    switch (status) {
      case PrinterStatus.disconnected:
        return 'Disconnected';
      case PrinterStatus.connecting:
        return 'Connecting...';
      case PrinterStatus.connected:
        return 'Connected';
      case PrinterStatus.printing:
        return 'Printing...';
      case PrinterStatus.error:
        return 'Error';
      case PrinterStatus.paperOut:
        return 'Paper Out';
      case PrinterStatus.coverOpen:
        return 'Cover Open';
    }
  }

  String _getScannerStatusText(ScannerStatus status) {
    switch (status) {
      case ScannerStatus.disconnected:
        return 'Disconnected';
      case ScannerStatus.connecting:
        return 'Connecting...';
      case ScannerStatus.connected:
        return 'Connected';
      case ScannerStatus.scanning:
        return 'Ready to Scan';
      case ScannerStatus.error:
        return 'Error';
    }
  }
}
