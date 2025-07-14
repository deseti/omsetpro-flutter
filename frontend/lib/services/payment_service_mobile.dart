// lib/services/payment_service_mobile.dart
// Implementasi untuk platform mobile (Android/iOS)

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'payment_service_interface.dart';
import '../providers/providers.dart';
import '../utils/api_config.dart';
import 'dart:math';

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
      const midtransClientKey = "Mid-client-Pqcy5qa-KoOoRDpd";
      
      _midtrans = await MidtransSDK.init(
        config: MidtransConfig(
          clientKey: midtransClientKey,
          merchantBaseUrl: ApiConfig.baseUrl,
        ),
      );
    } catch (e) {
      print('Error initializing Midtrans SDK: $e');
      throw Exception('Gagal menginisialisasi pembayaran digital');
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
      // 1. Dapatkan token dari backend
      final dio = _ref.read(dioProvider);
      final response = await dio.post(
        '/midtrans/create-transaction',
        data: {
          'orderId': orderId,
          'totalAmount': totalAmount,
          'items': items,
          'customerDetails': customerDetails,
        },
      );

      final snapToken = response.data['token'] ?? response.data['snap_token'];
      if (snapToken == null) {
        throw Exception('Gagal mendapatkan token pembayaran dari server');
      }

      // 2. Setup callback
      bool paymentCompleted = false;
      PaymentResult? result;

      _midtrans?.setTransactionFinishedCallback((transactionResult) {
        paymentCompleted = true;
        result = PaymentResult(
          isSuccess: transactionResult.status == 'success',
          transactionId: transactionResult.transactionId,
          message: transactionResult.message,
          additionalData: {
            'status': transactionResult.status,
            'orderId': orderId,
          },
        );
      });

      // 3. Mulai pembayaran
      await _midtrans?.startPaymentUiFlow(token: snapToken);

      // 4. Wait for callback (dengan timeout)
      int waitTime = 0;
      while (!paymentCompleted && waitTime < 30000) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitTime += 100;
      }

      return result ?? PaymentResult(
        isSuccess: false,
        message: 'Timeout menunggu hasil pembayaran',
      );

    } on DioError catch (e) {
      print('DioError: ${e.response?.data}');
      return PaymentResult(
        isSuccess: false,
        message: 'Gagal menghubungi server pembayaran',
      );
    } catch (e) {
      print('Payment error: $e');
      return PaymentResult(
        isSuccess: false,
        message: 'Terjadi kesalahan saat memproses pembayaran: $e',
      );
    }
  }
}
