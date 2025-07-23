// lib/services/payment_service_factory_web.dart
// Factory untuk platform web

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_service_interface.dart';
import 'payment_service_web.dart';

class PaymentServiceFactory {
  static PaymentServiceInterface createPaymentService(Ref ref) {
    return PaymentServiceWeb(ref);
  }
}
