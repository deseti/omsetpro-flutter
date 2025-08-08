import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/hardware_providers.dart';
import '../../../services/hardware/hardware_detection_service.dart';
import '../widgets/status_card.dart';
import '../widgets/device_card.dart';
import '../widgets/empty_state.dart';
import '../components/recent_scans_card.dart';

class ScannersTab extends ConsumerWidget {
  final VoidCallback onRefresh;

  const ScannersTab({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanners = ref.watch(scannersProvider);
    final scannerStatus = ref.watch(scannerStatusProvider);
    final connectedDevices = ref.watch(connectedDevicesProvider);

    return Column(
      children: [
        // Status Card
        StatusCard(
          title: 'Scanner Status',
          icon: Icons.qr_code_scanner,
          status: scannerStatus,
          statusColor: _getScannerStatusColor(scannerStatus.value),
          statusText: _getScannerStatusText,
          connectedDevice: connectedDevices[HardwareType.barcodeScanner],
        ),

        // Recent Scans
        const RecentScansCard(),

        // Scanners List
        Expanded(
          child: scanners.isEmpty
              ? EmptyState(
                  message: 'No scanners found',
                  icon: Icons.qr_code_scanner,
                  onRefresh: onRefresh,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: scanners.length,
                  itemBuilder: (context, index) => ScannerDeviceCard(
                    device: scanners[index],
                    onTest: () => _testScanner(ref, scanners[index]),
                    onToggleConnection: () =>
                        _toggleScannerConnection(ref, scanners[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Color _getScannerStatusColor(dynamic status) {
    // Implement based on your ScannerStatus enum
    return Colors.grey; // Default implementation
  }

  String _getScannerStatusText(dynamic status) {
    // Implement based on your ScannerStatus enum
    return 'Unknown'; // Default implementation
  }

  Future<void> _toggleScannerConnection(
      WidgetRef ref, HardwareDevice device) async {
    final manager = ref.read(hardwareManagerProvider);
    if (device.isConnected) {
      await manager.disconnectDevice(HardwareType.barcodeScanner);
    } else {
      await manager.connectDevice(device.id);
    }
  }

  Future<void> _testScanner(WidgetRef ref, HardwareDevice device) async {
    final manager = ref.read(hardwareManagerProvider);
    if (!device.isConnected) {
      await manager.connectDevice(device.id);
    }

    await manager.scannerService.testScanner();
  }
}
