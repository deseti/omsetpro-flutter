import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class KasirPage extends ConsumerStatefulWidget {
  final int cabangId;
  final String cabangNama;

  const KasirPage({
    Key? key,
    required this.cabangId,
    required this.cabangNama,
  }) : super(key: key);

  @override
  ConsumerState<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends ConsumerState<KasirPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // === FUNGSI HELPER UNTUK MANAJEMEN KERANJANG ===
  void _updateCartItemQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      // Jika jumlah 0 atau kurang, hapus item
      _removeCartItem(index);
      return;
    }

    final currentCart = ref.read(cartProvider);
    final updatedCart = List<Map<String, dynamic>>.from(currentCart);
    updatedCart[index]['jumlah'] = newQuantity;
    ref.read(cartProvider.notifier).state = updatedCart;
  }

  void _removeCartItem(int index) {
    final currentCart = ref.read(cartProvider);
    final updatedCart = List<Map<String, dynamic>>.from(currentCart);
    updatedCart.removeAt(index);
    ref.read(cartProvider.notifier).state = updatedCart;
  }

  // === FUNGSI HELPER UNTUK FILTER PRODUK ===
  List<dynamic> _filterProducts(List<dynamic> products) {
    if (_searchQuery.isEmpty) {
      return products;
    }
    return products.where((produk) {
      final nama = produk['nama'].toString().toLowerCase();
      return nama.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final totalHarga = cart.fold<double>(0, (sum, item) {
      return sum + (item['produk']['harga'] * item['jumlah']);
    }).toInt();

    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir di ${widget.cabangNama}'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
                // Product Grid
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(produkListFutureProvider(widget.cabangId));
                      ref.read(cartProvider.notifier).state = [];
                      await Future.delayed(const Duration(milliseconds: 300));
                    },
                    child: Consumer(
                      builder: (context, ref, _) {
                        final produkAsync = ref.watch(produkListFutureProvider(widget.cabangId));
                        return produkAsync.when(
                          data: (produkList) {
                            final filteredProducts = _filterProducts(produkList);
                            return GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200,
                                childAspectRatio: 3 / 4,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final produk = filteredProducts[index];
                                return _buildProdukCard(produk);
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(child: Text('Error: $err')),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 1,
            child: _buildCartView(cart, totalHarga),
          ),
        ],
      ),
    );
  }

  Widget _buildProdukCard(dynamic produk) {
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

  Widget _buildCartView(List<Map<String, dynamic>> cart, int totalHarga) {
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
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              // Info produk
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['produk']['nama'],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Rp ${item['produk']['harga']}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              // Kontrol jumlah
                              Row(
                                children: [
                                  // Tombol kurang
                                  IconButton(
                                    onPressed: () {
                                      _updateCartItemQuantity(index, item['jumlah'] - 1);
                                    },
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: Colors.red,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                  // Tampilan jumlah
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${item['jumlah']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  // Tombol tambah
                                  IconButton(
                                    onPressed: () {
                                      _updateCartItemQuantity(index, item['jumlah'] + 1);
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: Colors.green,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                  // Tombol hapus
                                  IconButton(
                                    onPressed: () {
                                      _removeCartItem(index);
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                  'cabangId': widget.cabangId,
                  'metodeBayar': 'Tunai',
                  'items': itemsDto,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaksi berhasil!'), backgroundColor: Colors.green),
                );
                ref.invalidate(produkListFutureProvider(widget.cabangId));
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
