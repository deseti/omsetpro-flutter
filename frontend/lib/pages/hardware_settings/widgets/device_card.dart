import 'package:flutter/material.dart';
import '../../../services/hardware/hardware_detection_service.dart';

class PrinterDeviceCard extends StatelessWidget {
  final HardwareDevice device;
  final VoidCallback onTest;
  final VoidCallback onToggleConnection;

  const PrinterDeviceCard({
    super.key,
    required this.device,
    required this.onTest,
    required this.onToggleConnection,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(
                '${device.manufacturer} • ${device.connectionType.toString().split('.').last.toUpperCase()}'),
            Text('Address: ${device.address}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: onTest,
              tooltip: 'Test Print',
            ),
            IconButton(
              icon: Icon(device.isConnected ? Icons.link_off : Icons.link),
              onPressed: onToggleConnection,
              tooltip: device.isConnected ? 'Disconnect' : 'Connect',
            ),
          ],
        ),
        isThreeLine: true,
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
}

class ScannerDeviceCard extends StatelessWidget {
  final HardwareDevice device;
  final VoidCallback onTest;
  final VoidCallback onToggleConnection;

  const ScannerDeviceCard({
    super.key,
    required this.device,
    required this.onTest,
    required this.onToggleConnection,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(
                '${device.manufacturer} • ${device.connectionType.toString().split('.').last.toUpperCase()}'),
            Text('Address: ${device.address}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: onTest,
              tooltip: 'Test Scanner',
            ),
            IconButton(
              icon: Icon(device.isConnected ? Icons.link_off : Icons.link),
              onPressed: onToggleConnection,
              tooltip: device.isConnected ? 'Disconnect' : 'Connect',
            ),
          ],
        ),
        isThreeLine: true,
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
}
