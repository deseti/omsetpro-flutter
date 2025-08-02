// lib/services/payment_service_factory_mobile.dart
// Factory untuk platform mobile

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_service_interface.dart';
import 'payment_service_mobile.dart';
import 'payment_service_webview.dart';

class PaymentServiceFactory {
  static PaymentServiceInterface createPaymentService(Ref ref) {
    // Gunakan WebView service sebagai default karena lebih stabil
    // Fallback ke native SDK jika dibutuhkan
    return PaymentServiceWebView(ref);
  }
}
