// lib/services/payment_service_factory_mobile.dart
// Factory untuk platform mobile

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_service_interface.dart';
import 'payment_service_mobile.dart';
import 'payment_service_mobile_webview.dart';
import 'payment_service_webview.dart';

class PaymentServiceFactory {
  static PaymentServiceInterface createPaymentService(Ref ref) {
    // Gunakan Mobile WebView service untuk pengalaman dalam app
    // Ini memberikan experience seperti web tapi tetap dalam aplikasi
    return PaymentServiceMobileWebview(ref);
  }
}
