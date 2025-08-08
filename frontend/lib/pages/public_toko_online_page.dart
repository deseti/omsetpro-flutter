import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/toko_online_model.dart';
import '../services/toko_online_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/api_config.dart';

// Provider untuk data toko berdasarkan slug
final tokoDataProvider =
    FutureProvider.family<TokoOnlineData, String>((ref, slug) async {
  // Create public Dio instance without auth
  final publicDio = Dio();
  publicDio.options.baseUrl = ApiConfig.baseUrl;
  final service = TokoOnlineService(publicDio);
  return service.getTokoBySlug(slug);
});

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

class PublicTokoOnlinePage extends ConsumerStatefulWidget {
  final String slug;

  const PublicTokoOnlinePage({Key? key, required this.slug}) : super(key: key);

  @override
  ConsumerState<PublicTokoOnlinePage> createState() =>
      _PublicTokoOnlinePageState();
}

class _PublicTokoOnlinePageState extends ConsumerState<PublicTokoOnlinePage> {
  @override
  Widget build(BuildContext context) {
    final tokoAsync = ref.watch(tokoDataProvider(widget.slug));
    final cart = ref.watch(cartProvider);

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
          if (cart.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => _showCartDialog(context),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${ref.read(cartProvider.notifier).totalItems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
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
      floatingActionButton: cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCartDialog(context),
              icon: const Icon(Icons.shopping_cart),
              label:
                  Text('${ref.read(cartProvider.notifier).totalItems} Items'),
            )
          : null,
    );
  }

  Widget _buildTokoContent(TokoOnlineData toko) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toko info
          _buildTokoInfo(toko),
          const SizedBox(height: 24),

          // Delivery options
          _buildDeliveryOptions(toko),
          const SizedBox(height: 24),

          // Products
          _buildProductGrid(toko.produk),
        ],
      ),
    );
  }

  Widget _buildTokoInfo(TokoOnlineData toko) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (toko.logoUrl != null)
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(toko.logoUrl!),
                  )
                else
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.store, size: 30),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toko.nama,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (toko.alamat.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(toko.alamat,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                      if (toko.telepon.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('📞 ${toko.telepon}',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOptions(TokoOnlineData toko) {
    List<String> options = [];
    if (toko.allowPickup) options.add('📦 Ambil di Tempat');
    if (toko.allowDelivery) options.add('🚚 Diantar');

    if (options.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilihan Pengiriman',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...options.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child:
                      Text(option, style: const TextStyle(color: Colors.green)),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Produk> produkList) {
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
            return _buildProductCard(produkList[index]);
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(Produk produk) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          AspectRatio(
            aspectRatio: 1.0,
            child: produk.fotoUrl != null
                ? Image.network(
                    produk.fotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),

          // Product info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produk.nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatCurrency(produk.harga),
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok: ${produk.stok}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),

                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          produk.stok > 0 ? () => _addToCart(produk) : null,
                      child: Text(produk.stok > 0 ? 'Tambah' : 'Habis'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Produk produk) {
    ref.read(cartProvider.notifier).addToCart(produk, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${produk.nama} ditambahkan ke keranjang')),
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

// Checkout Bottom Sheet
class CheckoutBottomSheet extends ConsumerStatefulWidget {
  final List<CartItem> cart;
  final TokoOnlineData toko;
  final VoidCallback onOrderPlaced;

  const CheckoutBottomSheet({
    Key? key,
    required this.cart,
    required this.toko,
    required this.onOrderPlaced,
  }) : super(key: key);

  @override
  ConsumerState<CheckoutBottomSheet> createState() =>
      _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends ConsumerState<CheckoutBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _hpController = TextEditingController();
  String _tipePengiriman = 'Diambil';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default tipe pengiriman
    if (!widget.toko.allowPickup && widget.toko.allowDelivery) {
      _tipePengiriman = 'Diantar';
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice =
        widget.cart.fold<int>(0, (sum, item) => sum + item.subtotal);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Checkout',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cart items
                        _buildCartItems(),
                        const SizedBox(height: 24),

                        // Customer info
                        _buildCustomerForm(),
                        const SizedBox(height: 24),

                        // Delivery options
                        _buildDeliveryOptions(),
                        const SizedBox(height: 24),

                        // Payment info
                        _buildPaymentInfo(),
                        const SizedBox(height: 24),

                        // Total
                        _buildTotal(totalPrice),
                        const SizedBox(height: 24),

                        // Order button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _placeOrder,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    'Pesan Sekarang (${CurrencyFormatter.formatCurrency(totalPrice)})'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pesanan Anda',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...widget.cart.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.produk.nama,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          '${CurrencyFormatter.formatCurrency(item.produk.harga)} x ${item.jumlah}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatCurrency(item.subtotal),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCustomerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Pelanggan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _namaController,
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty == true) return 'Nama harus diisi';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _hpController,
          decoration: const InputDecoration(
            labelText: 'Nomor WhatsApp',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value?.isEmpty == true) return 'Nomor HP harus diisi';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDeliveryOptions() {
    List<String> availableOptions = [];
    if (widget.toko.allowPickup) availableOptions.add('Diambil');
    if (widget.toko.allowDelivery) availableOptions.add('Diantar');

    if (availableOptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metode Pengiriman',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...availableOptions.map((option) => RadioListTile<String>(
              title: Text(
                  option == 'Diambil' ? 'Ambil di Tempat' : 'Diantar Kurir'),
              value: option,
              groupValue: _tipePengiriman,
              onChanged: (value) {
                setState(() {
                  _tipePengiriman = value!;
                });
              },
            )),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    if (widget.toko.rekeningBank.isEmpty) {
      return const Card(
        color: Colors.orange,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Toko belum menambahkan rekening bank. Hubungi langsung untuk pembayaran.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text('Transfer ke salah satu rekening berikut:'),
        const SizedBox(height: 8),
        ...widget.toko.rekeningBank.map((rekening) => Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance),
                title: Text(rekening.namaBank),
                subtitle: Text(
                    '${rekening.nomorRekening}\na.n. ${rekening.namaPemilik}'),
              ),
            )),
      ],
    );
  }

  Widget _buildTotal(int totalPrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Pembayaran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            CurrencyFormatter.formatCurrency(totalPrice),
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create public Dio instance without auth
      final publicDio = Dio();
      publicDio.options.baseUrl = ApiConfig.baseUrl;
      final service = TokoOnlineService(publicDio);
      final orderRequest = OrderRequest(
        items: widget.cart
            .map((item) => OrderItem(
                  produkId: item.produk.id,
                  jumlah: item.jumlah,
                ))
            .toList(),
        namaPelanggan: _namaController.text.trim(),
        noHpPelanggan: _hpController.text.trim(),
        tipePengiriman: _tipePengiriman,
      );

      final result = await service.createOrder(
        widget.toko.nama.toLowerCase().replaceAll(' ', '-'), // Temporary slug
        orderRequest,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pesanan Berhasil!'),
            content: Text(
                'Nomor pesanan: ${result['id']}\n\nSilakan transfer pembayaran dan konfirmasi ke toko.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  widget.onOrderPlaced();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
