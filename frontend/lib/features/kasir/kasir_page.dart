import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../services/offline_database.dart';
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';

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
    
    // Start auto sync when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SyncService.startAutoSync(ref);
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

    // Watch connectivity status
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOfflineMode = ref.watch(offlineModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir di ${widget.cabangNama}'),
        backgroundColor: isOfflineMode ? Colors.orange : null,
        actions: [
          // Manual sync button untuk testing
          IconButton(
            onPressed: () async {
              print('🔧 Manual sync button pressed');
              final result = await SyncService.manualSync(ref);
              final message = result 
                ? 'Sync berhasil!' 
                : 'Sync gagal atau tidak ada data untuk disync';
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: result ? Colors.green : Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.sync),
            tooltip: 'Manual Sync',
          ),
          // Offline mode indicator
          connectivityAsync.when(
            data: (isOnline) => isOnline 
              ? const Icon(Icons.wifi, color: Colors.green)
              : const Icon(Icons.wifi_off, color: Colors.red),
            loading: () => const Icon(Icons.sync, color: Colors.yellow),
            error: (_, __) => const Icon(Icons.error, color: Colors.red),
          ),
          const SizedBox(width: 8),
        ],
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
                      ref.invalidate(produkListWithOfflineProvider(widget.cabangId));
                      ref.read(cartProvider.notifier).state = [];
                      await Future.delayed(const Duration(milliseconds: 300));
                    },
                    child: Consumer(
                      builder: (context, ref, _) {
                        final produkAsync = ref.watch(produkListWithOfflineProvider(widget.cabangId));
                        return produkAsync.when(
                          data: (produkList) {
                            final filteredProducts = _filterProducts(produkList);
                            
                            // Show offline banner if in offline mode
                            return Column(
                              children: [
                                if (isOfflineMode)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8.0),
                                    color: Colors.orange.shade100,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.offline_bolt, color: Colors.orange),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Mode Offline - Data dari cache lokal',
                                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                Expanded(
                                  child: GridView.builder(
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
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                const SizedBox(height: 16),
                                Text('Error: $err'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.invalidate(produkListWithOfflineProvider(widget.cabangId));
                                  },
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
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
                final isConnected = await ConnectivityService.isConnected();
                
                final itemsDto = cart.map((item) => {
                  'produkId': item['produk']['id'],
                  'jumlah': item['jumlah'],
                }).toList();

                if (isConnected) {
                  // Online mode - send to server directly
                  await dio.post('/transaksi', data: {
                    'cabangId': widget.cabangId,
                    'metodeBayar': 'Tunai',
                    'items': itemsDto,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaksi berhasil!'), backgroundColor: Colors.green),
                  );
                } else {
                  // Offline mode - save to local database
                  await OfflineDatabase.saveTransaksiOffline(
                    cabangId: widget.cabangId,
                    metodeBayar: 'Tunai',
                    totalHarga: totalHarga,
                    items: cart.map((item) => {
                      'produkId': item['produk']['id'],
                      'jumlah': item['jumlah'],
                      'nama': item['produk']['nama'],
                      'harga': item['produk']['harga'],
                    }).toList(),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaksi disimpan offline - akan disync saat online'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }

                // Clear cart and refresh
                ref.read(cartProvider.notifier).state = [];
                ref.invalidate(produkListWithOfflineProvider(widget.cabangId));

              } catch (e) {
                // Fallback to offline mode on any error
                try {
                  await OfflineDatabase.saveTransaksiOffline(
                    cabangId: widget.cabangId,
                    metodeBayar: 'Tunai',
                    totalHarga: totalHarga,
                    items: cart.map((item) => {
                      'produkId': item['produk']['id'],
                      'jumlah': item['jumlah'],
                      'nama': item['produk']['nama'],
                      'harga': item['produk']['harga'],
                    }).toList(),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Server error - transaksi disimpan offline'),
                      backgroundColor: Colors.orange,
                    ),
                  );

                  ref.read(cartProvider.notifier).state = [];
                } catch (offlineError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $offlineError'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: ref.watch(offlineModeProvider) ? Colors.orange : Colors.green,
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final isOffline = ref.watch(offlineModeProvider);
                return Text(
                  isOffline ? 'Bayar (Offline)' : 'Bayar (Tunai)', 
                  style: const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
