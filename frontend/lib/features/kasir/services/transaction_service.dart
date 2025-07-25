import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../models/pelanggan_model.dart';
import '../../../providers/providers.dart' as AppProviders;
import '../../../services/offline_database_proxy.dart' as OfflineDatabase;
import '../../../services/connectivity_service.dart';
import '../../../services/receipt_service.dart';
import '../../../services/midtrans_service.dart';
import '../../../widgets/receipt_preview_dialog.dart';
import '../../../utils/laporan_refresh_helper.dart';

class TransactionService {
  static Future<void> processTransaction({
    required BuildContext context,
    required WidgetRef ref,
    required int cabangId,
    required String cabangNama,
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
        'cabangId': cabangId,
        'metodeBayar':
            isDigitalPayment ? (paymentMethod ?? 'Digital') : 'Tunai',
        'items': itemsDto,
        'pelangganId': selectedPelanggan?.id,
        'orderId': orderId,
        'isDigitalPayment': isDigitalPayment,
      };

      if (isConnected) {
        await _processOnlineTransaction(
          context,
          ref,
          dio,
          requestData,
          cart,
          totalHarga,
          cabangId,
          cabangNama,
          scaffoldMessenger,
        );
      } else {
        await _processOfflineTransaction(
          context,
          ref,
          cabangId,
          cabangNama,
          cart,
          totalHarga,
          isDigitalPayment,
          paymentMethod,
          scaffoldMessenger,
        );
      }

      _clearCartAndRefresh(ref, cabangId);
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Terjadi kesalahan saat transaksi.';
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Error: $errorMessage'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  static Future<void> _processOnlineTransaction(
    BuildContext context,
    WidgetRef ref,
    Dio dio,
    Map<String, dynamic> requestData,
    List<Map<String, dynamic>> cart,
    int totalHarga,
    int cabangId,
    String cabangNama,
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    final response = await dio.post('/transaksi', data: requestData);
    final transaksiId =
        response.data['id'] ?? DateTime.now().millisecondsSinceEpoch;

    if (!context.mounted) return;

    scaffoldMessenger.showSnackBar(
      const SnackBar(
          content: Text('Transaksi berhasil!'), backgroundColor: Colors.green),
    );

    _showReceiptPreview(
      context: context,
      ref: ref,
      cart: cart,
      totalHarga: totalHarga,
      transaksiId: transaksiId,
      cabangNama: cabangNama,
    );

    LaporanRefreshHelper.refreshLaporanAfterTransaction(ref);
  }

  static Future<void> _processOfflineTransaction(
    BuildContext context,
    WidgetRef ref,
    int cabangId,
    String cabangNama,
    List<Map<String, dynamic>> cart,
    int totalHarga,
    bool isDigitalPayment,
    String? paymentMethod,
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    final transaksiId = DateTime.now().millisecondsSinceEpoch;

    await OfflineDatabase.OfflineDatabase.saveTransaksiOffline(
      cabangId: cabangId,
      metodeBayar: isDigitalPayment ? (paymentMethod ?? 'Digital') : 'Tunai',
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

    if (!context.mounted) return;

    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Transaksi disimpan offline - akan disync saat online'),
        backgroundColor: Colors.orange,
      ),
    );

    _showReceiptPreview(
      context: context,
      ref: ref,
      cart: cart,
      totalHarga: totalHarga,
      transaksiId: transaksiId,
      cabangNama: cabangNama,
    );
  }

  static Future<void> processDigitalTransaction({
    required BuildContext context,
    required WidgetRef ref,
    required int cabangId,
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

      _clearCartAndRefresh(ref, cabangId);
    } catch (e) {
      if (context.mounted) {
        String errorMessage = e.toString();

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

  static Future<void> processManualDigitalPayment({
    required BuildContext context,
    required WidgetRef ref,
    required int cabangId,
    required String cabangNama,
    required List<Map<String, dynamic>> cart,
    required int totalHarga,
    required String paymentType,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final orderId = 'MANUAL-${DateTime.now().millisecondsSinceEpoch}';

      await processTransaction(
        context: context,
        ref: ref,
        cabangId: cabangId,
        cabangNama: cabangNama,
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

  static void _showReceiptPreview({
    required BuildContext context,
    required WidgetRef ref,
    required List<Map<String, dynamic>> cart,
    required int totalHarga,
    required int transaksiId,
    required String cabangNama,
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
      namaCabang: cabangNama,
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

  static void _clearCartAndRefresh(WidgetRef ref, int cabangId) {
    ref.read(AppProviders.cartProvider.notifier).state = [];
    ref.read(AppProviders.selectedPelangganProvider.notifier).state = null;
    ref.invalidate(AppProviders.produkListWithOfflineProvider(cabangId));
  }
}
