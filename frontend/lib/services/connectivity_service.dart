// Conditional import untuk memilih implementasi connectivity yang tepat
export 'connectivity_service_mobile.dart' if (dart.library.html) 'connectivity_service_web.dart';
