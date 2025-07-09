import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class KasirPage extends ConsumerWidget {
  final int cabangId;
  final String cabangNama;

  const KasirPage({
    Key? key,
    required this.cabangId,
    required this.cabangNama,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final totalHarga = cart.fold<double>(0, (sum, item) {
      return sum + (item['produk']['harga'] * item['jumlah']);
    }).toInt();

    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir di $cabangNama'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(produkListFutureProvider(cabangId));
                ref.read(cartProvider.notifier).state = [];
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: Consumer(
                builder: (context, ref, _) {
                  final produkAsync = ref.watch(produkListFutureProvider(cabangId));
                  return produkAsync.when(
                    data: (produkList) => GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 3 / 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: produkList.length,
                      itemBuilder: (context, index) {
                        final produk = produkList[index];
                        return _buildProdukCard(context, ref, produk);
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  );
                },
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 1,
            child: _buildCartView(context, ref, cart, totalHarga, cabangId),
          ),
        ],
      ),
    );
  }

  Widget _buildProdukCard(BuildContext context, WidgetRef ref, dynamic produk) {
    return InkWell(
      onTap: () {
        final cartNotifier = ref.read(cartProvider.notifier);
        final currentCart = cartNotifier.state;
        final existingItemIndex = currentCart.indexWhere((item) => item['produk']['id'] == produk['id']);

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
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: produk['fotoUrl'] != null
                  ? Image.network(
                      produk['fotoUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.inventory_2, size: 50, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                produk['nama'],
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(bottom: 8.0),
              child: Text('Rp ${produk['harga']}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartView(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> cart, int totalHarga, int cabangId) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Keranjang', style: Theme.of(context).textTheme.headlineSmall),
          const Divider(),
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text('Keranjang kosong'))
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return ListTile(
                        title: Text(item['produk']['nama']),
                        subtitle: Text('Rp ${item['produk']['harga']}'),
                        trailing: Text('x ${item['jumlah']}'),
                      );
                    },
                  ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleLarge),
              Text('Rp $totalHarga', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: cart.isEmpty ? null : () async {
              try {
                final dio = ref.read(dioProvider);
                final itemsDto = cart.map((item) => {
                  'produkId': item['produk']['id'],
                  'jumlah': item['jumlah'],
                }).toList();

                await dio.post('/transaksi', data: {
                  'cabangId': cabangId,
                  'metodeBayar': 'Tunai',
                  'items': itemsDto,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaksi berhasil!'), backgroundColor: Colors.green),
                );
                ref.invalidate(produkListFutureProvider(cabangId));
                ref.read(cartProvider.notifier).state = [];
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaksi gagal!'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
            ),
            child: const Text('Bayar (Tunai)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}