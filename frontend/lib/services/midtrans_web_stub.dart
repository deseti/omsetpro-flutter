// Stub file untuk platform web - menggantikan midtrans_sdk
// File ini akan digunakan ketika aplikasi berjalan di web

class MidtransSDK {
  static Future<MidtransSDK> init({required MidtransConfig config}) async {
    throw UnsupportedError('Midtrans SDK tidak didukung di platform web');
  }
  
  void setTransactionFinishedCallback(Function(dynamic) callback) {
    // No-op untuk web
  }
  
  Future<void> startPaymentUiFlow({required String token}) async {
    throw UnsupportedError('Midtrans SDK tidak didukung di platform web');
  }
}

class MidtransConfig {
  final String clientKey;
  final String merchantBaseUrl;
  
  MidtransConfig({
    required this.clientKey,
    required this.merchantBaseUrl,
  });
}
