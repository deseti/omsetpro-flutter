import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/laporan/laporan_models.dart';
import '../utils/api_config.dart';

class LaporanService {
  late final Dio _dio;

  LaporanService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    ));

    // Interceptor untuk menambahkan Authorization header
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken'); // Fixed: menggunakan key yang sama
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('Token added to request: Bearer ${token.substring(0, 20)}...'); // Debug log
        } else {
          print('No token found in SharedPreferences'); // Debug log
        }
        handler.next(options);
      },
    ));
  }

  // Constructor yang menggunakan Dio dari provider
  LaporanService.withDio(this._dio) {
    // Add cache-busting headers to existing Dio instance
    _dio.options.headers.addAll({
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    });
  }

  /// GET /laporan/ringkasan-penjualan
  /// Mendapatkan ringkasan penjualan dengan filter tanggal dan cabang
  Future<RingkasanPenjualan> getRingkasanPenjualan({
    DateTime? startDate,
    DateTime? endDate,
    int? cabangId,
  }) async {
    try {
      print('=== CALLING getRingkasanPenjualan ===');
      print('startDate: $startDate, endDate: $endDate, cabangId: $cabangId');
      
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = _formatDate(startDate);
      }
      if (endDate != null) {
        queryParams['endDate'] = _formatDate(endDate);
      }
      if (cabangId != null) {
        queryParams['cabangId'] = cabangId.toString();
      }
      
      // Add timestamp to prevent caching
      queryParams['_t'] = DateTime.now().millisecondsSinceEpoch.toString();

      print('Query params: $queryParams');

      final response = await _dio.get(
        '/laporan/ringkasan-penjualan',
        queryParameters: queryParams,
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      return RingkasanPenjualan.fromJson(response.data);
    } on DioException catch (e) {
      print('=== DioException in getRingkasanPenjualan ===');
      print('Status code: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      print('Request headers: ${e.requestOptions.headers}');
      throw _handleError(e);
    }
  }

  /// GET /laporan/produk-terlaris
  /// Mendapatkan daftar produk terlaris
  Future<List<ProdukTerlaris>> getProdukTerlaris({
    DateTime? startDate,
    DateTime? endDate,
    int? cabangId,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
      };
      
      if (startDate != null) {
        queryParams['startDate'] = _formatDate(startDate);
      }
      if (endDate != null) {
        queryParams['endDate'] = _formatDate(endDate);
      }
      if (cabangId != null) {
        queryParams['cabangId'] = cabangId.toString();
      }
      
      // Add timestamp to prevent caching
      queryParams['_t'] = DateTime.now().millisecondsSinceEpoch.toString();

      final response = await _dio.get(
        '/laporan/produk-terlaris',
        queryParameters: queryParams,
      );

      return (response.data as List)
          .map((item) => ProdukTerlaris.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /laporan/statistik-transaksi
  /// Mendapatkan statistik transaksi harian
  Future<List<StatistikTransaksi>> getStatistikTransaksi({
    DateTime? startDate,
    DateTime? endDate,
    int? cabangId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = _formatDate(startDate);
      }
      if (endDate != null) {
        queryParams['endDate'] = _formatDate(endDate);
      }
      if (cabangId != null) {
        queryParams['cabangId'] = cabangId.toString();
      }
      
      // Add timestamp to prevent caching
      queryParams['_t'] = DateTime.now().millisecondsSinceEpoch.toString();

      final response = await _dio.get(
        '/laporan/statistik-transaksi',
        queryParameters: queryParams,
      );

      return (response.data as List)
          .map((item) => StatistikTransaksi.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /laporan/laba-rugi
  /// Mendapatkan laporan laba rugi
  Future<LaporanLabaRugi> getLaporanLabaRugi({
    DateTime? startDate,
    DateTime? endDate,
    int? cabangId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = _formatDate(startDate);
      }
      if (endDate != null) {
        queryParams['endDate'] = _formatDate(endDate);
      }
      if (cabangId != null) {
        queryParams['cabangId'] = cabangId.toString();
      }
      
      // Add timestamp to prevent caching
      queryParams['_t'] = DateTime.now().millisecondsSinceEpoch.toString();

      final response = await _dio.get(
        '/laporan/laba-rugi',
        queryParameters: queryParams,
      );

      return LaporanLabaRugi.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /laporan/dashboard
  /// Mendapatkan data dashboard lengkap
  Future<DashboardData> getDashboard({
    DateTime? startDate,
    DateTime? endDate,
    int? cabangId,
  }) async {
    try {
      print('=== CALLING getDashboard ===');
      print('startDate: $startDate, endDate: $endDate, cabangId: $cabangId');
      
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = _formatDate(startDate);
      }
      if (endDate != null) {
        queryParams['endDate'] = _formatDate(endDate);
      }
      if (cabangId != null) {
        queryParams['cabangId'] = cabangId.toString();
      }
      
      // Add timestamp to prevent caching
      queryParams['_t'] = DateTime.now().millisecondsSinceEpoch.toString();

      print('Query params: $queryParams');

      final response = await _dio.get(
        '/laporan/dashboard',
        queryParameters: queryParams,
      );

      print('Response status: ${response.statusCode}');
      print('Response generatedAt: ${response.data['generatedAt']}');
      print('Response total omzet: ${response.data['ringkasan']['totalOmzet']}');

      return DashboardData.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Helper method untuk format tanggal ke string ISO
  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
  }

  /// Helper method untuk handle error dari Dio
  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return data['message'];
      }
      return 'Error: ${e.response!.statusCode}';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Koneksi timeout, periksa internet Anda';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server tidak merespons, coba lagi nanti';
    } else {
      return 'Gagal terhubung ke server';
    }
  }
}
