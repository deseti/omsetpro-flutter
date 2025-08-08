import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../models/toko_online_model.dart';
import '../../../services/toko_online_service.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/api_config.dart';
import '../widgets/checkout_sections.dart';

class CheckoutBottomSheet extends ConsumerStatefulWidget {
  final List<CartItem> cart;
  final TokoOnlineData toko;
  final VoidCallback onOrderPlaced;

  const CheckoutBottomSheet({
    super.key,
    required this.cart,
    required this.toko,
    required this.onOrderPlaced,
  });

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
                        CartItemsSection(cart: widget.cart),
                        const SizedBox(height: 24),

                        // Customer info
                        CustomerFormSection(
                          namaController: _namaController,
                          hpController: _hpController,
                        ),
                        const SizedBox(height: 24),

                        // Delivery options
                        DeliveryOptionsSection(
                          toko: widget.toko,
                          selectedTipe: _tipePengiriman,
                          onTipeChanged: (value) {
                            setState(() {
                              _tipePengiriman = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Payment info
                        PaymentInfoSection(toko: widget.toko),
                        const SizedBox(height: 24),

                        // Total
                        TotalSection(totalPrice: totalPrice),
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
