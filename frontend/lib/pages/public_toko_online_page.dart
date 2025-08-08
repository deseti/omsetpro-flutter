import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'public_toko_online/public_toko_online.dart';

class PublicTokoOnlinePage extends ConsumerStatefulWidget {
  final String slug;

  const PublicTokoOnlinePage({super.key, required this.slug});

  @override
  ConsumerState<PublicTokoOnlinePage> createState() =>
      _PublicTokoOnlinePageState();
}

class _PublicTokoOnlinePageState extends ConsumerState<PublicTokoOnlinePage> {
  @override
  Widget build(BuildContext context) {
    final tokoAsync = ref.watch(tokoDataProvider(widget.slug));

    return Scaffold(
      appBar: AppBar(
        title: tokoAsync.when(
          data: (toko) => Text(toko.nama),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          // Cart icon with badge
          CartBadgeWidget(
            onTap: () => _showCartDialog(context),
          ),
        ],
      ),
      body: tokoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(tokoDataProvider(widget.slug)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (toko) => _buildTokoContent(toko),
      ),
      floatingActionButton: CartFloatingButtonWidget(
        onTap: () => _showCartDialog(context),
      ),
    );
  }

  Widget _buildTokoContent(toko) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toko info
          TokoInfoWidget(toko: toko),
          const SizedBox(height: 24),

          // Delivery options
          DeliveryOptionsWidget(toko: toko),
          const SizedBox(height: 24),

          // Products
          ProdukGridWidget(produkList: toko.produk),
        ],
      ),
    );
  }

  void _showCartDialog(BuildContext context) {
    final cart = ref.read(cartProvider);
    final toko = ref.read(tokoDataProvider(widget.slug)).asData?.value;

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang kosong')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CheckoutBottomSheet(
        cart: cart,
        toko: toko!,
        onOrderPlaced: () {
          ref.read(cartProvider.notifier).clearCart();
          Navigator.pop(context);
        },
      ),
    );
  }
}
