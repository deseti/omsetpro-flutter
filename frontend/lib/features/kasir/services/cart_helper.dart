import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart' as AppProviders;

class CartHelper {
  static void updateItemQuantity(WidgetRef ref, int index, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(ref, index);
      return;
    }

    final currentCart = ref.read(AppProviders.cartProvider);
    final updatedCart = List<Map<String, dynamic>>.from(currentCart);
    updatedCart[index]['jumlah'] = newQuantity;
    ref.read(AppProviders.cartProvider.notifier).state = updatedCart;
  }

  static void removeItem(WidgetRef ref, int index) {
    final currentCart = ref.read(AppProviders.cartProvider);
    final updatedCart = List<Map<String, dynamic>>.from(currentCart);
    updatedCart.removeAt(index);
    ref.read(AppProviders.cartProvider.notifier).state = updatedCart;
  }

  static void clearCart(WidgetRef ref) {
    ref.read(AppProviders.cartProvider.notifier).state = [];
  }

  static void addOrUpdateItem(WidgetRef ref, dynamic produk) {
    final cartNotifier = ref.read(AppProviders.cartProvider.notifier);
    final currentCart = cartNotifier.state;
    final existingItemIndex =
        currentCart.indexWhere((item) => item['produk']['id'] == produk['id']);

    if (existingItemIndex != -1) {
      final updatedItem = {
        ...currentCart[existingItemIndex],
        'jumlah': currentCart[existingItemIndex]['jumlah'] + 1,
      };
      final newCart = List<Map<String, dynamic>>.from(currentCart);
      newCart[existingItemIndex] = updatedItem;
      cartNotifier.state = newCart;
    } else {
      cartNotifier.state = [
        ...currentCart,
        {'produk': produk, 'jumlah': 1}
      ];
    }
  }
}
