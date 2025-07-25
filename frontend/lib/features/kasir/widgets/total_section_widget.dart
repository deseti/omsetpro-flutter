import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart' as AppProviders;
import '../../../utils/currency_formatter.dart';

class TotalSectionWidget extends ConsumerWidget {
  final int totalAkhir;

  const TotalSectionWidget({
    super.key,
    required this.totalAkhir,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartTotalInfo = ref.watch(AppProviders.cartTotalWithPromoProvider);
    final subtotal = cartTotalInfo['subtotal'];
    final totalDiskon = cartTotalInfo['totalDiskon'];
    final namaPromo = cartTotalInfo['namaPromo'];

    return Column(
      children: [
        if (totalDiskon > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text(
                  'Rp ${CurrencyFormatter.formatCurrency(subtotal).substring(3)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Diskon ($namaPromo):',
                  style: const TextStyle(color: Colors.green)),
              Text('-Rp $totalDiskon',
                  style: const TextStyle(color: Colors.green)),
            ],
          ),
          const Divider(),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: Theme.of(context).textTheme.titleLarge),
            Text('Rp $totalAkhir',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
