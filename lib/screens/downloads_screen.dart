import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../models/game.dart';
import '../widgets/game_image.dart';

class DownloadsScreen extends StatefulWidget {
  final Game? gameToDownload;
  final VoidCallback? onDownloadStarted;
  const DownloadsScreen({
    super.key,
    this.gameToDownload,
    this.onDownloadStarted,
  });

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _isDownloading = false;
  Game? _downloadingGame;
  bool _downloadStarted = false;

  @override
  void initState() {
    super.initState();
    if (widget.gameToDownload != null && !_downloadStarted) {
      _downloadStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startDownload(widget.gameToDownload!);
          widget.onDownloadStarted?.call();
        }
      });
    }
  }

  void _startDownload(Game game) async {
    if (!mounted) return;
    setState(() {
      _isDownloading = true;
      _downloadingGame = game;
    });
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      Provider.of<DownloadProvider>(context, listen: false).addDownload(game);
      setState(() {
        _isDownloading = false;
        _downloadingGame = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadProvider>().downloadedGames;

    return Column(
      children: [
        if (_isDownloading)
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text('Downloading ${_downloadingGame?.title}...'),
              ],
            ),
          ),
        Expanded(
          child: downloads.isEmpty && !_isDownloading
              ? const Center(
                  child: Text(
                    'No downloaded games yet.\nGo to Library and download some!',
                  ),
                )
              : ListView.builder(
                  itemCount: downloads.length,
                  itemBuilder: (context, index) {
                    final game = downloads[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: GameImage(
                          imagePath: game.image,
                          width: 50,
                          height: 50,
                        ),
                        title: Text(game.title),
                        subtitle: Text(game.description),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => Provider.of<DownloadProvider>(
                            context,
                            listen: false,
                          ).removeDownload(game),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
