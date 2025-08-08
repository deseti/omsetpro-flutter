import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/hardware_providers.dart';

class RecentScansCard extends ConsumerWidget {
  const RecentScansCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
  }
}
