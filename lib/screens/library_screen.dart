import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../providers/download_provider.dart';
import '../providers/owned_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/game_service.dart';
import '../widgets/game_image.dart';

class LibraryScreen extends StatefulWidget {
  final Function(Game) onStartDownload;
  const LibraryScreen({super.key, required this.onStartDownload});

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
    final auth2 = Provider.of<AuthProvider>(context, listen: false);
    final apiClient2 = ApiClient(auth2);
    final gameService = GameService(apiClient2);
    setState(() {
      _futureGames = gameService.fetchGames();
    });
  }

  List<Game> _applyFiltersAndSort(List<Game> ownedGames) {
    List<Game> filtered = ownedGames;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((g) => g.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_selectedFilter == 'Alphabetical') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else if (_selectedFilter == 'Installed') {
      filtered = filtered.where((g) => Provider.of<DownloadProvider>(context, listen: false).isDownloaded(g)).toList();
    } else if (_selectedFilter == 'PriceLowHigh') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedFilter == 'PriceHighLow') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownedProvider = context.watch<OwnedProvider>();
    final downloadProvider = context.watch<DownloadProvider>();

    return FutureBuilder<List<Game>>(
      future: _futureGames,
      builder: (context, snapshot) {
        // _futureGames is null until owned games are loaded
        if (_futureGames == null || snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading games: ${snapshot.error}'));
        }
        final allGames = snapshot.data ?? [];
        final ownedGames = allGames.where((game) => ownedProvider.isOwned(game.id)).toList();

        if (ownedGames.isEmpty) {
          return const Center(child: Text('No purchased games yet. Go to store and buy some!'));
        }

        final displayGames = _applyFiltersAndSort(ownedGames);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by title...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Filter: '),
                  DropdownButton<String>(
                    value: _selectedFilter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Games')),
                      DropdownMenuItem(value: 'Alphabetical', child: Text('A-Z')),
                      DropdownMenuItem(value: 'Installed', child: Text('Installed')),
                      DropdownMenuItem(value: 'PriceLowHigh', child: Text('Price: Low to High')),
                      DropdownMenuItem(value: 'PriceHighLow', child: Text('Price: High to Low')),
                    ],
                    onChanged: (value) => setState(() => _selectedFilter = value!),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: displayGames.length,
                itemBuilder: (context, index) {
                  final game = displayGames[index];
                  final isDownloaded = downloadProvider.isDownloaded(game);
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: GameImage(imagePath: game.image, width: 50, height: 50),
                      title: Text(game.title),
                      subtitle: Text(game.description),
                      trailing: isDownloaded
                          ? ElevatedButton(
                        style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.green),
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playing game... (demo)'))),
                        child: const Text('Play'),
                      )
                          : ElevatedButton(
                        style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor),
                        onPressed: () => widget.onStartDownload(game),
                        child: const Text('Download'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}