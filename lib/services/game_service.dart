import 'dart:convert';
import '../models/game.dart';
import 'api_client.dart';

class GameService {
  final ApiClient api;

  GameService(this.api);

  Future<List<Game>> fetchGames() async {
    final response = await api.get('/api/games');
    final List data = jsonDecode(response.body);
    return data.map((json) => Game.fromJson(json)).toList();
  }

  Future<Game> addGame(Game game) async {
    final response = await api.post('/api/games', game.toJson());
    final data = jsonDecode(response.body);
    return Game.fromJson(data['data']);
  }

  Future<Game> updateGame(Game game) async {
    final response = await api.put('/api/games/${game.id}', game.toJson());
    final data = jsonDecode(response.body);
    return Game.fromJson(data['data']);
  }

  Future<void> deleteGame(int id) async {
    await api.delete('/api/games/$id');
  }
}