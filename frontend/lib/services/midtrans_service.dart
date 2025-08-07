// lib/services/midtrans_service.dart
// Wrapper service yang menggunakan factory pattern untuk multi-platform support

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_service_factory.dart';
import 'payment_service_interface.dart';
import 'dart:math';

// Provider untuk MidtransService agar tetap kompatibel dengan kode yang sudah ada
final midtransServiceProvider = Provider((ref) => MidtransService(ref));

class MidtransService {
  final Ref _ref;
  late final PaymentServiceInterface _paymentService;

  MidtransService(this._ref) {
    _paymentService = PaymentServiceFactory.createPaymentService(_ref);
    _paymentService.initializePayment();
  }

  // [MODIFIKASI] Mengubah fungsi ini agar mengembalikan PaymentResult
  // Ini membuatnya lebih informatif dan bisa ditangani oleh pemanggilnya.
  Future<PaymentResult> startPayment({
    required int totalAmount,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> customerDetails,
  }) async {
    final orderId =
        'OMSETPRO-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';

    // Langsung memanggil dan mengembalikan hasil dari service platform-specific
    final result = await _paymentService.processPayment(
      orderId: orderId,
      totalAmount: totalAmount,
      items: items,
      customerDetails: customerDetails,
    );

    // [PERBAIKAN] Pastikan orderId dikembalikan sebagai transactionId
    final updatedResult = PaymentResult(
      isSuccess: result.isSuccess,
      transactionId: orderId, // Gunakan orderId yang kita generate
      message: result.message,
      additionalData: result.additionalData,
    );

    // Log untuk debugging, bisa dihapus jika tidak perlu
    if (kDebugMode) {
      if (updatedResult.isSuccess) {
        print('Payment initiation successful: ${updatedResult.transactionId}');
        print('Message: ${updatedResult.message}');
      } else {
        print('Payment initiation failed: ${updatedResult.message}');
      }
    }

    return updatedResult;
  }

  // Method tambahan untuk mendapatkan informasi platform
  bool get isDigitalPaymentSupported => _paymentService.isSupported && !kIsWeb;
  String get platformName => _paymentService.platformName;

  // Method ini sudah benar, kita gunakan sebagai referensi.
  // Kita membuat startPayment berperilaku sama seperti ini.
  Future<PaymentResult> processPaymentWithResult({
    required int totalAmount,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> customerDetails,
  }) async {
    final orderId =
        'OMSETPRO-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';

    return await _paymentService.processPayment(
      orderId: orderId,
      totalAmount: totalAmount,
      items: items,
      customerDetails: customerDetails,
    );
  }
}
