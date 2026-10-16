import 'dart:convert';
import 'api_client.dart';

class PurchaseService {
  final ApiClient api;

  PurchaseService(this.api);

  Future<void> purchaseGame(int gameId) async {
    final response = await api.post('/api/purchases', {'game_id': gameId});
    if (response.statusCode != 201) {
      throw Exception('Failed to record purchase');
    }
  }

  Future<List<Map<String, dynamic>>> getOwnedGames() async {
    final response = await api.get('/api/users/me/games');
    final List data = jsonDecode(response.body);
    return data.map((e) => e as Map<String, dynamic>).toList();
  }
}
