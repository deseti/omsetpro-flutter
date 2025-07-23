// lib/services/payment_service_web.dart
// Implementasi untuk platform web

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'payment_service_interface.dart';
import '../providers/providers.dart';
import '../utils/api_config.dart';
// Conditional import untuk web
import 'dart:html' as html if (dart.library.html) 'dart:html';

class PaymentServiceWeb implements PaymentServiceInterface {
  final Ref _ref;

  PaymentServiceWeb(this._ref);

  @override
  bool get isSupported => kIsWeb;

  @override
  String get platformName => 'Web Browser';

  @override
  Future<void> initializePayment() async {
    // Tidak perlu inisialisasi khusus untuk web
    if (kDebugMode) {
      print('Payment service initialized for web platform');
    }
  }

  @override
  Future<PaymentResult> processPayment({
    required String orderId,
    required int totalAmount,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> customerDetails,
  }) async {
    if (!isSupported) {
      return PaymentResult(
        isSuccess: false,
        message: 'Web payment service tidak tersedia di platform ini',
      );
    }

    try {
      // Strategy 1: Redirect ke Midtrans Snap URL
      return await _redirectToSnapPayment(
        orderId: orderId,
        totalAmount: totalAmount,
        items: items,
        customerDetails: customerDetails,
      );
    } catch (e) {
      // Strategy 2: Manual payment entry
      return PaymentResult(
        isSuccess: false,
        message: 'Pembayaran digital tidak tersedia di web. '
                'Silakan gunakan aplikasi mobile atau catat transaksi secara manual.',
        additionalData: {
          'suggestedAction': 'manual_entry',
          'orderId': orderId,
          'totalAmount': totalAmount,
        },
      );
    }
  }

  Future<PaymentResult> _redirectToSnapPayment({
    required String orderId,
    required int totalAmount,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> customerDetails,
  }) async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post(
        '/midtrans/create-snap-url',  // Endpoint khusus untuk web
        data: {
          'orderId': orderId,
          'totalAmount': totalAmount,
          'items': items,
          'customerDetails': customerDetails,
          'platform': 'web',
        },
      );

      final snapUrl = response.data['snap_url'];
      if (snapUrl != null) {
        // Buka di tab/window baru
        html.window.open(snapUrl, '_blank');
        
        return PaymentResult(
          isSuccess: true,
          message: 'Halaman pembayaran telah dibuka di tab baru. '
                  'Silakan selesaikan pembayaran di tab tersebut.',
          transactionId: orderId,
          additionalData: {
            'action': 'redirected',
            'snapUrl': snapUrl,
          },
        );
      } else {
        throw Exception('Tidak mendapat URL pembayaran dari server');
      }
    } catch (e) {
      throw Exception('Gagal membuat URL pembayaran: $e');
    }
  }
}
