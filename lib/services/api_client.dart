import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_client.dart';
import '../app_config.dart';
import '../providers/auth_provider.dart';

class ApiClient {
  final AuthProvider auth;

  ApiClient(this.auth);

  Future<http.Response> get(String path) async {
    final res = await httpClient.get(
      Uri.parse('${AppConfig.baseUrl}$path'),
      headers: _headers(),
    );
    return _handle(res);
  }

  Future<http.Response> post(String path, dynamic body) async {
    final res = await httpClient.post(
      Uri.parse('${AppConfig.baseUrl}$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<http.Response> put(String path, dynamic body) async {
    final res = await httpClient.put(
      Uri.parse('${AppConfig.baseUrl}$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<http.Response> delete(String path) async {
    final res = await httpClient.delete(
      Uri.parse('${AppConfig.baseUrl}$path'),
      headers: _headers(),
    );
    return _handle(res);
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
    };
  }

  http.Response _handle(http.Response response) {
    if (response.statusCode == 401) {
      auth.logout();
      throw Exception('UNAUTHORIZED');
    }
    return response;
  }
}
