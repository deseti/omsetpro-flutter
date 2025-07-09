// Stub implementation for web platform
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncService {
  static Future<void> startAutoSync(WidgetRef ref) async {
    // Web platform - no auto sync needed
    print('SyncService: startAutoSync called on web - ignoring');
  }

  static Future<bool> manualSync(WidgetRef ref) async {
    // Web platform - no manual sync needed
    print('SyncService: manualSync called on web - returning true');
    return true;
  }
}
