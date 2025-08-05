// lib/services/payment_service_mobile_webview.dart
// Implementasi payment dengan webview internal untuk mobile

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'payment_service_interface.dart';
import '../providers/providers.dart';
import 'dart:async';

class PaymentServiceMobileWebview implements PaymentServiceInterface {
  final Ref _ref;

  PaymentServiceMobileWebview(this._ref);

  @override
  bool get isSupported => !kIsWeb;

  @override
  String get platformName => 'Mobile WebView';

  @override
  Future<void> initializePayment() async {
    // No initialization needed for webview
    print('✅ WebView payment service ready');
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
        message: 'Pembayaran digital tidak didukung di platform ini',
      );
    }

    try {
      print('🔄 Starting webview payment process for order: $orderId');
      print('💰 Total amount: $totalAmount');

      // 1. Dapatkan snap URL dari backend
      final dio = _ref.read(dioProvider);
      print('📡 Requesting snap URL from backend...');
      
      final response = await dio.post(
        '/midtrans/create-transaction',
        data: {
          'orderId': orderId,
          'totalAmount': totalAmount,
          'items': items,
          'customerDetails': customerDetails,
          'platform': 'mobile_webview',
        },
      );

      print('✅ Backend response received: ${response.statusCode}');
      final snapUrl = response.data['snap_url'] ?? response.data['redirect_url'];
      if (snapUrl == null) {
        print('❌ No snap URL received from backend');
        print('📄 Response data: ${response.data}');
        throw Exception('Gagal mendapatkan URL pembayaran dari server');
      }

      print('🌐 Snap URL received: $snapUrl');

      // 2. Return URL untuk dibuka di WebView oleh calling widget
      return PaymentResult(
        isSuccess: true,
        message: 'URL pembayaran siap dibuka',
        transactionId: orderId,
        additionalData: {
          'snapUrl': snapUrl,
          'platform': 'mobile_webview',
          'action': 'open_webview',
        },
      );

    } catch (e) {
      print('❌ WebView payment failed: $e');
      return PaymentResult(
        isSuccess: false,
        message: 'Pembayaran digital tidak tersedia saat ini: $e',
      );
    }
  }
}
