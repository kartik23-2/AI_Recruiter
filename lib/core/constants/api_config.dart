import 'dart:io' show Platform;

/// Backend API configuration.
///
/// Android emulator: use 10.0.2.2 to reach the host machine.
/// iOS simulator / desktop: use localhost.
/// Physical device: set [hostOverride] to your machine's LAN IP.
class ApiConfig {
  ApiConfig._();

  /// Override for physical devices, e.g. '192.168.1.42'.
  static const String? hostOverride = null;

  static const int port = 8001;

  static String get baseUrl {
    if (hostOverride != null) {
      return 'http://$hostOverride:$port';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$port';
    }
    return 'http://localhost:$port';
  }

  static String get analyzeResumeUrl => '$baseUrl/analyze-resume';
}
