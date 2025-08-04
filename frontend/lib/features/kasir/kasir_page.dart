import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../providers/providers.dart' as AppProviders;
import '../../providers/hardware_providers.dart';
import '../../services/sync_service.dart';
import '../../services/hardware/hardware_manager_service.dart';
import '../../services/hardware/barcode_scanner_service.dart';
import '../../widgets/responsive_widgets.dart';
import '../../theme/app_theme.dart';
import '../../pages/hardware_settings_page.dart';
import './widgets/product_grid_widget.dart';
import './widgets/cart_section_widget.dart';
import './services/transaction_service.dart';
import './services/cart_helper.dart';

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
      _initializeHardware();
    });
  }

  /// Initialize hardware services for POS operations
  Future<void> _initializeHardware() async {
    try {
      final hardwareManager = ref.read(hardwareManagerProvider);
      if (!hardwareManager.isInitialized) {
        await hardwareManager.initialize();
        // Auto-connect to saved devices
        await hardwareManager.autoConnectSavedDevices();
      }
      
      // Listen to barcode scans and auto-add products
      ref.listen(barcodeStreamProvider, (previous, next) {
        next.when(
          data: (barcode) => _handleBarcodeScanned(barcode.data),
          loading: () {},
          error: (error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Scanner error: $error')),
            );
          },
        );
      });
      
    } catch (e) {
      print('Hardware initialization failed: $e');
    }
  }

  /// Handle barcode scanned from external scanner
  void _handleBarcodeScanned(String barcode) {
    // Find product by barcode and add to cart
    final produkList = ref.read(AppProviders.produkListWithOfflineProvider(widget.cabangId));
    
    produkList.when(
      data: (products) {
        final product = products.firstWhere(
          (p) => p['barcode']?.toString() == barcode,
          orElse: () => null,
        );
        
        if (product != null) {
          _addToCartByBarcode(product);
          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${product['nama']} to cart'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          // Product not found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product not found: $barcode'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      loading: () {},
      error: (error, stackTrace) {},
    );
  }

  /// Add product to cart from barcode scan
  void _addToCartByBarcode(Map<String, dynamic> produk) {
    final currentCart = ref.read(AppProviders.cartProvider);
    
    // Check if product already in cart
    final existingIndex = currentCart.indexWhere(
      (item) => item['produk']['id'] == produk['id'],
    );
    
    if (existingIndex != -1) {
      // Increase quantity
      final updatedCart = [...currentCart];
      updatedCart[existingIndex] = {
        ...updatedCart[existingIndex],
        'jumlah': updatedCart[existingIndex]['jumlah'] + 1,
      };
      ref.read(AppProviders.cartProvider.notifier).state = updatedCart;
    } else {
      // Add new item
      final newItem = {
        'produk': produk,
        'jumlah': 1,
      };
      ref.read(AppProviders.cartProvider.notifier).state = [...currentCart, newItem];
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateCartItemQuantity(int index, int newQuantity) {
    CartHelper.updateItemQuantity(ref, index, newQuantity);
  }

  void _processTransaction({
    required List<Map<String, dynamic>> cart,
    required int totalHarga,
    bool isDigitalPayment = false,
    String? paymentMethod,
    String? orderId,
  }) {
    TransactionService.processTransaction(
      context: context,
      ref: ref,
      cabangId: widget.cabangId,
      cabangNama: widget.cabangNama,
      cart: cart,
      totalHarga: totalHarga,
      isDigitalPayment: isDigitalPayment,
      paymentMethod: paymentMethod,
      orderId: orderId,
    );
  }

  // [MODIFIKASI FINAL] Mengubah alur fungsi ini
  Future<void> _processDigitalTransaction({
    required List<Map<String, dynamic>> cart,
    required int totalHarga,
  }) async {
    // 1. Panggil service untuk memulai pembayaran dan tunggu hasilnya
    final paymentResult = await TransactionService.processDigitalTransaction(
      context: context,
      ref: ref,
      cart: cart,
      totalHarga: totalHarga,
    );

    // 2. Periksa hasilnya
    if (paymentResult.isSuccess) {
      // 3. JIKA SUKSES (halaman bayar terbuka), JANGAN BUAT STRUK.
      //    Cukup bersihkan keranjang dan beri notifikasi ke kasir.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentResult.message ??
                'Halaman pembayaran dibuka. Selesaikan pembayaran di sana.'),
            backgroundColor: Colors.blue,
          ),
        );

        // Langsung bersihkan keranjang agar kasir bisa lanjut ke transaksi berikutnya.
        // Transaksi akan dicatat oleh backend setelah ada konfirmasi dari Midtrans (via webhook).
        CartHelper.clearCart(ref);
      }
    } else {
      // 4. JIKA GAGAL, tampilkan pesan error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                paymentResult.message ?? 'Gagal memulai pembayaran digital.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _processManualDigitalPayment(
    List<Map<String, dynamic>> cart,
    int totalHarga,
    String paymentType,
  ) {
    TransactionService.processManualDigitalPayment(
      context: context,
      ref: ref,
      cabangId: widget.cabangId,
      cabangNama: widget.cabangNama,
      cart: cart,
      totalHarga: totalHarga,
      paymentType: paymentType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(AppProviders.cartProvider);
    final cartTotalInfo = ref.watch(AppProviders.cartTotalWithPromoProvider);
    final totalHarga = cartTotalInfo['totalAkhir'];
    final connectivityAsync = ref.watch(AppProviders.connectivityProvider);
    final isOfflineMode = ref.watch(AppProviders.offlineModeProvider);

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
          // Hardware Status Icon
          Consumer(
            builder: (context, ref, child) {
              final isPrinterConnected = ref.watch(isPrinterConnectedProvider);
              final isScannerConnected = ref.watch(isScannerConnectedProvider);
              
              return IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HardwareSettingsPage(),
                    ),
                  );
                },
                icon: Stack(
                  children: [
                    const Icon(Icons.devices),
                    if (isPrinterConnected || isScannerConnected)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Hardware Settings',
              );
            },
          ),
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
      body: ResponsiveBreakpoints.isMobile(context)
          ? _buildMobileLayout(cart, totalHarga)
          : ResponsiveMasterDetail(
              master: ProductGridWidget(
                cabangId: widget.cabangId,
                searchController: _searchController,
                searchQuery: _searchQuery,
              ),
              detail: CartSectionWidget(
                onCashPayment: () =>
                    _processTransaction(cart: cart, totalHarga: totalHarga),
                onDigitalPayment: () => _processDigitalTransaction(
                    cart: cart, totalHarga: totalHarga),
                onManualPayment: (paymentType) =>
                    _processManualDigitalPayment(cart, totalHarga, paymentType),
              ),
              masterWidth: ResponsiveBreakpoints.getResponsiveValue(
                context,
                mobile: 300,
                tablet: 400,
                desktop: 500,
              ),
              showMasterInDrawer: false,
            ),
    );
  }

  Widget _buildMobileLayout(List<Map<String, dynamic>> cart, int totalHarga) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: ProductGridWidget(
            cabangId: widget.cabangId,
            searchController: _searchController,
            searchQuery: _searchQuery,
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: CartSectionWidget(
              onCashPayment: () =>
                  _processTransaction(cart: cart, totalHarga: totalHarga),
              onDigitalPayment: () => _processDigitalTransaction(
                  cart: cart, totalHarga: totalHarga),
              onManualPayment: (paymentType) =>
                  _processManualDigitalPayment(cart, totalHarga, paymentType),
            ),
          ),
        ),
      ],
    );
  }
}
