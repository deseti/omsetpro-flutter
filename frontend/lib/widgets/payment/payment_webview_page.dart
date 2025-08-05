// lib/widgets/payment/payment_webview_page.dart
// Halaman WebView untuk pembayaran digital di mobile

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/payment_service_interface.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String snapUrl;
  final String orderId;
  final Function(PaymentResult) onResult;

  const PaymentWebViewPage({
    super.key,
    required this.snapUrl,
    required this.orderId,
    required this.onResult,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _title = 'Pembayaran Digital';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            print('🌐 Page started loading: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print('✅ Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
            
            // Check if payment is completed based on URL
            _checkPaymentStatus(url);
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔄 Navigation request: ${request.url}');
            
            // Allow all navigation for payment flow
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.snapUrl));
  }

  void _checkPaymentStatus(String url) {
    // Check URL patterns to determine payment status
    if (url.contains('/finish') || 
        url.contains('status_code=200') ||
        url.contains('transaction_status=settlement') ||
        url.contains('transaction_status=capture')) {
      // Payment successful
      print('✅ Payment successful detected from URL: $url');
      widget.onResult(PaymentResult(
        isSuccess: true,
        message: 'Pembayaran berhasil!',
        transactionId: widget.orderId,
        additionalData: {
          'finalUrl': url,
          'platform': 'mobile_webview',
        },
      ));
      Navigator.of(context).pop();
    } else if (url.contains('/unfinish') || 
               url.contains('status_code=201') ||
               url.contains('transaction_status=pending')) {
      // Payment pending/unfinished
      print('⏳ Payment pending detected from URL: $url');
      widget.onResult(PaymentResult(
        isSuccess: false,
        message: 'Pembayaran belum selesai atau dibatalkan',
        transactionId: widget.orderId,
        additionalData: {
          'finalUrl': url,
          'platform': 'mobile_webview',
          'status': 'pending',
        },
      ));
      Navigator.of(context).pop();
    } else if (url.contains('/error') || 
               url.contains('status_code=400') ||
               url.contains('transaction_status=deny') ||
               url.contains('transaction_status=cancel') ||
               url.contains('transaction_status=expire')) {
      // Payment failed
      print('❌ Payment failed detected from URL: $url');
      widget.onResult(PaymentResult(
        isSuccess: false,
        message: 'Pembayaran gagal atau dibatalkan',
        transactionId: widget.orderId,
        additionalData: {
          'finalUrl': url,
          'platform': 'mobile_webview',
          'status': 'failed',
        },
      ));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // User cancelled payment
            widget.onResult(PaymentResult(
              isSuccess: false,
              message: 'Pembayaran dibatalkan oleh pengguna',
              transactionId: widget.orderId,
              additionalData: {
                'platform': 'mobile_webview',
                'status': 'cancelled',
              },
            ));
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat halaman pembayaran...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
