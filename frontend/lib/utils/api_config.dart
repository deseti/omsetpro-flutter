import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Untuk web, gunakan localhost
      return 'http://localhost:3000';
    } else {
      // Untuk mobile, prioritaskan IP jaringan WiFi untuk perangkat fisik
      return 'http://192.168.1.6:3000';
    }
  }
  
  // Alternative URLs untuk fallback
  static List<String> get fallbackUrls {
    return [
      'http://192.168.1.6:3000',   // WiFi local network (primary untuk perangkat fisik)
      'http://localhost:3000',      // USB debugging dengan adb reverse
      'http://10.0.2.2:3000',      // Android emulator
      'http://192.168.1.100:3000', // Alternative IP ranges
      'http://192.168.0.100:3000', // Alternative IP ranges
    ];
  }
  
  static Map<String, String> get defaultHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
