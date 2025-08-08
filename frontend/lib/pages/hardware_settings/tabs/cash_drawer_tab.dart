import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/hardware_providers.dart';
import '../components/cash_drawer_info.dart';

class CashDrawerTab extends ConsumerWidget {
  const CashDrawerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    isPrinterConnected
                        ? 'Available via printer'
                        : 'Requires printer connection',
                    style: TextStyle(
                      color: isPrinterConnected ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isPrinterConnected
                          ? () => _openCashDrawer(ref, context)
                          : null,
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('Open Cash Drawer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const CashDrawerInfo(),
        ],
      ),
    );
  }

  Future<void> _openCashDrawer(WidgetRef ref, BuildContext context) async {
    final manager = ref.read(hardwareManagerProvider);
    final result = await manager.openCashDrawer();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
