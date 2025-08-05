// lib/services/payment_service_web.dart
// Implementasi untuk platform web menggunakan Snap.js

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'payment_service_interface.dart';
import '../providers/providers.dart';
import '../utils/api_config.dart';
import 'dart:async';
// Conditional import untuk web - Suppress lint warning karena ini file khusus web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class PaymentServiceWeb implements PaymentServiceInterface {
  final Ref _ref;

  PaymentServiceWeb(this._ref);

  @override
  bool get isSupported => kIsWeb;

  @override
  String get platformName => 'Web Browser (Snap.js)';

  @override
  Future<void> initializePayment() async {
    if (kDebugMode) {
      print('✅ Payment service initialized for web platform with Snap.js');
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
      print('🔄 Starting web payment for order: $orderId');
      
      // PERUBAHAN: Langsung gunakan redirect method yang sudah terbukti bekerja
      // Snap.js popup sudah muncul tapi ada masalah dengan callback detection
      return await _redirectToSnapPayment(
        orderId: orderId,
        totalAmount: totalAmount,
        items: items,
        customerDetails: customerDetails,
      );
    } catch (e) {
      print('❌ Web payment failed: $e');
      return PaymentResult(
        isSuccess: false,
        message: 'Pembayaran digital tidak tersedia saat ini. '
            'Error: ${e.toString()}',
        additionalData: {
          'error': e.toString(),
        },
      );
    }
  }

  Future<PaymentResult> _processSnapPayment({
    required String orderId,
    required int totalAmount,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> customerDetails,
  }) async {
    try {
      print('🔄 Creating Snap token for web payment...');
      
      final dio = _ref.read(dioProvider);
      final response = await dio.post(
        '/midtrans/create-snap-url', // Endpoint untuk mendapatkan snap token
        data: {
          'orderId': orderId,
          'totalAmount': totalAmount,
          'items': items,
          'customerDetails': customerDetails,
          'platform': 'web',
        },
      );

      print('✅ Backend response received: ${response.statusCode}');
      
      // Cek apakah response berisi snap_token
      final snapToken = response.data['snap_token'] ?? response.data['token'];
      final snapUrl = response.data['snap_url'];
      
      if (snapToken != null) {
        // Gunakan Snap.js untuk memproses pembayaran
        print('🎫 Using Snap.js with token: ${snapToken.toString().substring(0, 20)}...');
        
        // Panggil snapPay() dari JavaScript dan tunggu callback
        final completer = Completer<PaymentResult>();
        
        // Gunakan fungsi snapPay yang sudah diperbaiki
        js.context.callMethod('snapPay', [
          snapToken, 
          js.allowInterop((result) {
            if (completer.isCompleted) return; // Prevent multiple completions
            
            print('✅ Snap.js payment callback triggered');
            print('🔍 Raw result type: ${result.runtimeType}');
            print('🔍 Raw result content: $result');
            
            try {
              // Parse result dengan aman
              String status = 'unknown';
              dynamic paymentResult;
              
              if (result != null) {
                print('🔍 Analyzing JS result object...');
                
                // Jika result adalah Map/JsObject, ekstrak status
                if (result is Map) {
                  print('📋 Result is Map: $result');
                  status = result['status']?.toString() ?? 'unknown';
                  paymentResult = result['result'];
                } else {
                  // Jika result adalah object JS, coba konversi
                  try {
                    final jsResult = result as js.JsObject;
                    print('🔧 Result is JsObject, checking properties...');
                    
                    // Coba ekstrak semua properti yang mungkin ada
                    final statusProp = jsResult['status'];
                    final resultProp = jsResult['result'];
                    final messageProp = jsResult['message'];
                    final errorProp = jsResult['error'];
                    
                    print('🔧 status: $statusProp');
                    print('🔧 result: $resultProp');
                    print('🔧 message: $messageProp');
                    print('🔧 error: $errorProp');
                    
                    status = statusProp?.toString() ?? 'unknown';
                    paymentResult = resultProp;
                    
                    // Jika masih unknown, coba cek apakah ini adalah response payment langsung
                    if (status == 'unknown' && jsResult.hasProperty('transaction_status')) {
                      final transStatus = jsResult['transaction_status'];
                      print('🔧 Found transaction_status: $transStatus');
                      status = transStatus?.toString() ?? 'unknown';
                      paymentResult = result;
                    }
                    
                  } catch (e) {
                    print('⚠️ Could not parse JS result as JsObject: $e');
                    print('⚠️ Treating as payment popup result');
                    
                    // Kemungkinan ini adalah result langsung dari payment popup
                    // Yang berarti user berhasil menyelesaikan payment flow
                    status = 'success';
                    paymentResult = result;
                  }
                }
              }
              
              print('🎯 Final parsed status: $status');
              
              if (status == 'success') {
                completer.complete(PaymentResult(
                  isSuccess: true,
                  message: 'Pembayaran berhasil! Transaksi akan segera diproses.',
                  transactionId: orderId,
                  additionalData: {
                    'action': 'payment_success',
                    'snapToken': snapToken,
                    'method': 'snap_js',
                    'result': paymentResult?.toString() ?? 'success',
                  },
                ));
              } else if (status == 'pending') {
                completer.complete(PaymentResult(
                  isSuccess: true,
                  message: 'Pembayaran dalam proses. Silakan tunggu konfirmasi.',
                  transactionId: orderId,
                  additionalData: {
                    'action': 'payment_pending',
                    'snapToken': snapToken,
                    'method': 'snap_js',
                    'result': paymentResult?.toString() ?? 'pending',
                  },
                ));
              } else if (status == 'closed') {
                completer.complete(PaymentResult(
                  isSuccess: false,
                  message: 'Pembayaran dibatalkan oleh pengguna.',
                  transactionId: orderId,
                  additionalData: {
                    'action': 'payment_cancelled',
                    'method': 'snap_js',
                  },
                ));
              } else if (status == 'error') {
                completer.complete(PaymentResult(
                  isSuccess: false,
                  message: 'Pembayaran gagal. Silakan coba lagi.',
                  transactionId: orderId,
                  additionalData: {
                    'action': 'payment_error',
                    'method': 'snap_js',
                    'error': result?.toString() ?? 'unknown error',
                  },
                ));
              } else if (status == 'unknown' && result != null) {
                // Jika ada result tapi status unknown, anggap sebagai success
                print('⚠️ Unknown status but result exists, treating as success');
                completer.complete(PaymentResult(
                  isSuccess: true,
                  message: 'Pembayaran berhasil! Pop-up telah ditutup.',
                  transactionId: orderId,
                  additionalData: {
                    'action': 'payment_success',
                    'snapToken': snapToken,
                    'method': 'snap_js',
                    'result': result?.toString() ?? 'success_unknown_status',
                  },
                ));
              } else {
                completer.complete(PaymentResult(
                  isSuccess: false,
                  message: 'Status pembayaran tidak dikenal.',
                  transactionId: orderId,
                  additionalData: {
                    'action': 'payment_unknown',
                    'method': 'snap_js',
                    'error': 'Unknown status: $status',
                  },
                ));
              }
            } catch (e) {
              print('❌ Error parsing Snap.js result: $e');
              completer.complete(PaymentResult(
                isSuccess: false,
                message: 'Error memproses hasil pembayaran: $e',
                transactionId: orderId,
                additionalData: {
                  'action': 'payment_parse_error',
                  'method': 'snap_js',
                  'error': e.toString(),
                },
              ));
            }
          })
        ]);
        
        // Timeout setelah 10 menit jika tidak ada response
        Timer(const Duration(minutes: 10), () {
          if (!completer.isCompleted) {
            completer.complete(PaymentResult(
              isSuccess: false,
              message: 'Timeout pembayaran. Silakan coba lagi.',
              transactionId: orderId,
            ));
          }
        });
        
        return await completer.future;
      } else if (snapUrl != null) {
        // Fallback ke redirect jika tidak ada token
        return await _redirectToSnapPayment(
          orderId: orderId,
          totalAmount: totalAmount,
          items: items,
          customerDetails: customerDetails,
        );
      } else {
        throw Exception('Tidak mendapat snap token atau URL dari server');
      }
    } catch (e) {
      print('❌ Snap.js processing error: $e');
      rethrow;
    }
  }

  Future<PaymentResult> _redirectToSnapPayment({
    required String orderId,
    required int totalAmount,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> customerDetails,
  }) async {
    try {
      print('🌐 Using redirect payment method...');
      
      final dio = _ref.read(dioProvider);
      final response = await dio.post(
        '/midtrans/create-snap-url',
        data: {
          'orderId': orderId,
          'totalAmount': totalAmount,
          'items': items,
          'customerDetails': customerDetails,
          'platform': 'web_redirect',
        },
      );

      final snapUrl = response.data['snap_url'];
      if (snapUrl != null) {
        print('🚀 Opening Snap payment page: $snapUrl');
        
        // Buka di tab/window yang sama untuk pengalaman yang lebih seamless
        html.window.location.assign(snapUrl);

        return PaymentResult(
          isSuccess: true,
          message: 'Mengarahkan ke halaman pembayaran...',
          transactionId: orderId,
          additionalData: {
            'action': 'redirected',
            'snapUrl': snapUrl,
            'method': 'redirect',
            'note': 'Transaksi akan ter-update otomatis setelah pembayaran selesai',
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
