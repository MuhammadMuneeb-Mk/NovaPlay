import 'dart:convert';
import '../models/user.dart';
import 'api_client.dart';

class UserService {
  final ApiClient api;

  UserService(this.api);

  // Update profile (username, email, display_name) – requires currentPassword for verification
  Future<User> updateUserProfile(int id, {
    required String username,
    required String email,
    required String displayName,
    required String currentPassword,
  }) async {
    final body = {
      'username': username,
      'email': email,
      'display_name': displayName,
      'currentPassword': currentPassword,
    };
    final response = await api.put('/api/users/$id', body);
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Update failed');
    }
    final data = jsonDecode(response.body);
    return User.fromJson(data['data']);
  }

  // Change password only – requires currentPassword and newPassword
  Future<void> changePassword(int id, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final body = {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
    final response = await api.post('/api/users/$id/change-password', body);
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Password change failed');
    }
  }

}