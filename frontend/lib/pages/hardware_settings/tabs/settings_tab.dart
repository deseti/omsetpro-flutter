import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/hardware_providers.dart';

class SettingsTab extends ConsumerWidget {
  final VoidCallback onExportConfiguration;
  final VoidCallback onShowHardwareInfo;

  const SettingsTab({
    super.key,
    required this.onExportConfiguration,
    required this.onShowHardwareInfo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Text(
                    'Cash Drawer: ${hardwareStatus['cashDrawer']['available'] ? 'Available' : 'Not Available'}'),
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
                subtitle: const Text(
                    'Automatically connect to saved devices on startup'),
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
                subtitle:
                    const Text('Export hardware settings and device list'),
                onTap: onExportConfiguration,
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Hardware Info'),
                subtitle: const Text('View detailed hardware information'),
                onTap: onShowHardwareInfo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
