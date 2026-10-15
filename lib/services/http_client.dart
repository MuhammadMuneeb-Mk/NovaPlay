import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../app_config.dart';
import 'mock_backend.dart';

// In demo mode requests go to MockBackend instead of the real server.
final http.Client httpClient = AppConfig.demoMode
    ? MockClient(MockBackend.instance.handle)
    : http.Client();
