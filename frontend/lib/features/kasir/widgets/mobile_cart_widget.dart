import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart' as AppProviders;
import '../../../theme/app_theme.dart';
import './cart_item_widget.dart';
import './empty_cart_widget.dart';
import './payment_buttons_widget.dart';
import './cart_floating_buttons.dart';

class MobileCartWidget extends ConsumerWidget {
  final List<Map<String, dynamic>> cart;
  final selectedPelanggan;
  final double totalHarga;
  final VoidCallback? onCashPayment;
  final VoidCallback? onDigitalPayment;
  final Function(String)? onManualPayment;
  final Function(BuildContext, WidgetRef) onClearCart;

  const MobileCartWidget({
    super.key,
    required this.cart,
    required this.selectedPelanggan,
    required this.totalHarga,
    this.onCashPayment,
    this.onDigitalPayment,
    this.onManualPayment,
    required this.onClearCart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // Main cart content - simplified
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              // Header - Fixed
              _buildHeader(context),
              // Cart Items Only - scrollable
              Expanded(
                child: cart.isEmpty
                    ? const EmptyCartWidget()
                    : _buildCartItems(context, ref),
              ),
              // Payment Buttons - Fixed at bottom
              if (cart.isNotEmpty) _buildPaymentButtons(context),
            ],
          ),
        ),
        // Floating Action Buttons
        if (cart.isNotEmpty)
          CartFloatingButtons(
            selectedPelanggan: selectedPelanggan,
            totalHarga: totalHarga,
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
              onPressed: () => _showClearCartDialog(context),
              tooltip: 'Kosongkan keranjang',
            ),
        ],
      ),
    );
  }

  Widget _buildCartItems(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: cart.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              CartItemWidget(
                item: item,
                index: index,
                onQuantityChanged: (index, newQuantity) {
                  final updatedCart = [...cart];
                  updatedCart[index] = {
                    ...updatedCart[index],
                    'jumlah': newQuantity,
                  };
                  ref.read(AppProviders.cartProvider.notifier).state =
                      updatedCart;
                },
              ),
              if (index < cart.length - 1) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentButtons(BuildContext context) {
    return Container(
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
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer(
          builder: (context, ref, child) {
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
                    Navigator.of(context).pop();
                    onClearCart(context, ref);
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
      },
    );
  }
}
