// Conditional import untuk memilih implementasi sync yang tepat
export 'sync_service_mobile.dart' if (dart.library.html) 'sync_service_web.dart';
