import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart'; // <-- PERBAIKAN: Import yang hilang ditambahkan
import '../../models/pelanggan_model.dart';
import '../../providers/providers.dart' as AppProviders;
import '../../services/offline_database_proxy.dart' as OfflineDatabase;
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';
import '../../services/receipt_service.dart';
import '../../services/midtrans_service.dart'; // <-- TAMBAHKAN INI
import '../../services/payment_service_factory.dart'; // <-- TAMBAH IMPORT BARU
import '../../services/payment_service_interface.dart'; // <-- TAMBAH IMPORT INTERFACE
import '../../widgets/receipt_preview_dialog.dart';
import '../../widgets/responsive_widgets.dart'; // Import responsive widgets
import '../../theme/app_theme.dart'; // Import tema
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

    final items = cart
        .map((item) => {
              'nama': item['produk']['nama'],
              'jumlah': item['jumlah'],
              'harga': item['produk']['harga'],
            })
        .toList();

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
    bool isDigitalPayment = false,
    String? paymentMethod,
    String? orderId,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final selectedPelanggan = ref.read(AppProviders.selectedPelangganProvider);

    try {
      final dio = ref.read(AppProviders.dioProvider);
      final isConnected = await ConnectivityService.isConnected();

      final itemsDto = cart
          .map((item) => {
                'produkId': item['produk']['id'],
                'jumlah': item['jumlah'],
              })
          .toList();

      final requestData = {
        'cabangId': widget.cabangId,
        'metodeBayar':
            isDigitalPayment ? (paymentMethod ?? 'Digital') : 'Tunai',
        'items': itemsDto,
        'pelangganId': selectedPelanggan?.id,
        'orderId': orderId, // Tambahkan orderId jika ada
        'isDigitalPayment': isDigitalPayment,
      };

      if (isConnected) {
        final response = await dio.post('/transaksi', data: requestData);
        final transaksiId =
            response.data['id'] ?? DateTime.now().millisecondsSinceEpoch;
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content: Text('Transaksi berhasil!'),
              backgroundColor: Colors.green),
        );
        _showReceiptPreview(
            cart: cart, totalHarga: totalHarga, transaksiId: transaksiId);
        LaporanRefreshHelper.refreshLaporanAfterTransaction(ref);
      } else {
        final transaksiId = DateTime.now().millisecondsSinceEpoch;
        await OfflineDatabase.OfflineDatabase.saveTransaksiOffline(
          cabangId: widget.cabangId,
          metodeBayar:
              isDigitalPayment ? (paymentMethod ?? 'Digital') : 'Tunai',
          totalHarga: totalHarga,
          items: cart
              .map((item) => {
                    'produkId': item['produk']['id'],
                    'jumlah': item['jumlah'],
                    'nama': item['produk']['nama'],
                    'harga': item['produk']['harga'],
                  })
              .toList(),
        );
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content:
                Text('Transaksi disimpan offline - akan disync saat online'),
            backgroundColor: Colors.orange,
          ),
        );
        _showReceiptPreview(
            cart: cart, totalHarga: totalHarga, transaksiId: transaksiId);
      }

      ref.read(AppProviders.cartProvider.notifier).state = [];
      ref.read(AppProviders.selectedPelangganProvider.notifier).state = null;
      ref.invalidate(
          AppProviders.produkListWithOfflineProvider(widget.cabangId));
    } on DioException catch (e) {
      // <-- PERBAIKAN: Menggunakan tipe DioException yang benar
      final errorMessage =
          e.response?.data['message'] ?? 'Terjadi kesalahan saat transaksi.';
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Error: $errorMessage'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _processDigitalTransaction({
    required List<Map<String, dynamic>> cart,
    required int totalHarga,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final midtransService = ref.read(midtransServiceProvider);
    final selectedPelanggan = ref.read(AppProviders.selectedPelangganProvider);

    final List<Map<String, dynamic>> itemDetails = cart.map((item) {
      return {
        'id': item['produk']['id'].toString(),
        'price': item['produk']['harga'].toDouble(),
        'quantity': item['jumlah'],
        'name': item['produk']['nama'],
      };
    }).toList();

    final Map<String, dynamic> customerDetails = {
      'first_name': selectedPelanggan?.nama ?? 'Pelanggan',
      'last_name': '',
      'email': selectedPelanggan?.email ?? 'pelanggan@omsetpro.com',
      'phone': selectedPelanggan?.noHp ?? '081234567890',
    };

    try {
      await midtransService.startPayment(
        totalAmount: totalHarga,
        items: itemDetails,
        customerDetails: customerDetails,
      );

      // TODO: Tambahkan callback listener dari Midtrans untuk mengupdate
      // status transaksi di backend Anda setelah pembayaran berhasil.

      ref.read(AppProviders.cartProvider.notifier).state = [];
      ref.read(AppProviders.selectedPelangganProvider.notifier).state = null;
      ref.invalidate(
          AppProviders.produkListWithOfflineProvider(widget.cabangId));
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();

        // Berikan pesan khusus untuk platform web
        if (e.toString().contains('web')) {
          errorMessage =
              'Pembayaran digital hanya tersedia di aplikasi mobile. '
              'Silakan gunakan metode pembayaran tunai atau buka aplikasi di perangkat mobile.';
        }

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error memulai pembayaran: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // [PERBAIKAN] Widget ini dipindahkan ke dalam class _KasirPageState
  Widget _buildPelangganInfo(Pelanggan? pelanggan) {
    return ResponsiveCard(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: pelanggan == null
          ? ListTile(
              leading: Icon(
                Icons.person_add_alt_1,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Tanpa Pelanggan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                'Klik untuk mencari atau menambah',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
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
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    child: Text(
                      pelanggan.nama.substring(0, 1).toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  title: Text(
                    pelanggan.nama,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  subtitle: Text(
                    pelanggan.noHp,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: 'Hapus Pelanggan dari Transaksi',
                    onPressed: () {
                      ref
                          .read(AppProviders.selectedPelangganProvider.notifier)
                          .state = null;
                    },
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const PilihPelangganDialog(),
                    );
                  },
                ),
                Divider(color: Theme.of(context).colorScheme.outline),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Poin',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          const SizedBox(height: AppTheme.spaceXS),
                          Text(
                            '${pelanggan.totalPoin} Poin',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      FilledButton.tonal(
                        onPressed: pelanggan.totalPoin > 0
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      RedeemRewardDialog(pelanggan: pelanggan),
                                );
                              }
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_giftcard, size: 18),
                            const SizedBox(width: AppTheme.spaceXS),
                            const Text('Tukar Poin'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(AppProviders.cartProvider);
    final cartTotalInfo = ref.watch(AppProviders.cartTotalWithPromoProvider);
    final totalHarga = cartTotalInfo['totalAkhir'];
    final connectivityAsync = ref.watch(AppProviders.connectivityProvider);
    final isOfflineMode = ref.watch(AppProviders.offlineModeProvider);
    final selectedPelanggan = ref.watch(AppProviders.selectedPelangganProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kasir di ${widget.cabangNama}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        backgroundColor: isOfflineMode
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isOfflineMode
            ? Theme.of(context).colorScheme.onTertiary
            : Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await SyncService.manualSync(ref);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result
                      ? 'Sync berhasil!'
                      : 'Sync gagal atau tidak ada data baru.'),
                  backgroundColor: result
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.tertiary,
                ),
              );
            },
            icon: const Icon(Icons.sync),
            tooltip: 'Manual Sync',
          ),
          connectivityAsync.when(
            data: (isOnline) => Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: isOnline
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.error,
            ),
            loading: () => SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onSurface,
                strokeWidth: 2,
              ),
            ),
            error: (_, __) => Icon(
              Icons.error,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
        ],
      ),
      body: ResponsiveMasterDetail(
        master: _buildProductGrid(),
        detail: _buildCartView(cart, totalHarga, selectedPelanggan),
        masterWidth: ResponsiveBreakpoints.getResponsiveValue(
          context,
          mobile: 300,
          tablet: 400,
          desktop: 500,
        ),
        showMasterInDrawer: context.isMobile,
      ),
    );
  }

  Widget _buildProductGrid() {
    final isOfflineMode = ref.watch(AppProviders.offlineModeProvider);

    return Column(
      children: [
        // Search Bar
        ResponsiveContainer(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari produk atau scan barcode...',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        // Product Grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                  AppProviders.produkListWithOfflineProvider(widget.cabangId));
              ref.read(AppProviders.cartProvider.notifier).state = [];
              ref.read(AppProviders.selectedPelangganProvider.notifier).state =
                  null;
            },
            child: Consumer(
              builder: (context, ref, _) {
                final produkAsync = ref.watch(
                    AppProviders.produkListWithOfflineProvider(
                        widget.cabangId));
                return produkAsync.when(
                  data: (produkList) {
                    final filteredProducts = _filterProducts(produkList);
                    return Column(
                      children: [
                        // Offline Mode Indicator
                        if (isOfflineMode)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppTheme.spaceMD),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(AppTheme.radiusMD),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.offline_bolt,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer,
                                ),
                                const SizedBox(width: AppTheme.spaceSM),
                                Expanded(
                                  child: Text(
                                    'Mode Offline - Data dari cache lokal',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onTertiaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Products Grid
                        Expanded(
                          child: ResponsiveGrid(
                            mobileColumns:
                                ResponsiveUtils.getGridCrossAxisCount(
                              context,
                              mobileCount: 2,
                              tabletCount: 3,
                              desktopCount: 4,
                            ),
                            tabletColumns:
                                ResponsiveUtils.getGridCrossAxisCount(
                              context,
                              mobileCount: 2,
                              tabletCount: 3,
                              desktopCount: 4,
                            ),
                            desktopColumns:
                                ResponsiveUtils.getGridCrossAxisCount(
                              context,
                              mobileCount: 2,
                              tabletCount: 3,
                              desktopCount: 4,
                            ),
                            childAspectRatio: 0.75,
                            children: filteredProducts
                                .map((product) => _buildProdukCard(product))
                                .toList(),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: AppTheme.spaceMD),
                        Text(
                          'Terjadi kesalahan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spaceSM),
                        Text(
                          'Error: $err',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                          textAlign: TextAlign.center,
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
    );
  }

  Widget _buildProdukCard(dynamic produk) {
    return ResponsiveCard(
      onTap: () {
        final cartNotifier = ref.read(AppProviders.cartProvider.notifier);
        final currentCart = cartNotifier.state;
        final existingItemIndex = currentCart
            .indexWhere((item) => item['produk']['id'] == produk['id']);

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
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMD),
                ),
              ),
              child: produk['fotoUrl'] != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusMD),
                      ),
                      child: Image.network(
                        produk['fotoUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                              strokeWidth: 2,
                            ),
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.inventory_2,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          // Product Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Product Name
                  Text(
                    produk['nama'],
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Product Price
                  Text(
                    _formatCurrency(produk['harga']),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
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

  Widget _buildCartView(List<Map<String, dynamic>> cart, int totalHarga,
      Pelanggan? selectedPelanggan) {
    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Keranjang',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Divider(
            color: Theme.of(context).colorScheme.outline,
            height: AppTheme.spaceLG,
          ),

          // Customer Info
          _buildPelangganInfo(selectedPelanggan),
          const ResponsiveSpacing(mobileSize: AppTheme.spaceMD),

          // Cart Content
          Expanded(
            child: Column(
              children: [
                // Cart Items
                Expanded(
                  child: cart.isEmpty
                      ? _buildEmptyCart()
                      : ListView.separated(
                          itemCount: cart.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppTheme.spaceSM),
                          itemBuilder: (context, index) {
                            final item = cart[index];
                            return _buildCartItem(item, index);
                          },
                        ),
                ),

                // Promo Section
                const ResponsiveSpacing(mobileSize: AppTheme.spaceMD),
                _buildPromoSection(ref),

                // Total Section
                const ResponsiveSpacing(mobileSize: AppTheme.spaceMD),
                _buildTotalSection(ref, totalHarga),
              ],
            ),
          ),

          // Payment Buttons - Fixed at bottom
          const ResponsiveSpacing(mobileSize: AppTheme.spaceLG),
          _buildPaymentButtons(cart, totalHarga),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'Keranjang kosong',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Pilih produk untuk mulai transaksi',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return ResponsiveCard(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Row(
        children: [
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['produk']['nama'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  _formatCurrency(item['produk']['harga']),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          // Quantity Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () =>
                    _updateCartItemQuantity(index, item['jumlah'] - 1),
                icon: const Icon(Icons.remove_circle_outline),
                color: Theme.of(context).colorScheme.error,
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 40),
                child: Text(
                  '${item['jumlah']}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () =>
                    _updateCartItemQuantity(index, item['jumlah'] + 1),
                icon: const Icon(Icons.add_circle_outline),
                color: Theme.of(context).colorScheme.secondary,
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButtons(List<Map<String, dynamic>> cart, int totalHarga) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Payment Methods
        ...ref
            .watch(AppProviders.availablePaymentMethodsProvider)
            .map((method) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
            child: _buildPaymentButton(method, cart, totalHarga),
          );
        }),

        // Platform Info (Debug Mode)
        if (kDebugMode) ...[
          const ResponsiveSpacing(mobileSize: AppTheme.spaceSM),
          Consumer(
            builder: (context, ref, child) {
              final platformInfo = ref.watch(AppProviders.platformInfoProvider);
              return Container(
                padding: const EdgeInsets.all(AppTheme.spaceSM),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  'Platform: ${platformInfo['platform']} | '
                  'Digital Payment: ${platformInfo['digitalPaymentSupported'] ? '✓' : '✗'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentButton(AppProviders.PaymentMethod method,
      List<Map<String, dynamic>> cart, int totalHarga) {
    switch (method) {
      case AppProviders.PaymentMethod.digital:
        return FilledButton.icon(
          onPressed: cart.isEmpty
              ? null
              : () => _processDigitalTransaction(
                    cart: cart,
                    totalHarga: totalHarga,
                  ),
          icon: const Icon(Icons.qr_code),
          label: const Text('Bayar Digital (QRIS, dll)'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
          ),
        );
      case AppProviders.PaymentMethod.manual:
        return FilledButton.tonal(
          onPressed: cart.isEmpty
              ? null
              : () => _showManualPaymentDialog(cart, totalHarga),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.credit_card),
              SizedBox(width: AppTheme.spaceSM),
              Text('Input Pembayaran Manual'),
            ],
          ),
        );
      case AppProviders.PaymentMethod.cash:
        final isOfflineMode = ref.watch(AppProviders.offlineModeProvider);
        return FilledButton.icon(
          onPressed: cart.isEmpty
              ? null
              : () => _processTransaction(cart: cart, totalHarga: totalHarga),
          icon: Icon(isOfflineMode ? Icons.offline_bolt : Icons.payments),
          label: const Text('Bayar (Tunai)'),
          style: FilledButton.styleFrom(
            backgroundColor: isOfflineMode
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.secondary,
            foregroundColor: isOfflineMode
                ? Theme.of(context).colorScheme.onTertiary
                : Theme.of(context).colorScheme.onSecondary,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
          ),
        );
    }
  }

  Widget _buildPromoSection(WidgetRef ref) {
    final activePromosAsync = ref.watch(AppProviders.activePromosProvider);
    final selectedPromo = ref.watch(AppProviders.selectedPromoProvider);

    return activePromosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (promos) {
        if (promos.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Promo Tersedia:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<Map<String, dynamic>?>(
              value: selectedPromo,
              hint: const Text('Pilih Promo (Opsional)'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<Map<String, dynamic>?>(
                  value: null,
                  child: Text('Tanpa Promo'),
                ),
                ...promos.map((promo) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: promo,
                    child: Text(
                        '${promo['nama']} - ${promo['nilai']}${promo['tipe'] == 'PERCENTAGE' ? '%' : ' Rupiah'}'),
                  );
                }),
              ],
              onChanged: (value) {
                ref.read(AppProviders.selectedPromoProvider.notifier).state =
                    value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalSection(WidgetRef ref, int totalAkhir) {
    final cartTotalInfo = ref.watch(AppProviders.cartTotalWithPromoProvider);
    final subtotal = cartTotalInfo['subtotal'];
    final totalDiskon = cartTotalInfo['totalDiskon'];
    final namaPromo = cartTotalInfo['namaPromo'];

    return Column(
      children: [
        if (totalDiskon > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text('Rp $subtotal'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Diskon ($namaPromo):',
                  style: const TextStyle(color: Colors.green)),
              Text('-Rp $totalDiskon',
                  style: const TextStyle(color: Colors.green)),
            ],
          ),
          const Divider(),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: Theme.of(context).textTheme.titleLarge),
            Text('Rp $totalAkhir',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // Method untuk menampilkan dialog pembayaran manual (khusus web)
  void _showManualPaymentDialog(
      List<Map<String, dynamic>> cart, int totalHarga) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${_formatCurrency(totalHarga)}'),
            const SizedBox(height: 16),
            const Text(
              'Pilih metode pembayaran:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Transfer Bank'),
              subtitle: const Text('Catat sebagai pembayaran digital'),
              onTap: () {
                Navigator.of(context).pop();
                _processManualDigitalPayment(cart, totalHarga, 'transfer');
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('QRIS'),
              subtitle: const Text('Pembayaran melalui QRIS'),
              onTap: () {
                Navigator.of(context).pop();
                _processManualDigitalPayment(cart, totalHarga, 'qris');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('E-Wallet'),
              subtitle: const Text('GoPay, OVO, DANA, dll'),
              onTap: () {
                Navigator.of(context).pop();
                _processManualDigitalPayment(cart, totalHarga, 'ewallet');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  // Method untuk memproses pembayaran digital manual
  Future<void> _processManualDigitalPayment(List<Map<String, dynamic>> cart,
      int totalHarga, String paymentType) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Simulasi pembayaran berhasil (dalam implementasi nyata,
      // Anda bisa menambahkan dialog konfirmasi)
      final orderId = 'MANUAL-${DateTime.now().millisecondsSinceEpoch}';

      // Proses transaksi seperti pembayaran tunai, tapi tandai sebagai digital
      await _processTransaction(
        cart: cart,
        totalHarga: totalHarga,
        isDigitalPayment: true,
        paymentMethod: paymentType,
        orderId: orderId,
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Pembayaran $paymentType berhasil dicatat'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatCurrency(int amount) {
    // Format mata uang sesuai kebutuhan Anda
    return 'Rp ${amount.toString().replaceAllMapped(
          RegExp(r'(\d+)(\d{3})'),
          (Match m) => '${m[1]}.${m[2]}',
        )}';
  }
}
