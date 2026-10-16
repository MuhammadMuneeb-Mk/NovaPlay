import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game.dart';

enum DownloadStatus { queued, downloading, paused }

class DownloadTask {
  DownloadTask(this.game, this.totalMb, this.durationTicks);

  final Game game;
  final double totalMb;
  final int durationTicks;
  double receivedMb = 0;
  double speedMbps = 0;
  DownloadStatus status = DownloadStatus.queued;

  double get progress => (receivedMb / totalMb).clamp(0.0, 1.0);
}

// Simulated download manager. Like a real launcher, one game downloads at a
// time and the rest wait in a queue. Downloads are sped up so even a 100 GB
// game finishes in under half a minute.
class DownloadProvider extends ChangeNotifier {
  DownloadProvider() {
    _load();
  }

  static const _storageKey = 'installed_games';
  static const tick = Duration(milliseconds: 250);

  final List<Game> _downloadedGames = [];
  final List<DownloadTask> _tasks = [];
  final _random = Random();
  final _completed = StreamController<Game>.broadcast();
  Timer? _timer;

  List<Game> get downloadedGames => List.unmodifiable(_downloadedGames);
  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  /// Fires when a download finishes, used to show a "ready to play" message.
  Stream<Game> get completed => _completed.stream;

  bool isDownloaded(Game game) => _downloadedGames.any((g) => g.id == game.id);

  DownloadTask? taskFor(Game game) {
    for (final task in _tasks) {
      if (task.game.id == game.id) return task;
    }
    return null;
  }

  double get installedMb =>
      _downloadedGames.fold(0, (sum, g) => sum + sizeMbFor(g));

  // made-up install sizes, roughly what these games really take
  static double sizeMbFor(Game game) {
    const sizesGb = {
      'among us': 0.3,
      'minecraft': 1.2,
      'viewfinder': 6.3,
      'war thunder': 26.0,
      'fortnite': 32.0,
      'forza horizon 4': 72.0,
      'forza horizon 5': 110.0,
    };
    final title = game.title.toLowerCase();
    for (final entry in sizesGb.entries) {
      if (title.contains(entry.key)) return entry.value * 1024;
    }
    return ((game.id ?? 1) * 7 % 40 + 4) * 1024.0;
  }

  void startDownload(Game game) {
    if (isDownloaded(game) || taskFor(game) != null) return;
    final sizeGb = sizeMbFor(game) / 1024;
    // 6 to 25 seconds depending on size
    final seconds = (6 + sizeGb * 0.17).clamp(6, 25);
    final ticks = (seconds * 1000 / tick.inMilliseconds).round();
    _tasks.add(DownloadTask(game, sizeMbFor(game), ticks));
    _update();
  }

  void pause(Game game) {
    final task = taskFor(game);
    if (task == null) return;
    task.status = DownloadStatus.paused;
    task.speedMbps = 0;
    _update();
  }

  void resume(Game game) {
    final task = taskFor(game);
    if (task == null || task.status != DownloadStatus.paused) return;
    task.status = DownloadStatus.queued;
    _update();
  }

  void cancel(Game game) {
    _tasks.removeWhere((t) => t.game.id == game.id);
    _update();
  }

  void removeDownload(Game game) {
    _downloadedGames.removeWhere((g) => g.id == game.id);
    _save();
    notifyListeners();
  }

  void removeAll() {
    _downloadedGames.clear();
    _tasks.clear();
    _save();
    _update();
  }

  // keeps exactly one task downloading and the timer running only when needed
  void _update() {
    final downloading = _tasks.any(
      (t) => t.status == DownloadStatus.downloading,
    );
    if (!downloading) {
      for (final task in _tasks) {
        if (task.status == DownloadStatus.queued) {
          task.status = DownloadStatus.downloading;
          break;
        }
      }
    }
    final active = _tasks.any((t) => t.status == DownloadStatus.downloading);
    if (active) {
      _timer ??= Timer.periodic(tick, (_) => _onTick());
    } else {
      _timer?.cancel();
      _timer = null;
    }
    notifyListeners();
  }

  void _onTick() {
    DownloadTask? task;
    for (final t in _tasks) {
      if (t.status == DownloadStatus.downloading) task = t;
    }
    if (task == null) {
      _update();
      return;
    }

    // speed drifts around 60 MB/s so the number on screen looks alive
    final target = 60 + (_random.nextDouble() - 0.5) * 50;
    task.speedMbps = task.speedMbps == 0
        ? target
        : task.speedMbps * 0.7 + target * 0.3;
    task.receivedMb +=
        task.totalMb / task.durationTicks * (task.speedMbps / 60);

    if (task.receivedMb >= task.totalMb) {
      _tasks.remove(task);
      _downloadedGames.add(task.game);
      _save();
      _completed.add(task.game);
      _update();
    } else {
      notifyListeners();
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved == null) return;
    final list = jsonDecode(saved) as List;
    _downloadedGames
      ..clear()
      ..addAll(list.map((json) => Game.fromJson(json as Map<String, dynamic>)));
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _downloadedGames
        .map((g) => {'id': g.id, ...g.toJson()})
        .toList();
    await prefs.setString(_storageKey, jsonEncode(list));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _completed.close();
    super.dispose();
  }
}

String formatSize(double mb) =>
    mb < 1024 ? '${mb.round()} MB' : '${(mb / 1024).toStringAsFixed(1)} GB';

String formatSpeed(double mbps) => '${mbps.toStringAsFixed(1)} MB/s';

String formatTimeLeft(DownloadTask task) {
  final ticksLeft = ((1 - task.progress) * task.durationTicks).ceil();
  final seconds = (ticksLeft * DownloadProvider.tick.inMilliseconds / 1000)
      .ceil();
  return seconds < 60 ? '$seconds s left' : '${(seconds / 60).ceil()} min left';
}
