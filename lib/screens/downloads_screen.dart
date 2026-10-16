import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../models/game.dart';
import '../widgets/empty_state.dart';
import '../widgets/game_image.dart';

class DownloadsScreen extends StatelessWidget {
  final VoidCallback onOpenLibrary;

  const DownloadsScreen({super.key, required this.onOpenLibrary});

  Future<void> _uninstall(BuildContext context, Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Uninstall ${game.title}?'),
        content: Text(
          'This frees ${formatSize(DownloadProvider.sizeMbFor(game))}. '
          'You can download it again from your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<DownloadProvider>().removeDownload(game);
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadProvider>();
    final tasks = downloads.tasks;
    final installed = downloads.downloadedGames;

    if (tasks.isEmpty && installed.isEmpty) {
      return EmptyState(
        icon: Icons.download_outlined,
        title: 'Nothing downloaded yet',
        message: 'Download a game from your library and it will show up here.',
        actionLabel: 'Go to library',
        onAction: onOpenLibrary,
      );
    }

    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Summary(
          tasks: tasks,
          installedCount: installed.length,
          installedMb: downloads.installedMb,
        ),
        if (tasks.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Downloading', style: titleStyle),
          const SizedBox(height: 8),
          for (final task in tasks) _DownloadCard(task: task),
        ],
        if (installed.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Installed', style: titleStyle),
          const SizedBox(height: 8),
          for (final game in installed)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                leading: GameImage(
                  imagePath: game.image,
                  width: 52,
                  height: 52,
                ),
                title: Text(
                  game.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(formatSize(DownloadProvider.sizeMbFor(game))),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Play',
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Launching ${game.title}... (demo)',
                              ),
                            ),
                          ),
                      icon: Icon(
                        Icons.play_circle_fill,
                        color: Theme.of(context).primaryColor,
                        size: 30,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Uninstall',
                      onPressed: () => _uninstall(context, game),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Downloads are simulated and sped up for this demo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final List<DownloadTask> tasks;
  final int installedCount;
  final double installedMb;

  const _Summary({
    required this.tasks,
    required this.installedCount,
    required this.installedMb,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final active = tasks
        .where((t) => t.status == DownloadStatus.downloading)
        .firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              active != null ? Icons.downloading : Icons.download_done,
              color: primary,
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    active != null
                        ? formatSpeed(active.speedMbps)
                        : tasks.isEmpty
                        ? 'All downloads finished'
                        : 'Downloads paused',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$installedCount installed · ${formatSize(installedMb)} used',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final DownloadTask task;

  const _DownloadCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final downloads = context.read<DownloadProvider>();
    final game = task.game;
    final paused = task.status == DownloadStatus.paused;
    final queued = task.status == DownloadStatus.queued;

    String detail;
    if (paused) {
      detail = 'Paused';
    } else if (queued) {
      detail = 'Waiting in queue';
    } else {
      detail = '${formatSpeed(task.speedMbps)} · ${formatTimeLeft(task)}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GameImage(imagePath: game.image, width: 52, height: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(detail, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: paused ? 'Resume' : 'Pause',
                  onPressed: queued
                      ? null
                      : () => paused
                            ? downloads.resume(game)
                            : downloads.pause(game),
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                ),
                IconButton(
                  tooltip: 'Cancel',
                  onPressed: () => downloads.cancel(game),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(end: task.progress),
              duration: DownloadProvider.tick,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(value: value, minHeight: 8),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${formatSize(task.receivedMb)} of ${formatSize(task.totalMb)}',
                  style: const TextStyle(fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${(task.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
