import 'package:flutter/material.dart';
import '../models/game.dart';

class DownloadProvider extends ChangeNotifier {
  final List<Game> _downloadedGames = [];

  List<Game> get downloadedGames => _downloadedGames;

  bool isDownloaded(Game game) {
    return _downloadedGames.any((g) => g.id == game.id);
  }

  void addDownload(Game game) {
    if (!isDownloaded(game)) {
      _downloadedGames.add(game);
      notifyListeners();
    }
  }

  void removeDownload(Game game) {
    _downloadedGames.removeWhere((g) => g.id == game.id);
    notifyListeners();
  }
}