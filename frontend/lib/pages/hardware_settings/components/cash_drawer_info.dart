import 'package:flutter/material.dart';

class CashDrawerInfo extends StatelessWidget {
  const CashDrawerInfo({super.key});

  @override
  Widget build(BuildContext context) {
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
            const Text('• RJ11/RJ12 to printer',
                style: TextStyle(fontSize: 12)),
            const Text('• Direct USB (with compatible models)',
                style: TextStyle(fontSize: 12)),
            const Text('• Network-enabled smart drawers',
                style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
