import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../models/pelanggan_model.dart';
import '../../../providers/providers.dart' as AppProviders;
import '../../../services/offline_database_proxy.dart' as OfflineDatabase;
import '../../../services/connectivity_service.dart';
import '../../../services/receipt_service.dart';
import '../../../services/midtrans_service.dart';
import '../../../services/payment_service_interface.dart';
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
    String? paymentMethod, // Ini akan berisi 'QRIS', 'Transfer Bank', dll.
    String? orderId,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final selectedPelanggan = ref.read(AppProviders.selectedPelangganProvider);

    try {
      final dio = ref.read(AppProviders.dioProvider);
      final isConnected = await ConnectivityService.isConnected();

      // [MODIFIKASI] Logika penentuan metode bayar yang lebih lugas
      final String metodeBayarUntukStruk;
      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        metodeBayarUntukStruk = paymentMethod;
      } else if (isDigitalPayment) {
        metodeBayarUntukStruk = 'Digital';
      } else {
        metodeBayarUntukStruk = 'Tunai';
      }

      final itemsDto = cart
          .map((item) => {
                'produkId': item['produk']['id'],
                'jumlah': item['jumlah'],
              })
          .toList();

      final requestData = {
        'cabangId': cabangId,
        'metodeBayar': metodeBayarUntukStruk, // Gunakan variabel yang sudah pasti
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
            metodeBayarUntukStruk // Kirim metode bayar ke struk
            );
      } else {
        await _processOfflineTransaction(
            context,
            ref,
            cabangId,
            cabangNama,
            cart,
            totalHarga,
            scaffoldMessenger,
            metodeBayarUntukStruk // Kirim metode bayar ke struk
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
    String metodeBayar, // [BARU] Terima metode bayar
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
      metodeBayar: metodeBayar, // [BARU] Kirim ke struk
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
    ScaffoldMessengerState scaffoldMessenger,
    String metodeBayar, // [BARU] Terima metode bayar
  ) async {
    final transaksiId = DateTime.now().millisecondsSinceEpoch;

    await OfflineDatabase.OfflineDatabase.saveTransaksiOffline(
      cabangId: cabangId,
      metodeBayar: metodeBayar,
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
      metodeBayar: metodeBayar, // [BARU] Kirim ke struk
    );
  }

  static Future<PaymentResult> processDigitalTransaction({
    required BuildContext context,
    required WidgetRef ref,
    required List<Map<String, dynamic>> cart,
    required int totalHarga,
    required int cabangId, // [PERBAIKAN] Tambahkan cabangId parameter
  }) async {
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
      final paymentResult = await midtransService.startPayment(
        totalAmount: totalHarga,
        items: itemDetails,
        customerDetails: customerDetails,
      );
      
      // [PERBAIKAN] Simpan transaksi ke database dengan orderId dari payment
      if (paymentResult.isSuccess && paymentResult.transactionId != null) {
        await _saveDigitalTransactionToDatabase(
          ref: ref,
          cart: cart,
          totalHarga: totalHarga,
          orderId: paymentResult.transactionId!,
          selectedPelanggan: selectedPelanggan,
          cabangId: cabangId, // Gunakan cabangId dari parameter
        );
      }
      
      return paymentResult;
    } catch (e) {
      return PaymentResult(
        isSuccess: false,
        message: 'Error memulai pembayaran: ${e.toString()}',
      );
    }
  }

  // [BARU] Helper function untuk menyimpan transaksi digital ke database
  static Future<void> _saveDigitalTransactionToDatabase({
    required WidgetRef ref,
    required List<Map<String, dynamic>> cart,
    required int totalHarga,
    required String orderId,
    required Pelanggan? selectedPelanggan,
    required int cabangId,
  }) async {
    try {
      final dio = ref.read(AppProviders.dioProvider);
      
      final itemsDto = cart
          .map((item) => {
                'produkId': item['produk']['id'],
                'jumlah': item['jumlah'],
              })
          .toList();

      final requestData = {
        'cabangId': cabangId,
        'metodeBayar': 'Digital', // Pembayaran digital
        'items': itemsDto,
        'pelangganId': selectedPelanggan?.id,
        'orderId': orderId, // [PENTING] Kirim orderId ke backend
      };

      print('🔄 Saving digital transaction to database with orderId: $orderId');
      final response = await dio.post('/transaksi', data: requestData);
      print('✅ Digital transaction saved to database: ${response.data}');
      
      // Refresh laporan setelah transaksi tersimpan
      LaporanRefreshHelper.refreshLaporanAfterTransaction(ref);
    } catch (e) {
      print('❌ Error saving digital transaction to database: $e');
      // Don't throw error karena payment sudah berhasil
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
    // Untuk pembayaran manual, kita langsung proses transaksinya
    // karena kita tidak perlu menunggu konfirmasi dari payment gateway.
    // Kita anggap pembayaran sudah diterima secara manual oleh kasir.
    await processTransaction(
      context: context,
      ref: ref,
      cabangId: cabangId,
      cabangNama: cabangNama,
      cart: cart,
      totalHarga: totalHarga,
      isDigitalPayment: true,
      paymentMethod: paymentType, // Ini akan berisi "QRIS", "Transfer Bank", dll.
      orderId: 'MANUAL-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static void _showReceiptPreview({
    required BuildContext context,
    required WidgetRef ref,
    required List<Map<String, dynamic>> cart,
    required int totalHarga,
    required int transaksiId,
    required String cabangNama,
    required String metodeBayar, // [BARU] Terima parameter ini
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
      metodeBayar: metodeBayar, // [BARU] Kirim ke service struk
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
