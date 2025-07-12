import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart'; // <-- PERBAIKAN: Import yang hilang ditambahkan
import '../../models/pelanggan_model.dart';
import '../../providers/providers.dart' as AppProviders;
import '../../services/offline_database_proxy.dart' as OfflineDatabase;
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';
import '../../services/receipt_service.dart';
import '../../widgets/receipt_preview_dialog.dart';
import '../../utils/laporan_refresh_helper.dart';
import './widgets/pilih_pelanggan_dialog.dart';
import './widgets/redeem_reward_dialog.dart';

class KasirPage extends ConsumerStatefulWidget {
  final int cabangId;
  final String cabangNama;

  const KasirPage({
    super.key,
    required this.cabangId,
    required this.cabangNama,
  });

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
        _searchQuery = _searchController.text;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SyncService.startAutoSync(ref);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateCartItemQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeCartItem(index);
      return;
    }
    final currentCart = ref.read(AppProviders.cartProvider);
    final updatedCart = List<Map<String, dynamic>>.from(currentCart);
    updatedCart[index]['jumlah'] = newQuantity;
    ref.read(AppProviders.cartProvider.notifier).state = updatedCart;
  }

  void _removeCartItem(int index) {
    final currentCart = ref.read(AppProviders.cartProvider);
    final updatedCart = List<Map<String, dynamic>>.from(currentCart);
    updatedCart.removeAt(index);
    ref.read(AppProviders.cartProvider.notifier).state = updatedCart;
  }

  List<dynamic> _filterProducts(List<dynamic> products) {
    if (_searchQuery.isEmpty) {
      return products;
    }
    final query = _searchQuery.toLowerCase();
    return products.where((produk) {
      final nama = produk['nama'].toString().toLowerCase();
      final barcode = produk['barcode']?.toString().toLowerCase() ?? '';
      return nama.contains(query) || barcode.contains(query);
    }).toList();
  }

  void _showReceiptPreview({
    required List<Map<String, dynamic>> cart,
    required int totalHarga,
    required int transaksiId,
  }) {
    final user = ref.read(AppProviders.userProfileProvider);
    final namaKasir = user?['namaLengkap'] ?? 'Kasir';

    final items = cart.map((item) => {
      'nama': item['produk']['nama'],
      'jumlah': item['jumlah'],
      'harga': item['produk']['harga'],
    }).toList();

    final receiptText = ReceiptService.formatReceiptText(
      namaToko: 'OmsetPro POS',
      namaCabang: widget.cabangNama,
      alamatCabang: 'Alamat Cabang',
      namaKasir: namaKasir,
      transaksiId: transaksiId,
      items: items,
      subtotal: totalHarga,
      totalHarga: totalHarga,
    );

    ReceiptPreviewDialog.show(
      context,
      receiptText: receiptText,
      transaksiId: transaksiId.toString(),
    );
  }

  Future<void> _processTransaction({
    required List<Map<String, dynamic>> cart,
    required int totalHarga,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final selectedPelanggan = ref.read(AppProviders.selectedPelangganProvider);

    try {
      final dio = ref.read(AppProviders.dioProvider);
      final isConnected = await ConnectivityService.isConnected();

      final itemsDto = cart.map((item) => {
        'produkId': item['produk']['id'],
        'jumlah': item['jumlah'],
      }).toList();

      final requestData = {
        'cabangId': widget.cabangId,
        'metodeBayar': 'Tunai',
        'items': itemsDto,
        'pelangganId': selectedPelanggan?.id,
      };

      if (isConnected) {
        final response = await dio.post('/transaksi', data: requestData);
        final transaksiId = response.data['id'] ?? DateTime.now().millisecondsSinceEpoch;
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil!'), backgroundColor: Colors.green),
        );
        _showReceiptPreview(cart: cart, totalHarga: totalHarga, transaksiId: transaksiId);
        LaporanRefreshHelper.refreshLaporanAfterTransaction(ref);
      } else {
        final transaksiId = DateTime.now().millisecondsSinceEpoch;
        await OfflineDatabase.OfflineDatabase.saveTransaksiOffline(
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
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Transaksi disimpan offline - akan disync saat online'),
            backgroundColor: Colors.orange,
          ),
        );
        _showReceiptPreview(cart: cart, totalHarga: totalHarga, transaksiId: transaksiId);
      }

      ref.read(AppProviders.cartProvider.notifier).state = [];
      ref.read(AppProviders.selectedPelangganProvider.notifier).state = null;
      ref.invalidate(AppProviders.produkListWithOfflineProvider(widget.cabangId));

    } on DioException catch (e) { // <-- PERBAIKAN: Menggunakan tipe DioException yang benar
      final errorMessage = e.response?.data['message'] ?? 'Terjadi kesalahan saat transaksi.';
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $errorMessage'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  // [PERBAIKAN] Widget ini dipindahkan ke dalam class _KasirPageState
  Widget _buildPelangganInfo(Pelanggan? pelanggan) {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: pelanggan == null
            ? ListTile(
                leading: const Icon(Icons.person_add_alt_1, color: Colors.blue),
                title: const Text('Tanpa Pelanggan'),
                subtitle: const Text('Klik untuk mencari atau menambah'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const PilihPelangganDialog(),
                  );
                },
              )
            : Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(child: Text(pelanggan.nama.substring(0, 1))),
                    title: Text(pelanggan.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(pelanggan.noHp),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Hapus Pelanggan dari Transaksi',
                      onPressed: () {
                        ref.read(AppProviders.selectedPelangganProvider.notifier).state = null;
                      },
                    ),
                    onTap: () {
                       showDialog(
                        context: context,
                        builder: (_) => const PilihPelangganDialog(),
                      );
                    },
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Poin', style: TextStyle(fontSize: 12)),
                            Text(
                              '${pelanggan.totalPoin} Poin',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.card_giftcard),
                          label: const Text('Tukar Poin'),
                          onPressed: pelanggan.totalPoin > 0
                              ? () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => RedeemRewardDialog(pelanggan: pelanggan),
                                  );
                                }
                              : null, // Disable tombol jika poin 0
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(AppProviders.cartProvider);
    final totalHarga = cart.fold<double>(0, (sum, item) {
      return sum + (item['produk']['harga'] * item['jumlah']);
    }).toInt();
    final connectivityAsync = ref.watch(AppProviders.connectivityProvider);
    final isOfflineMode = ref.watch(AppProviders.offlineModeProvider);
    final selectedPelanggan = ref.watch(AppProviders.selectedPelangganProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir di ${widget.cabangNama}'),
        backgroundColor: isOfflineMode ? Colors.orange.shade700 : null,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await SyncService.manualSync(ref);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result ? 'Sync berhasil!' : 'Sync gagal atau tidak ada data baru.'),
                  backgroundColor: result ? Colors.green : Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.sync),
            tooltip: 'Manual Sync',
          ),
          connectivityAsync.when(
            data: (isOnline) => isOnline 
              ? const Icon(Icons.wifi, color: Colors.green)
              : const Icon(Icons.wifi_off, color: Colors.red),
            loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)),
            error: (_, __) => const Icon(Icons.error, color: Colors.red),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari produk atau scan barcode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(AppProviders.produkListWithOfflineProvider(widget.cabangId));
                      ref.read(AppProviders.cartProvider.notifier).state = [];
                      ref.read(AppProviders.selectedPelangganProvider.notifier).state = null;
                    },
                    child: Consumer(
                      builder: (context, ref, _) {
                        final produkAsync = ref.watch(AppProviders.produkListWithOfflineProvider(widget.cabangId));
                        return produkAsync.when(
                          data: (produkList) {
                            final filteredProducts = _filterProducts(produkList);
                            return Column(
                              children: [
                                if (isOfflineMode)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8.0),
                                    color: Colors.orange.shade100,
                                    child: const Row(
                                      children: [
                                        Icon(Icons.offline_bolt, color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text('Mode Offline - Data dari cache lokal', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
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
                                    itemBuilder: (context, index) => _buildProdukCard(filteredProducts[index]),
                                  ),
                                ),
                              ],
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
            child: _buildCartView(cart, totalHarga, selectedPelanggan),
          ),
        ],
      ),
    );
  }

  Widget _buildProdukCard(dynamic produk) {
    return InkWell(
      onTap: () {
        final cartNotifier = ref.read(AppProviders.cartProvider.notifier);
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

  Widget _buildCartView(List<Map<String, dynamic>> cart, int totalHarga, Pelanggan? selectedPelanggan) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Keranjang', style: Theme.of(context).textTheme.headlineSmall),
          const Divider(),
          _buildPelangganInfo(selectedPelanggan),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['produk']['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Rp ${item['produk']['harga']}', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _updateCartItemQuantity(index, item['jumlah'] - 1),
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: Colors.red,
                                  ),
                                  Text('${item['jumlah']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    onPressed: () => _updateCartItemQuantity(index, item['jumlah'] + 1),
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: Colors.green,
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
            onPressed: cart.isEmpty ? null : () => _processTransaction(cart: cart, totalHarga: totalHarga),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: ref.watch(AppProviders.offlineModeProvider) ? Colors.orange : Colors.green,
            ),
            child: const Text('Bayar (Tunai)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}