// Mobile/desktop (dart:io): Android emulator uses 10.0.2.2, iOS simulator and desktop use localhost.
import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8081/api/v1';
    }
    return 'http://localhost:8081/api/v1';
  }
}
