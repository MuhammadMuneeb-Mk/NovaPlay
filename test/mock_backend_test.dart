import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_game/services/mock_backend.dart';

void main() {
  late MockClient client;
  const base = 'https://demo.novaplay.local';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MockBackend.instance.reset();
    client = MockClient(MockBackend.instance.handle);
  });

  Future<String> login() async {
    final res = await client.post(
      Uri.parse('$base/api/users/login'),
      body: jsonEncode({'username': 'demo', 'password': 'demo1234'}),
    );
    expect(res.statusCode, 200);
    return jsonDecode(res.body)['token'];
  }

  test('login fails with a wrong password', () async {
    final res = await client.post(
      Uri.parse('$base/api/users/login'),
      body: jsonEncode({'username': 'demo', 'password': 'nope'}),
    );
    expect(res.statusCode, 401);
  });

  test('lists the sample games', () async {
    final res = await client.get(Uri.parse('$base/api/games'));
    expect(res.statusCode, 200);
    expect((jsonDecode(res.body) as List).length, 7);
  });

  test('buying a game adds it to owned games once', () async {
    final token = await login();
    final headers = {'Authorization': 'Bearer $token'};

    final buy = await client.post(
      Uri.parse('$base/api/purchases'),
      headers: headers,
      body: jsonEncode({'game_id': 2}),
    );
    expect(buy.statusCode, 201);

    final again = await client.post(
      Uri.parse('$base/api/purchases'),
      headers: headers,
      body: jsonEncode({'game_id': 2}),
    );
    expect(again.statusCode, 409);

    final owned = await client.get(Uri.parse('$base/api/users/me/games'), headers: headers);
    final ids = (jsonDecode(owned.body) as List).map((g) => g['id']).toList();
    expect(ids, containsAll([1, 2, 4]));
  });

  test('protected routes need a token', () async {
    final res = await client.post(
      Uri.parse('$base/api/games'),
      body: jsonEncode({'title': 'x', 'image': 'x', 'description': 'x', 'price': 1}),
    );
    expect(res.statusCode, 401);
  });

  test('admin can add, edit and delete a game', () async {
    final headers = {'Authorization': 'Bearer ${await login()}'};

    final created = await client.post(
      Uri.parse('$base/api/games'),
      headers: headers,
      body: jsonEncode({
        'title': 'Test Game',
        'image': 'assets/images/minecraft.jpg',
        'description': 'test',
        'price': 5,
      }),
    );
    expect(created.statusCode, 201);
    final id = jsonDecode(created.body)['data']['id'];

    final updated = await client.put(
      Uri.parse('$base/api/games/$id'),
      headers: headers,
      body: jsonEncode({'title': 'Renamed', 'price': 7}),
    );
    expect(jsonDecode(updated.body)['data']['title'], 'Renamed');

    final deleted = await client.delete(Uri.parse('$base/api/games/$id'), headers: headers);
    expect(deleted.statusCode, 204);
  });

  test('signup rejects a taken username', () async {
    final res = await client.post(
      Uri.parse('$base/api/users'),
      body: jsonEncode({'username': 'demo', 'email': 'new@test.com', 'password': '1234'}),
    );
    expect(res.statusCode, 409);
  });

  test('change password checks the current password', () async {
    final headers = {'Authorization': 'Bearer ${await login()}'};
    final wrong = await client.post(
      Uri.parse('$base/api/users/1/change-password'),
      headers: headers,
      body: jsonEncode({'currentPassword': 'bad', 'newPassword': 'newpass'}),
    );
    expect(wrong.statusCode, 401);

    final ok = await client.post(
      Uri.parse('$base/api/users/1/change-password'),
      headers: headers,
      body: jsonEncode({'currentPassword': 'demo1234', 'newPassword': 'newpass'}),
    );
    expect(ok.statusCode, 200);
  });
}
