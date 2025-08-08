import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/toko_online_model.dart';
import '../widgets/produk_card_widget.dart';
import '../providers/cart_provider.dart';

class ProdukGridWidget extends ConsumerWidget {
  final List<Produk> produkList;

  const ProdukGridWidget({
    super.key,
    required this.produkList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (produkList.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('Belum ada produk tersedia'),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: produkList.length,
          itemBuilder: (context, index) {
            return ProdukCardWidget(
              produk: produkList[index],
              onAddToCart: (produk) => _addToCart(ref, context, produk),
            );
          },
        ),
      ],
    );
  }

  void _addToCart(WidgetRef ref, BuildContext context, Produk produk) {
    ref.read(cartProvider.notifier).addToCart(produk, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${produk.nama} ditambahkan ke keranjang')),
    );
  }
}
