import 'dart:convert';
import 'http_client.dart';
import '../app_config.dart';
import '../providers/auth_provider.dart';

class AuthService {
  final AuthProvider auth;

  AuthService(this.auth);

  Future<bool> login(String username, String password) async {
    final res = await httpClient.post(
      Uri.parse('${AppConfig.baseUrl}/api/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await auth.setToken(data['token'], user: data['user']);
      return true;
    }
    return false;
  }

  Future<bool> signup(
    String username,
    String email,
    String password,
    String displayName,
  ) async {
    final res = await httpClient.post(
      Uri.parse('${AppConfig.baseUrl}/api/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'display_name': displayName,
      }),
    );
    return res.statusCode == 201;
  }
}
