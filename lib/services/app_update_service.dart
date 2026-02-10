// Conditional export: use the real implementation on Android (non-web),
// fall back to a no-op stub on Web (where in_app_update is unsupported).
export 'app_update_service_stub.dart'
    if (dart.library.io) 'app_update_service_native.dart';
