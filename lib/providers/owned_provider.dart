import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/purchase_service.dart';

class OwnedProvider extends ChangeNotifier {
  final Set<int> _ownedIds = {};

  Set<int> get ownedIds => _ownedIds;

  bool isOwned(int? gameId) => gameId != null && _ownedIds.contains(gameId);

  void addOwned(int gameId) {
    if (_ownedIds.add(gameId)) {
      notifyListeners();
    }
  }

  Future<void> loadOwnedGames(ApiClient apiClient) async {
    final purchaseService = PurchaseService(apiClient);
    try {
      final games = await purchaseService.getOwnedGames();
      final newIds = games.map((json) => json['id'] as int).toSet();
      _ownedIds.clear();
      _ownedIds.addAll(newIds);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load owned games: $e');
    }
  }
}