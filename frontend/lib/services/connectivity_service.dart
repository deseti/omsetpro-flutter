import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamController<bool>? _connectivityController;

  // Stream untuk monitor koneksi internet
  static Stream<bool> get connectivityStream {
    _connectivityController ??= StreamController<bool>.broadcast();
    
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Anggap online jika ada koneksi (wifi, mobile, ethernet)
      final isOnline = results.any((result) => 
        result == ConnectivityResult.wifi || 
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet
      );
      
      _connectivityController?.add(isOnline);
    });
    
    return _connectivityController!.stream;
  }

  // Check koneksi saat ini
  static Future<bool> isConnected() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      return connectivityResults.any((result) => 
        result == ConnectivityResult.wifi || 
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet
      );
    } catch (e) {
      return false;
    }
  }

  static void dispose() {
    _connectivityController?.close();
    _connectivityController = null;
  }
}

// Provider untuk status koneksi
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.connectivityStream;
});

// Provider untuk cek koneksi saat ini
final currentConnectivityProvider = FutureProvider<bool>((ref) {
  return ConnectivityService.isConnected();
});
