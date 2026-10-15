import 'package:flutter/foundation.dart';

class AppConfig {
  // flutter build web --dart-define=DEMO_MODE=true runs the app without the backend
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE');

  static String get baseUrl {
    if (demoMode) {
      return 'https://demo.novaplay.local'; // not used, MockBackend answers
    } else if (kIsWeb) {
      return 'http://localhost:3000'; // for Chrome / Edge
    } else {
      return 'http://10.0.2.2:3000'; // for Android emulator
    }
  }
}
