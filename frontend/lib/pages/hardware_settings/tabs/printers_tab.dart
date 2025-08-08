import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/hardware_providers.dart';
import '../../../services/hardware/hardware_detection_service.dart';
import '../../../services/hardware/thermal_printer_service.dart';
import '../widgets/status_card.dart';
import '../widgets/device_card.dart';
import '../widgets/empty_state.dart';

class PrintersTab extends ConsumerWidget {
  final VoidCallback onRefresh;

  const PrintersTab({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printers = ref.watch(printersProvider);
    final printerStatus = ref.watch(printerStatusProvider);
    final connectedDevices = ref.watch(connectedDevicesProvider);

    return Column(
      children: [
        // Status Card
        StatusCard(
          title: 'Printer Status',
          icon: Icons.print,
          status: printerStatus,
          statusColor: _getPrinterStatusColor(printerStatus.value),
          statusText: _getPrinterStatusText,
          connectedDevice: connectedDevices[HardwareType.thermalPrinter],
        ),

        // Printers List
        Expanded(
          child: printers.isEmpty
              ? EmptyState(
                  message: 'No printers found',
                  icon: Icons.print,
                  onRefresh: onRefresh,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: printers.length,
                  itemBuilder: (context, index) => PrinterDeviceCard(
                    device: printers[index],
                    onTest: () => _testPrinter(ref, printers[index]),
                    onToggleConnection: () =>
                        _togglePrinterConnection(ref, printers[index]),
                  ),
                ),
        ),
      ],
    );
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

  String _getPrinterStatusText(dynamic status) {
    if (status is! PrinterStatus) return 'Unknown';
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

  Future<void> _togglePrinterConnection(
      WidgetRef ref, HardwareDevice device) async {
    final manager = ref.read(hardwareManagerProvider);
    if (device.isConnected) {
      await manager.disconnectDevice(HardwareType.thermalPrinter);
    } else {
      await manager.connectDevice(device.id);
    }
  }

  Future<void> _testPrinter(WidgetRef ref, HardwareDevice device) async {
    final manager = ref.read(hardwareManagerProvider);
    if (!device.isConnected) {
      await manager.connectDevice(device.id);
    }

    await manager.printerService.printTestPage();
  }
}
