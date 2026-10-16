import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_game/models/game.dart';
import 'package:app_game/providers/download_provider.dart';

Game _game(int id, String title) => Game(
  id: id,
  title: title,
  image: 'assets/images/minecraft.jpg',
  description: 'test',
  price: 1,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('downloads one game at a time and queues the rest', (
    tester,
  ) async {
    final downloads = DownloadProvider();
    final a = _game(1, 'Minecraft');
    final b = _game(2, 'Among Us');

    downloads.startDownload(a);
    downloads.startDownload(b);
    expect(downloads.taskFor(a)!.status, DownloadStatus.downloading);
    expect(downloads.taskFor(b)!.status, DownloadStatus.queued);

    await tester.pump(const Duration(seconds: 2));
    expect(downloads.taskFor(a)!.progress, greaterThan(0));
    expect(downloads.taskFor(b)!.progress, 0);

    // both are small, so both finish well within a minute of fake time
    await tester.pump(const Duration(seconds: 30));
    expect(downloads.isDownloaded(a), isTrue);
    expect(downloads.isDownloaded(b), isTrue);
    expect(downloads.tasks, isEmpty);
    downloads.dispose();
  });

  testWidgets('pausing stops progress and lets the next game start', (
    tester,
  ) async {
    final downloads = DownloadProvider();
    final a = _game(1, 'Forza Horizon 5');
    final b = _game(2, 'Among Us');

    downloads.startDownload(a);
    downloads.startDownload(b);
    await tester.pump(const Duration(seconds: 1));
    downloads.pause(a);
    final pausedAt = downloads.taskFor(a)!.progress;

    expect(downloads.taskFor(b)!.status, DownloadStatus.downloading);
    await tester.pump(const Duration(seconds: 3));
    expect(downloads.taskFor(a)!.progress, pausedAt);

    downloads.cancel(a);
    downloads.cancel(b);
    expect(downloads.tasks, isEmpty);
    downloads.dispose();
  });
}
