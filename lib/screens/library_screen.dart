import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../providers/download_provider.dart';
import '../providers/owned_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/game_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/game_image.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback onOpenDownloads;
  final VoidCallback onBrowseStore;

  const LibraryScreen({
    super.key,
    required this.onOpenDownloads,
    required this.onBrowseStore,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedFilter = 'All';
  Future<List<Game>>? _futureGames;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOwnedGamesThenGames();
  }

  void _loadOwnedGamesThenGames() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoggedIn) {
      final apiClient = ApiClient(auth);
      final ownedProvider = Provider.of<OwnedProvider>(context, listen: false);
      await ownedProvider.loadOwnedGames(apiClient);
    }
    if (!mounted) return;
    final gameService = GameService(
      ApiClient(Provider.of<AuthProvider>(context, listen: false)),
    );
    setState(() {
      _futureGames = gameService.fetchGames();
    });
  }

  List<Game> _applyFiltersAndSort(List<Game> ownedGames) {
    final downloads = Provider.of<DownloadProvider>(context, listen: false);
    List<Game> filtered = ownedGames;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (g) => g.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    if (_selectedFilter == 'Alphabetical') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else if (_selectedFilter == 'Installed') {
      filtered = filtered.where(downloads.isDownloaded).toList();
    } else if (_selectedFilter == 'PriceLowHigh') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedFilter == 'PriceHighLow') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }
    return filtered;
  }

  void _download(Game game) {
    context.read<DownloadProvider>().startDownload(game);
    // replace any older message instead of queueing behind it
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Downloading ${game.title}'),
          action: SnackBarAction(
            label: 'View',
            onPressed: widget.onOpenDownloads,
          ),
        ),
      );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownedProvider = context.watch<OwnedProvider>();
    // rebuild when a download moves or finishes
    context.watch<DownloadProvider>();

    return FutureBuilder<List<Game>>(
      future: _futureGames,
      builder: (context, snapshot) {
        // _futureGames is null until owned games are loaded
        if (_futureGames == null ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: 'Could not load your library',
            message: '${snapshot.error}',
            actionLabel: 'Try again',
            onAction: _loadOwnedGamesThenGames,
          );
        }
        final allGames = snapshot.data ?? [];
        final ownedGames = allGames
            .where((game) => ownedProvider.isOwned(game.id))
            .toList();

        if (ownedGames.isEmpty) {
          return EmptyState(
            icon: Icons.sports_esports_outlined,
            title: 'No games yet',
            message: 'Games you buy show up here, ready to download and play.',
            actionLabel: 'Browse the store',
            onAction: widget.onBrowseStore,
          );
        }

        final displayGames = _applyFiltersAndSort(ownedGames);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search your games...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedFilter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Games')),
                      DropdownMenuItem(
                        value: 'Alphabetical',
                        child: Text('A-Z'),
                      ),
                      DropdownMenuItem(
                        value: 'Installed',
                        child: Text('Installed'),
                      ),
                      DropdownMenuItem(
                        value: 'PriceLowHigh',
                        child: Text('Price: Low to High'),
                      ),
                      DropdownMenuItem(
                        value: 'PriceHighLow',
                        child: Text('Price: High to Low'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedFilter = value!),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${ownedGames.length} game${ownedGames.length == 1 ? '' : 's'} in your library',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: displayGames.isEmpty
                  ? const Center(child: Text('No games match this filter.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                      itemCount: displayGames.length,
                      itemBuilder: (context, index) => _LibraryTile(
                        game: displayGames[index],
                        onDownload: _download,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LibraryTile extends StatelessWidget {
  final Game game;
  final void Function(Game) onDownload;

  const _LibraryTile({required this.game, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadProvider>();
    final installed = downloads.isDownloaded(game);
    final task = downloads.taskFor(game);
    final size = formatSize(DownloadProvider.sizeMbFor(game));

    String status;
    if (installed) {
      status = 'Installed · $size';
    } else if (task == null) {
      status = 'Not installed · $size';
    } else if (task.status == DownloadStatus.downloading) {
      status =
          '${(task.progress * 100).round()}% · ${formatSpeed(task.speedMbps)}';
    } else if (task.status == DownloadStatus.paused) {
      status = 'Paused at ${(task.progress * 100).round()}%';
    } else {
      status = 'Waiting in queue';
    }

    Widget action;
    if (installed) {
      action = ElevatedButton.icon(
        key: const ValueKey('play'),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Launching ${game.title}... (demo)')),
        ),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Play'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      );
    } else if (task == null) {
      action = OutlinedButton.icon(
        key: const ValueKey('download'),
        onPressed: () => onDownload(game),
        icon: const Icon(Icons.download),
        label: const Text('Download'),
      );
    } else {
      final paused = task.status == DownloadStatus.paused;
      action = Row(
        key: const ValueKey('progress'),
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: paused ? 'Resume' : 'Pause',
            onPressed: () =>
                paused ? downloads.resume(game) : downloads.pause(game),
            icon: Icon(paused ? Icons.play_arrow : Icons.pause),
          ),
          IconButton(
            tooltip: 'Cancel',
            onPressed: () => downloads.cancel(game),
            icon: const Icon(Icons.close),
          ),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            GameImage(imagePath: game.image, width: 72, height: 72),
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
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (task != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: action,
            ),
          ],
        ),
      ),
    );
  }
}
