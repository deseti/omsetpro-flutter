import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart' as AppProviders;
import '../../../widgets/responsive_widgets.dart';
import '../../../theme/app_theme.dart';
import './cart_item_widget.dart';
import './empty_cart_widget.dart';
import './pelanggan_info_widget.dart';
import './promo_section_widget.dart';
import './total_section_widget.dart';
import './payment_buttons_widget.dart';

class CartSectionWidget extends ConsumerWidget {
  final VoidCallback? onCashPayment;
  final VoidCallback? onDigitalPayment;
  final Function(String)? onManualPayment;

  const CartSectionWidget({
    super.key,
    this.onCashPayment,
    this.onDigitalPayment,
    this.onManualPayment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(AppProviders.cartProvider);
    final selectedPelanggan = ref.watch(AppProviders.selectedPelangganProvider);

    // Calculate totals
    final totalHarga = cart.fold<double>(
      0.0,
      (sum, item) =>
          sum + ((item['harga'] as double) * (item['quantity'] as int)),
    );

    return ResponsiveContainer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMD),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppTheme.spaceSM),
                Text(
                  'Keranjang (${cart.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (cart.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _showClearCartDialog(context, ref),
                    tooltip: 'Kosongkan keranjang',
                  ),
              ],
            ),
          ),
          // Cart Content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 0.5,
                  ),
                ),
              ),
              child: cart.isEmpty
                  ? const EmptyCartWidget()
                  : Column(
                      children: [
                        // Customer Info
                        PelangganInfoWidget(pelanggan: selectedPelanggan),
                        const Divider(height: 1),
                        // Cart Items
                        Expanded(
                          child: ListView.separated(
                            itemCount: cart.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) => CartItemWidget(
                              item: cart[index],
                              index: index,
                              onQuantityChanged: (index, newQuantity) {
                                final updatedCart = [...cart];
                                updatedCart[index] = {
                                  ...updatedCart[index],
                                  'quantity': newQuantity,
                                };
                                ref
                                    .read(AppProviders.cartProvider.notifier)
                                    .state = updatedCart;
                              },
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        // Promo Section
                        const PromoSectionWidget(),
                        const Divider(height: 1),
                        // Total Section
                        TotalSectionWidget(totalAkhir: totalHarga.toInt()),
                      ],
                    ),
            ),
          ),
          // Payment Buttons
          if (cart.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radiusMD),
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 0.5,
                ),
              ),
              child: PaymentButtonsWidget(
                cart: cart,
                totalHarga: totalHarga.toInt(),
                onCashPayment: onCashPayment ?? () {},
                onDigitalPayment: onDigitalPayment ?? () {},
                onManualPayment: onManualPayment ?? (type) {},
              ),
            ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kosongkan Keranjang'),
          content: const Text(
              'Apakah Anda yakin ingin menghapus semua item dari keranjang?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(AppProviders.cartProvider.notifier).state = [];
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Hapus Semua'),
            ),
          ],
        );
      },
    );
  }
}
