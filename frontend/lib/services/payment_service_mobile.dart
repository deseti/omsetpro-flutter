// lib/services/payment_service_mobile.dart
// Implementasi untuk platform mobile (Android/iOS)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'payment_service_interface.dart';
import '../providers/providers.dart';
import '../utils/api_config.dart';
import 'dart:math';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class PaymentServiceMobile implements PaymentServiceInterface {
  final Ref _ref;
  MidtransSDK? _midtrans;

  PaymentServiceMobile(this._ref);

  @override
  bool get isSupported => !kIsWeb;

  @override
  String get platformName => 'Mobile (Android/iOS)';

  @override
  Future<void> initializePayment() async {
    if (!isSupported) return;

    try {
      print('🔧 Initializing Midtrans SDK...');
      
      // Delay untuk memastikan context Android sudah siap
      await Future.delayed(const Duration(milliseconds: 1000));
      
      const midtransClientKey = 'Mid-client-Pqcy5qa-KoOoRDpd';

      _midtrans = await MidtransSDK.init(
        config: MidtransConfig(
          clientKey: midtransClientKey,
          merchantBaseUrl: ApiConfig.baseUrl,
          colorTheme: ColorTheme(
            colorPrimary: Colors.blue,
            colorPrimaryDark: Colors.blue.shade700,
            colorSecondary: Colors.blue.shade200,
          ),
          enableLog: true, // Enable logging untuk debugging
        ),
      );
      
      print('✅ Midtrans SDK initialized successfully');
    } catch (e) {
      print('❌ Error initializing Midtrans SDK: $e');
      
      // Coba inisialisasi sekali lagi setelah delay
      try {
        await Future.delayed(const Duration(milliseconds: 2000));
        print('🔄 Retrying Midtrans SDK initialization...');
        
        const midtransClientKey = 'Mid-client-Pqcy5qa-KoOoRDpd';
        _midtrans = await MidtransSDK.init(
          config: MidtransConfig(
            clientKey: midtransClientKey,
            merchantBaseUrl: ApiConfig.baseUrl,
            colorTheme: ColorTheme(
              colorPrimary: Colors.blue,
              colorPrimaryDark: Colors.blue.shade700,
              colorSecondary: Colors.blue.shade200,
            ),
            enableLog: true,
          ),
        );
        
        print('✅ Midtrans SDK initialized successfully on retry');
      } catch (retryError) {
        print('❌ Retry failed: $retryError');
        throw Exception('Gagal menginisialisasi pembayaran digital. Coba restart aplikasi.');
      }
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
        message: 'Pembayaran digital tidak didukung di platform ini',
      );
    }

    try {
      print('🔄 Starting payment process for order: $orderId');
      print('💰 Total amount: $totalAmount');

      // Validasi SDK terlebih dahulu
      if (_midtrans == null) {
        print('⚠️ Midtrans SDK not initialized, initializing now...');
        try {
          await initializePayment();
          
          if (_midtrans == null) {
            throw Exception('Gagal menginisialisasi Midtrans SDK');
          }
        } catch (initError) {
          print('❌ Failed to initialize SDK, falling back to web payment');
          // Fallback: redirect ke web payment
          return _fallbackToWebPayment(orderId, totalAmount, items, customerDetails);
        }
      }

      // 1. Dapatkan token dari backend
      final dio = _ref.read(dioProvider);
      print('📡 Requesting snap token from backend...');
      
      final response = await dio.post(
        '/midtrans/create-transaction',
        data: {
          'orderId': orderId,
          'totalAmount': totalAmount,
          'items': items,
          'customerDetails': customerDetails,
        },
      );

      print('✅ Backend response received: ${response.statusCode}');
      final snapToken = response.data['token'] ?? response.data['snap_token'];
      if (snapToken == null) {
        print('❌ No snap token received from backend');
        print('📄 Response data: ${response.data}');
        throw Exception('Gagal mendapatkan token pembayaran dari server');
      }

      print('🎫 Snap token received: ${snapToken.toString().substring(0, 20)}...');

      // 2. Setup callback dengan Completer untuk async handling
      print('🔧 Setting up payment callback...');
      final paymentCompleter = Completer<PaymentResult>();

      _midtrans?.setTransactionFinishedCallback((transactionResult) {
        print('📞 Payment callback received: ${transactionResult.status}');
        print('📄 Transaction details: ${transactionResult.transactionId}');
        
        if (!paymentCompleter.isCompleted) {
          final result = PaymentResult(
            isSuccess: transactionResult.status == 'success' || transactionResult.status == 'settlement',
            transactionId: transactionResult.transactionId,
            message: transactionResult.message ?? 'Pembayaran selesai',
            additionalData: {
              'status': transactionResult.status,
              'orderId': orderId,
              'rawResponse': transactionResult.toString(),
            },
          );
          print('✅ Completing payment result: ${result.isSuccess}');
          paymentCompleter.complete(result);
        } else {
          print('⚠️ Payment completer already completed, ignoring callback');
        }
      });

      // 3. Mulai pembayaran
      print('🚀 Starting Midtrans payment UI...');
      try {
        await _midtrans?.startPaymentUiFlow(token: snapToken);
        print('🎯 Payment UI started successfully');
      } catch (e) {
        print('❌ Error starting payment UI: $e');
        if (!paymentCompleter.isCompleted) {
          paymentCompleter.complete(PaymentResult(
            isSuccess: false,
            message: 'Gagal membuka halaman pembayaran: $e',
          ));
        }
        return paymentCompleter.future;
      }

      // 4. Wait for callback dengan timeout yang lebih lama
      print('⏰ Waiting for payment result...');
      try {
        return await paymentCompleter.future.timeout(
          const Duration(minutes: 5), // Timeout 5 menit
          onTimeout: () {
            print('⏰ Payment timeout reached');
            return PaymentResult(
              isSuccess: false,
              message: 'Pembayaran dibatalkan atau timeout',
            );
          },
        );
      } catch (e) {
        return PaymentResult(
          isSuccess: false,
          message: 'Error saat pembayaran: $e',
        );
      }
    } on DioException catch (e) {
      print('DioException: ${e.response?.data}');
      return PaymentResult(
        isSuccess: false,
        message: 'Gagal menghubungi server pembayaran: ${e.message}',
      );
    } catch (e) {
      print('Payment error: $e');
      return PaymentResult(
        isSuccess: false,
        message: 'Terjadi kesalahan saat memproses pembayaran: $e',
      );
    }
  }

  // Fallback method untuk menggunakan web payment jika SDK gagal
  Future<PaymentResult> _fallbackToWebPayment(
    String orderId,
    int totalAmount,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> customerDetails,
  ) async {
    try {
      print('🌐 Using web payment fallback...');
      
      final dio = _ref.read(dioProvider);
      final response = await dio.post('/midtrans/create-snap-url', data: {
        'orderId': orderId,
        'totalAmount': totalAmount,
        'items': items,
        'customerDetails': customerDetails,
        'platform': 'mobile_fallback',
      });

      final snapUrl = response.data['snap_url'];
      if (snapUrl != null) {
        // Buka URL di browser eksternal
        print('📱 Opening payment URL in external browser: $snapUrl');
        
        final uri = Uri.parse(snapUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          return PaymentResult(
            isSuccess: true,
            message: 'Halaman pembayaran telah dibuka di browser. Silakan selesaikan pembayaran di browser tersebut.',
            transactionId: orderId,
            additionalData: {
              'action': 'external_browser',
              'snapUrl': snapUrl,
              'fallback': true,
            },
          );
        } else {
          return PaymentResult(
            isSuccess: true,
            message: 'Salin dan buka link berikut di browser:\n$snapUrl',
            transactionId: orderId,
            additionalData: {
              'action': 'copy_url',
              'snapUrl': snapUrl,
              'fallback': true,
            },
          );
        }
      } else {
        throw Exception('Gagal mendapatkan URL pembayaran');
      }
    } catch (e) {
      print('❌ Fallback payment failed: $e');
      return PaymentResult(
        isSuccess: false,
        message: 'Pembayaran digital tidak tersedia saat ini. Gunakan pembayaran tunai.',
      );
    }
  }
}
