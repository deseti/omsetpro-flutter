import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/toko_online_model.dart';

// Provider untuk shopping cart
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Produk produk, int quantity) {
    final existingIndex =
        state.indexWhere((item) => item.produk.id == produk.id);

    if (existingIndex >= 0) {
      // Update quantity if item already in cart
      final updatedCart = [...state];
      updatedCart[existingIndex] = CartItem(
        produk: produk,
        jumlah: updatedCart[existingIndex].jumlah + quantity,
      );
      state = updatedCart;
    } else {
      // Add new item to cart
      state = [...state, CartItem(produk: produk, jumlah: quantity)];
    }
  }

  void updateQuantity(int produkId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(produkId);
      return;
    }

    state = state.map((item) {
      if (item.produk.id == produkId) {
        item.jumlah = newQuantity;
      }
      return item;
    }).toList();
  }

  void removeFromCart(int produkId) {
    state = state.where((item) => item.produk.id != produkId).toList();
  }

  void clearCart() {
    state = [];
  }

  int get totalItems => state.fold(0, (sum, item) => sum + item.jumlah);

  int get totalPrice => state.fold(0, (sum, item) => sum + item.subtotal);
}
