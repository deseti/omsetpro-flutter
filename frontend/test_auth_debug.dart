import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

void main() async {
  print('=== DEBUG AUTH & LAPORAN ===');
  
  // 1. Check if token exists in SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');
  
  print('Token in SharedPreferences: ${token != null ? "YES (${token.substring(0, 20)}...)" : "NO"}');
  
  if (token != null) {
    // 2. Test API call with token
    final dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:3000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // Add interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['Authorization'] = 'Bearer $token';
        print('Request headers: ${options.headers}');
        handler.next(options);
      },
    ));
    
    try {
      print('\n=== TESTING LAPORAN API ===');
      final response = await dio.get('/laporan/dashboard');
      print('Dashboard API Success: ${response.statusCode}');
      print('Dashboard Data: ${response.data}');
    } catch (e) {
      print('Dashboard API Error: $e');
      if (e is DioException) {
        print('Status: ${e.response?.statusCode}');
        print('Data: ${e.response?.data}');
      }
    }
  } else {
    print('No token found. Please login first.');
  }
}
