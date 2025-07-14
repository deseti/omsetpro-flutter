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

  // Metode yang kompatibel dengan kode lama
  Future<void> startPayment({
    required int totalAmount,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> customerDetails,
  }) async {
    final orderId = 'OMSETPRO-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';

    final result = await _paymentService.processPayment(
      orderId: orderId,
      totalAmount: totalAmount,
      items: items,
      customerDetails: customerDetails,
    );

    if (!result.isSuccess) {
      throw Exception(result.message ?? 'Pembayaran gagal');
    }

    // Jika berhasil, tidak ada exception yang dilempar
    if (kDebugMode) {
      print('Payment successful: ${result.transactionId}');
      print('Message: ${result.message}');
    }
  }

  // Method tambahan untuk mendapatkan informasi platform
  bool get isDigitalPaymentSupported => _paymentService.isSupported && !kIsWeb;
  String get platformName => _paymentService.platformName;
  
  // Method untuk mendapatkan payment result langsung
  Future<PaymentResult> processPaymentWithResult({
    required int totalAmount,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> customerDetails,
  }) async {
    final orderId = 'OMSETPRO-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';
    
    return await _paymentService.processPayment(
      orderId: orderId,
      totalAmount: totalAmount,
      items: items,
      customerDetails: customerDetails,
    );
  }
}