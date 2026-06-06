import 'package:flutter/foundation.dart';

class AppConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // for Chrome / Edge
    } else {
      return 'http://10.0.2.2:3000'; // for Android emulator
    }
  }
}