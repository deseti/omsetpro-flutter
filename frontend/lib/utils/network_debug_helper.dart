import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NetworkDebugHelper {
  static Future<void> testConnection() async {
    const baseUrl =
        kIsWeb ? 'http://localhost:3000' : 'http://192.168.1.6:3000';

    try {
      print('🔍 Testing connection to: $baseUrl');
      print('🔍 Platform: ${kIsWeb ? "Web" : "Mobile"}');

      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('✅ Connection successful!');
      print('📊 Status: ${response.statusCode}');
      print('📊 Response: ${response.body}');
    } catch (e) {
      print('❌ Connection failed: $e');
      print('💡 Checklist:');
      print('   - Backend server running?');
      print('   - Correct IP address?');
      print('   - Firewall blocking?');
      print('   - Internet permissions (Android)?');
    }
  }

  static Future<void> testAiEndpoint(String token) async {
    const baseUrl =
        kIsWeb ? 'http://localhost:3000' : 'http://192.168.1.6:3000';

    try {
      print('🤖 Testing AI endpoint...');

      final response = await http
          .post(
            Uri.parse('$baseUrl/ai-insight/query'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'query': 'Test connection',
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('✅ AI endpoint accessible!');
      print('📊 Status: ${response.statusCode}');
    } catch (e) {
      print('❌ AI endpoint failed: $e');
    }
  }
}
