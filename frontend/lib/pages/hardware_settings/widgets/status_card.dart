import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final AsyncValue status;
  final Color statusColor;
  final String Function(dynamic) statusText;
  final dynamic connectedDevice;

  const StatusCard({
    super.key,
    required this.title,
    required this.icon,
    required this.status,
    required this.statusColor,
    required this.statusText,
    this.connectedDevice,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            status.when(
              data: (data) => Text(
                statusText(data),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              loading: () => const Text('Loading...'),
              error: (error, _) => Text('Error: $error'),
            ),
            if (connectedDevice != null) ...[
              const SizedBox(height: 8),
              Text(
                'Connected: ${connectedDevice.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
