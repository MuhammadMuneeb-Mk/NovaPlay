import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Fake version of backend/server.js used in the web demo.
/// Same routes and responses, data is saved in SharedPreferences.
class MockBackend {
  MockBackend._();
  static final MockBackend instance = MockBackend._();

  static const demoUsername = 'demo';
  static const demoPassword = 'demo1234';

  static const _storageKey = 'novaplay_demo_db';
  static const _latency = Duration(milliseconds: 350);

  Map<String, dynamic>? _db;

  // seed data

  static Map<String, dynamic> _seed() => {
    'nextGameId': 8,
    'nextUserId': 2,
    'nextPurchaseId': 3,
    'games': [
      {
        'id': 1,
        'title': 'Minecraft',
        'image': 'assets/images/minecraft.jpg',
        'description':
            'Build, explore and survive in a world made of blocks. Mine resources, craft tools and shape the landscape alone or with friends.',
        'price': 26.95,
      },
      {
        'id': 2,
        'title': 'Forza Horizon 5',
        'image': 'assets/images/forzahorizon5.jpg',
        'description':
            'An open-world racing festival set across the deserts, jungles and cities of Mexico, with hundreds of cars to collect.',
        'price': 59.99,
      },
      {
        'id': 3,
        'title': 'Fortnite',
        'image': 'assets/images/fortnite.jpg',
        'description':
            'A 100-player battle royale where you drop in, gather materials and build your way to being the last one standing.',
        'price': 9.99,
      },
      {
        'id': 4,
        'title': 'Among Us',
        'image': 'assets/images/amongus.jpg',
        'description':
            'Complete tasks aboard the ship while working out which crewmate is secretly the impostor. Best played with friends.',
        'price': 4.99,
      },
      {
        'id': 5,
        'title': 'Viewfinder',
        'image': 'assets/images/viewfinder.jpg',
        'description':
            'A puzzle game where photographs become reality. Place a picture in the world and step into it to find a new path.',
        'price': 24.99,
      },
      {
        'id': 6,
        'title': 'War Thunder',
        'image': 'assets/images/warthunder.jpg',
        'description':
            'Combined-arms combat with historically detailed aircraft, tanks and ships from the 1930s to the modern day.',
        'price': 14.99,
      },
      {
        'id': 7,
        'title': 'Forza Horizon 4',
        'image': 'assets/images/forzahorizon4.jpg',
        'description':
            'Race through a shared open world in Britain where the seasons change every week and reshape the roads.',
        'price': 39.99,
      },
    ],
    'users': [
      {
        'id': 1,
        'username': demoUsername,
        'email': 'demo@novaplay.dev',
        'password': demoPassword,
        'display_name': 'Demo Player',
      },
    ],
    'purchases': [
      {'id': 1, 'user_id': 1, 'game_id': 1},
      {'id': 2, 'user_id': 1, 'game_id': 4},
    ],
  };

  // persistence

  Future<void> _load() async {
    if (_db != null) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    _db = saved != null ? jsonDecode(saved) as Map<String, dynamic> : _seed();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_db));
  }

  // used by "Reset demo data" in settings
  Future<void> reset() async {
    _db = _seed();
    await _save();
  }

  List<Map<String, dynamic>> get _games =>
      List<Map<String, dynamic>>.from(_db!['games']);
  List<Map<String, dynamic>> get _users =>
      List<Map<String, dynamic>>.from(_db!['users']);
  List<Map<String, dynamic>> get _purchases =>
      List<Map<String, dynamic>>.from(_db!['purchases']);

  int _nextId(String key) {
    final id = _db![key] as int;
    _db![key] = id + 1;
    return id;
  }

  // helpers

  http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Map<String, dynamic> _publicUser(Map<String, dynamic> u) => {
    'id': u['id'],
    'username': u['username'],
    'email': u['email'],
    'display_name': u['display_name'],
  };

  String _tokenFor(Map<String, dynamic> user) => base64Url.encode(
    utf8.encode('novaplay-demo:${user['id']}:${user['username']}'),
  );

  // same idea as the verifyToken middleware
  Map<String, dynamic>? _authUser(http.Request req) {
    final header = req.headers['Authorization'] ?? req.headers['authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    try {
      final parts = utf8
          .decode(base64Url.decode(header.substring(7)))
          .split(':');
      if (parts.length != 3 || parts[0] != 'novaplay-demo') return null;
      final id = int.parse(parts[1]);
      return _users.firstWhere((u) => u['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _body(http.Request req) {
    if (req.body.isEmpty) return {};
    final decoded = jsonDecode(req.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  bool _taken(String field, String? value, {int? exceptId}) =>
      value != null &&
      _users.any((u) => u[field] == value && u['id'] != exceptId);

  // router

  Future<http.Response> handle(http.Request req) async {
    await _load();
    await Future.delayed(_latency);

    final segments = req.url.pathSegments;
    final method = req.method;

    if (segments.length < 2 || segments[0] != 'api') {
      return _json({'message': 'Route not found'}, 404);
    }

    final resource = segments[1];
    final id = segments.length > 2 ? int.tryParse(segments[2]) : null;

    switch (resource) {
      case 'games':
        return _handleGames(req, method, segments, id);
      case 'users':
        return _handleUsers(req, method, segments, id);
      case 'current-users':
        final user = _authUser(req);
        if (user == null) {
          return _json({'success': false, 'message': 'Invalid token'}, 401);
        }
        return _json({'success': true, 'user': _publicUser(user)});
      case 'purchases':
        if (method == 'POST') return _createPurchase(req);
    }
    return _json({'message': 'Route not found'}, 404);
  }

  // games

  Future<http.Response> _handleGames(
    http.Request req,
    String method,
    List<String> segments,
    int? id,
  ) async {
    if (segments.length == 2 && method == 'GET') return _json(_games);

    if (segments.length == 3 && id != null && method == 'GET') {
      final game = _games.where((g) => g['id'] == id).firstOrNull;
      return game == null
          ? _json({'message': 'Game not found'}, 404)
          : _json(game);
    }

    if (_authUser(req) == null) {
      return _json({'success': false, 'message': 'No token provided'}, 401);
    }

    final body = _body(req);

    if (segments.length == 2 && method == 'POST') {
      if (body['title'] == null ||
          body['image'] == null ||
          body['description'] == null ||
          body['price'] == null) {
        return _json({'message': 'Missing required fields'}, 400);
      }
      final game = {
        'id': _nextId('nextGameId'),
        'title': body['title'],
        'image': body['image'],
        'description': body['description'],
        'price': body['price'],
      };
      _db!['games'] = [..._games, game];
      await _save();
      return _json({'success': true, 'data': game}, 201);
    }

    if (segments.length == 3 && id != null && method == 'PUT') {
      final games = _games;
      final index = games.indexWhere((g) => g['id'] == id);
      if (index == -1) return _json({'message': 'Game not found'}, 404);
      final game = {...games[index], ...body, 'id': id};
      games[index] = game;
      _db!['games'] = games;
      await _save();
      return _json({'success': true, 'data': game});
    }

    if (segments.length == 3 && id != null && method == 'DELETE') {
      final games = _games;
      if (!games.any((g) => g['id'] == id)) {
        return _json({'message': 'Game not found'}, 404);
      }
      _db!['games'] = games.where((g) => g['id'] != id).toList();
      _db!['purchases'] = _purchases.where((p) => p['game_id'] != id).toList();
      await _save();
      return http.Response('', 204);
    }

    return _json({'message': 'Route not found'}, 404);
  }

  // users

  Future<http.Response> _handleUsers(
    http.Request req,
    String method,
    List<String> segments,
    int? id,
  ) async {
    final body = _body(req);

    // POST /api/users/login
    if (segments.length == 3 && segments[2] == 'login' && method == 'POST') {
      final identifier = (body['username'] ?? '').toString().trim();
      final password = body['password']?.toString();
      if (identifier.isEmpty || password == null || password.isEmpty) {
        return _json({
          'success': false,
          'message': 'Username and password required',
        }, 400);
      }
      final user = _users
          .where(
            (u) =>
                (u['username'] == identifier || u['email'] == identifier) &&
                u['password'] == password,
          )
          .firstOrNull;
      if (user == null) {
        return _json({'success': false, 'message': 'Invalid credentials'}, 401);
      }
      return _json({
        'success': true,
        'token': _tokenFor(user),
        'user': _publicUser(user),
      });
    }

    // GET /api/users/me/games
    if (segments.length == 4 && segments[2] == 'me' && segments[3] == 'games') {
      final user = _authUser(req);
      if (user == null) {
        return _json({'success': false, 'message': 'Invalid token'}, 401);
      }
      final owned = _purchases
          .where((p) => p['user_id'] == user['id'])
          .map((p) => p['game_id'])
          .toSet();
      return _json(_games.where((g) => owned.contains(g['id'])).toList());
    }

    // POST /api/users  (sign up)
    if (segments.length == 2 && method == 'POST') {
      final username = body['username']?.toString().trim();
      final email = body['email']?.toString().trim();
      final password = body['password']?.toString();
      if ([username, email, password].any((v) => v == null || v.isEmpty)) {
        return _json({'message': 'Username, email and password required'}, 400);
      }
      if (_taken('username', username) || _taken('email', email)) {
        return _json({'message': 'Username or email already exists'}, 409);
      }
      final displayName = body['display_name']?.toString().trim();
      final user = {
        'id': _nextId('nextUserId'),
        'username': username,
        'email': email,
        'password': password,
        'display_name': (displayName == null || displayName.isEmpty)
            ? username
            : displayName,
      };
      _db!['users'] = [..._users, user];
      await _save();
      return _json(_publicUser(user), 201);
    }

    if (segments.length == 2 && method == 'GET') {
      return _json(_users.map(_publicUser).toList());
    }

    if (id == null) return _json({'message': 'Route not found'}, 404);

    final users = _users;
    final index = users.indexWhere((u) => u['id'] == id);

    if (segments.length == 3 && method == 'GET') {
      return index == -1
          ? _json({'message': 'User not found'}, 404)
          : _json(_publicUser(users[index]));
    }

    final authUser = _authUser(req);
    if (authUser == null) {
      return _json({'success': false, 'message': 'No token provided'}, 401);
    }
    if (index == -1) {
      return _json({'success': false, 'message': 'User not found'}, 404);
    }
    final user = users[index];

    // POST /api/users/:id/change-password
    if (segments.length == 4 &&
        segments[3] == 'change-password' &&
        method == 'POST') {
      final current = body['currentPassword']?.toString();
      final next = body['newPassword']?.toString();
      if (current == null || next == null || current.isEmpty || next.isEmpty) {
        return _json({
          'success': false,
          'message': 'Current and new password required',
        }, 400);
      }
      if (next.length < 4) {
        return _json({
          'success': false,
          'message': 'New password must be at least 4 characters',
        }, 400);
      }
      if (user['password'] != current) {
        return _json({
          'success': false,
          'message': 'Current password is incorrect',
        }, 401);
      }
      users[index] = {...user, 'password': next};
      _db!['users'] = users;
      await _save();
      return _json({
        'success': true,
        'message': 'Password changed successfully',
      });
    }

    // PUT /api/users/:id  (profile update)
    if (segments.length == 3 && method == 'PUT') {
      final current = body['currentPassword']?.toString();
      if (current == null || current.isEmpty) {
        return _json({
          'success': false,
          'message': 'Current password required',
        }, 400);
      }
      if (user['password'] != current) {
        return _json({
          'success': false,
          'message': 'Current password is incorrect',
        }, 401);
      }
      if (_taken('username', body['username']?.toString(), exceptId: id)) {
        return _json({
          'success': false,
          'message': 'Username already taken',
        }, 409);
      }
      if (_taken('email', body['email']?.toString(), exceptId: id)) {
        return _json({
          'success': false,
          'message': 'Email already registered',
        }, 409);
      }
      final updated = {
        ...user,
        if (body['username'] != null) 'username': body['username'],
        if (body['email'] != null) 'email': body['email'],
        if (body['display_name'] != null) 'display_name': body['display_name'],
      };
      users[index] = updated;
      _db!['users'] = users;
      await _save();
      return _json({'success': true, 'data': _publicUser(updated)});
    }

    if (segments.length == 3 && method == 'DELETE') {
      _db!['users'] = users.where((u) => u['id'] != id).toList();
      await _save();
      return http.Response('', 204);
    }

    return _json({'message': 'Route not found'}, 404);
  }

  // purchases

  Future<http.Response> _createPurchase(http.Request req) async {
    final user = _authUser(req);
    if (user == null) {
      return _json({'success': false, 'message': 'No token provided'}, 401);
    }
    final gameId = _body(req)['game_id'];
    if (gameId == null) {
      return _json({'success': false, 'message': 'game_id required'}, 400);
    }
    if (_purchases.any(
      (p) => p['user_id'] == user['id'] && p['game_id'] == gameId,
    )) {
      return _json({
        'success': false,
        'message': 'Game already purchased',
      }, 409);
    }
    final purchase = {
      'id': _nextId('nextPurchaseId'),
      'user_id': user['id'],
      'game_id': gameId,
    };
    _db!['purchases'] = [..._purchases, purchase];
    await _save();
    return _json({'success': true, 'purchase_id': purchase['id']}, 201);
  }
}
