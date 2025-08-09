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
  // Nonaktifkan pembayaran digital Midtrans untuk semua platform
  // Hanya tersedia opsi pembayaran manual
  return [
    PaymentMethod.manual, // Pembayaran manual (Langsung/Tempo/Hutang)
  ];
});

// Provider untuk informasi platform
final platformInfoProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'isWeb': kIsWeb,
    'platform': kIsWeb ? 'web' : 'mobile',
    'digitalPaymentSupported': false, // Nonaktifkan pembayaran digital
    'features': {
      'midtrans': false, // Nonaktifkan Midtrans
      'manualEntry': true, // Aktifkan manual entry untuk tempo/hutang
      'cashPayment': true, // Aktifkan pembayaran tunai
    },
  };
});
