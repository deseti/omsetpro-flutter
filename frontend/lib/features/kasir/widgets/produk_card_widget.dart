import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/responsive_widgets.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/currency_formatter.dart';
import '../services/cart_helper.dart';

class ProdukCardWidget extends ConsumerWidget {
  final dynamic produk;

  const ProdukCardWidget({
    super.key,
    required this.produk,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveCard(
      onTap: () => _addToCart(ref),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProductImage(context),
          _buildProductInfo(context),
        ],
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusMD),
          ),
        ),
        child: produk['fotoUrl'] != null
            ? ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMD),
                ),
                child: Image.network(
                  produk['fotoUrl'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    );
                  },
                ),
              )
            : Icon(
                Icons.inventory_2,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Name
            Flexible(
              child: Text(
                produk['nama'] ?? 'Produk',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Product Price
            Text(
              CurrencyFormatter.formatCurrency(produk['harga']),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(WidgetRef ref) {
    print('🛒 Adding product to cart: ${produk['nama']} (ID: ${produk['id']})');
    try {
      CartHelper.addOrUpdateItem(ref, produk);
      print('✅ Successfully added to cart');
    } catch (e) {
      print('❌ Error adding to cart: $e');
    }
  }
}
