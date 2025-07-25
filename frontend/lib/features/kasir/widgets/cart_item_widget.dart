import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/responsive_widgets.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/currency_formatter.dart';

class CartItemWidget extends ConsumerWidget {
  final Map<String, dynamic> item;
  final int index;
  final Function(int index, int newQuantity) onQuantityChanged;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveCard(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Row(
        children: [
          _buildProductInfo(context),
          _buildQuantityControls(context),
        ],
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['produk']['nama'],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            CurrencyFormatter.formatCurrency(item['produk']['harga']),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => onQuantityChanged(index, item['jumlah'] - 1),
          icon: const Icon(Icons.remove_circle_outline),
          color: Theme.of(context).colorScheme.error,
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 40),
          child: Text(
            '${item['jumlah']}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          onPressed: () => onQuantityChanged(index, item['jumlah'] + 1),
          icon: const Icon(Icons.add_circle_outline),
          color: Theme.of(context).colorScheme.secondary,
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
          ),
        ),
      ],
    );
  }
}
