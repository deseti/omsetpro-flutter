// lib/services/payment_service_factory.dart
// Factory untuk memilih implementasi pembayaran yang tepat

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_service_interface.dart';
import 'payment_service_factory_mobile.dart' 
  if (dart.library.html) 'payment_service_factory_web.dart';

// Export PaymentServiceFactory dari file yang sesuai
export 'payment_service_factory_mobile.dart' 
  if (dart.library.html) 'payment_service_factory_web.dart';
// Provider untuk mendeteksi platform dan payment methods yang tersedia
final availablePaymentMethodsProvider = Provider<List<PaymentMethod>>((ref) {
  if (kIsWeb) {
    return [
      PaymentMethod.manual,  // Manual entry untuk web
      PaymentMethod.cash,    // Cash payment
    ];
  } else {
    return [
      PaymentMethod.digital, // Midtrans untuk mobile
      PaymentMethod.cash,    // Cash payment
    ];
  }
});

// Provider untuk informasi platform
final platformInfoProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'isWeb': kIsWeb,
    'platform': kIsWeb ? 'web' : 'mobile',
    'digitalPaymentSupported': !kIsWeb,
    'features': {
      'midtrans': !kIsWeb,
      'manualEntry': kIsWeb,
      'cashPayment': true,
    },
  };
});
