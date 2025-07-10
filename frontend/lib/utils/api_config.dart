import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Untuk web, gunakan localhost
      return 'http://localhost:3000';
    } else {
      // Untuk mobile via USB debugging, gunakan localhost (karena adb reverse)
      // Untuk WiFi, bisa gunakan IP 192.168.1.6:3000
      return 'http://localhost:3000';
    }
  }
  
  // Alternative URLs untuk fallback
  static List<String> get fallbackUrls {
    return [
      'http://localhost:3000',      // USB debugging dengan adb reverse
      'http://10.0.2.2:3000',      // Android emulator
      'http://192.168.1.6:3000',   // WiFi local network
    ];
  }
  
  static Map<String, String> get defaultHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
