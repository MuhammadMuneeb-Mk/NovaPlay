import 'package:flutter/material.dart';
import '../widgets/max_width.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../services/api_client.dart';
import '../services/game_service.dart';
import '../providers/auth_provider.dart';
import 'add_edit_game_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/game_image.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Game> _games = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  GameService get _gameService =>
      GameService(ApiClient(Provider.of<AuthProvider>(context, listen: false)));

  Future<void> _loadGames() async {
    try {
      final games = await _gameService.fetchGames();
      if (!mounted) return;
      setState(() {
        _games = games;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openEditor([Game? game]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditGameScreen(game: game)),
    );
    if (saved != true || !mounted) return;
    await _loadGames();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(game == null ? 'Game added' : 'Changes saved')),
    );
  }

  Future<void> _deleteGame(Game game) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete game?'),
        content: Text(
          '"${game.title}" will be removed from the store for everyone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _gameService.deleteGame(game.id!);
      if (!mounted) return;
      setState(() => _games.removeWhere((g) => g.id == game.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${game.title} deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return EmptyState(
        icon: Icons.wifi_off,
        title: 'Could not load games',
        message: _error!,
        actionLabel: 'Try again',
        onAction: () {
          setState(() => _loading = true);
          _loadGames();
        },
      );
    }
    if (_games.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'The store is empty',
        message: 'Add the first game to get started.',
        actionLabel: 'Add game',
        onAction: () => _openEditor(),
      );
    }

    final shown = _games
        .where((g) => g.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final average =
        _games.fold<double>(0, (sum, g) => sum + g.price) / _games.length;
    final highest = _games.map((g) => g.price).reduce((a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: _loadGames,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Row(
            children: [
              _StatCard(label: 'Games', value: '${_games.length}'),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Average price',
                value: '\$${average.toStringAsFixed(2)}',
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Highest price',
                value: '\$${highest.toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search games...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No games match your search.')),
            ),
          for (final game in shown)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                leading: GameImage(
                  imagePath: game.image,
                  width: 56,
                  height: 56,
                ),
                title: Text(
                  game.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '\$${game.price.toStringAsFixed(2)} · ${game.description}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _openEditor(game),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openEditor(game),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteGame(game),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage games'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadGames,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: MaxWidth(maxWidth: 900, child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add game'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
