import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';

class CartFloatingButtonWidget extends ConsumerWidget {
  final VoidCallback onTap;

  const CartFloatingButtonWidget({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: onTap,
      icon: const Icon(Icons.shopping_cart),
      label: Text('${ref.read(cartProvider.notifier).totalItems} Items'),
    );
  }
}
