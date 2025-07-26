import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart' as AppProviders;
import '../../../theme/app_theme.dart';
import './mobile_cart_widget.dart';
import './desktop_cart_widget.dart';

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
          sum +
          ((item['produk']['harga'] as num).toDouble() *
              (item['jumlah'] as num).toDouble()),
    );

    final isMobile = ResponsiveBreakpoints.isMobile(context);

    // Common clear cart function
    void clearCart(BuildContext context, WidgetRef ref) {
      ref.read(AppProviders.cartProvider.notifier).state = [];
    }

    if (isMobile) {
      return MobileCartWidget(
        cart: cart,
        selectedPelanggan: selectedPelanggan,
        totalHarga: totalHarga,
        onCashPayment: onCashPayment,
        onDigitalPayment: onDigitalPayment,
        onManualPayment: onManualPayment,
        onClearCart: clearCart,
      );
    }

    return DesktopCartWidget(
      cart: cart,
      selectedPelanggan: selectedPelanggan,
      totalHarga: totalHarga,
      onCashPayment: onCashPayment,
      onDigitalPayment: onDigitalPayment,
      onManualPayment: onManualPayment,
      onClearCart: clearCart,
    );
  }
}
