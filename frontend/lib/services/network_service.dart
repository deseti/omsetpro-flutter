import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';

class NetworkService {
  static Dio? _dio;
  static String? _workingBaseUrl;

  /// Get cached Dio instance if available, returns null if not cached yet
  static Dio? getCachedDio() {
    return _dio;
  }

  static Future<Dio> getDio() async {
    if (_dio != null && _workingBaseUrl != null) {
      // Update token jika ada perubahan
      await _updateTokenInInterceptor(_dio!);
      return _dio!;
    }

    // Test URLs untuk menemukan yang working
    String? workingUrl = await _findWorkingUrl();
    
    if (workingUrl == null) {
      throw Exception('Tidak dapat terhubung ke server. Pastikan:\n'
          '1. Backend server berjalan\n'
          '2. Gunakan adb reverse tcp:3000 tcp:3000\n'
          '3. Atau hubungkan via WiFi');
    }

    _workingBaseUrl = workingUrl;
    _dio = Dio(BaseOptions(
      baseUrl: workingUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // Tambahkan interceptor untuk authentication
    await _updateTokenInInterceptor(_dio!);

    print('✅ Connected to: $_workingBaseUrl');
    return _dio!;
  }

  static Future<void> _updateTokenInInterceptor(Dio dio) async {
    // Clear existing interceptors to avoid duplicates
    dio.interceptors.clear();
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  static Future<String?> _findWorkingUrl() async {
    List<String> urlsToTest = kIsWeb 
        ? [ApiConfig.baseUrl] 
        : ApiConfig.fallbackUrls;

    for (String url in urlsToTest) {
      try {
        print('🔍 Testing: $url');
        
        final dio = Dio(BaseOptions(
          baseUrl: url,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));

        final response = await dio.get('/');
        
        if (response.statusCode == 200) {
          print('✅ Success with: $url');
          return url;
        }
      } catch (e) {
        print('❌ Failed: $url - $e');
        continue;
      }
    }
    
    return null;
  }

  static void reset() {
    _dio = null;
    _workingBaseUrl = null;
  }
}
