// lib/services/payment_service_interface.dart
// Abstract interface untuk semua implementasi pembayaran

abstract class PaymentServiceInterface {
  Future<void> initializePayment();

  Future<PaymentResult> processPayment({
    required String orderId,
    required int totalAmount,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> customerDetails,
  });

  bool get isSupported;
  String get platformName;
}

class PaymentResult {
  final bool isSuccess;
  final String? transactionId;
  final String? message;
  final Map<String, dynamic>? additionalData;

  PaymentResult({
    required this.isSuccess,
    this.transactionId,
    this.message,
    this.additionalData,
  });
}

enum PaymentMethod {
  cash, // Pembayaran tunai langsung
  manual, // Pembayaran tempo/hutang (manual entry)
}
