// lib/services/payment_service_webview.dart
// Implementasi alternative menggunakan WebView internal

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'payment_service_interface.dart';
import '../providers/providers.dart';
import '../utils/api_config.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class PaymentServiceWebView implements PaymentServiceInterface {
  final Ref _ref;

  PaymentServiceWebView(this._ref);

  @override
  bool get isSupported => !kIsWeb;

  @override
  String get platformName => 'WebView Payment';

  @override
  Future<void> initializePayment() async {
    // Tidak perlu inisialisasi khusus untuk WebView
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
        message: 'Pembayaran tidak didukung di platform ini',
      );
    }

    try {
      print('🔄 Starting WebView payment for order: $orderId');
      print('💰 Total amount: $totalAmount');

      // 1. Dapatkan snap URL dari backend
      final dio = _ref.read(dioProvider);
      print('📡 Requesting snap URL from backend...');
      
      final response = await dio.post('/midtrans/create-snap-url', data: {
        'orderId': orderId,
        'totalAmount': totalAmount,
        'items': items,
        'customerDetails': customerDetails,
        'platform': 'mobile_webview',
      });

      print('✅ Backend response received: ${response.statusCode}');
      final snapUrl = response.data['snap_url'];
      if (snapUrl == null) {
        print('❌ No snap URL received from backend');
        throw Exception('Gagal mendapatkan URL pembayaran dari server');
      }

      print('🌐 Snap URL received: $snapUrl');

      // 2. Buka URL di browser eksternal atau internal
      final uri = Uri.parse(snapUrl);
      
      try {
        print('📱 Attempting to open payment URL in browser');
        
        // Coba buka dengan mode external application
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
        
        if (launched) {
          print('✅ Successfully opened payment URL in browser');
          return PaymentResult(
            isSuccess: true,
            message: 'Halaman pembayaran telah dibuka di browser. '
                'Silakan selesaikan pembayaran dan kembali ke aplikasi.',
            transactionId: orderId,
            additionalData: {
              'action': 'external_browser',
              'snapUrl': snapUrl,
              'method': 'webview',
            },
          );
        } else {
          throw Exception('Failed to launch URL');
        }
      } catch (e) {
        print('❌ Failed to open URL: $e');
        
        // Fallback: Return URL untuk disalin manual
        return PaymentResult(
          isSuccess: true,
          message: 'Salin dan buka link pembayaran berikut di browser:\n\n$snapUrl\n\n'
              'Setelah pembayaran selesai, kembali ke aplikasi.',
          transactionId: orderId,
          additionalData: {
            'action': 'copy_url',
            'snapUrl': snapUrl,
            'method': 'manual_copy',
          },
        );
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.response?.data}');
      return PaymentResult(
        isSuccess: false,
        message: 'Gagal menghubungi server pembayaran: ${e.message}',
      );
    } catch (e) {
      print('❌ Payment error: $e');
      return PaymentResult(
        isSuccess: false,
        message: 'Terjadi kesalahan saat memproses pembayaran: $e',
      );
    }
  }
}
