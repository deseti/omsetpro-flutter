import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../providers/providers.dart' as AppProviders;
import '../../services/sync_service.dart';
import '../../services/midtrans_service.dart';
import '../../widgets/responsive_widgets.dart';
import '../../theme/app_theme.dart';
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
    });
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

  void _processDigitalTransaction({
    required List<Map<String, dynamic>> cart,
    required int totalHarga,
  }) {
    TransactionService.processDigitalTransaction(
      context: context,
      ref: ref,
      cabangId: widget.cabangId,
      cart: cart,
      totalHarga: totalHarga,
    );
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
        // Product Grid sebagai tab atau section atas
        Expanded(
          flex: 2,
          child: ProductGridWidget(
            cabangId: widget.cabangId,
            searchController: _searchController,
            searchQuery: _searchQuery,
          ),
        ),
        // Cart Section sebagai bottom sheet atau section bawah
        Container(
          height: 200, // Fixed height untuk cart
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
            onDigitalPayment: () =>
                _processDigitalTransaction(cart: cart, totalHarga: totalHarga),
            onManualPayment: (paymentType) =>
                _processManualDigitalPayment(cart, totalHarga, paymentType),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    // Format mata uang sesuai kebutuhan Anda
    return 'Rp ${amount.toString().replaceAllMapped(
          RegExp(r'(\d+)(\d{3})'),
          (Match m) => '${m[1]}.${m[2]}',
        )}';
  }
}
