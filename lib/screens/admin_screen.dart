import 'package:flutter/material.dart';
import '../widgets/max_width.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../services/api_client.dart';
import '../services/game_service.dart';
import '../providers/auth_provider.dart';
import 'add_edit_game_screen.dart';
import '../widgets/game_image.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Game> _games = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final apiClient = ApiClient(auth);
    final gameService = GameService(apiClient);
    try {
      final games = await gameService.fetchGames();
      setState(() {
        _games = games;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteGame(Game game) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Game'),
        content: Text('Delete "${game.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final apiClient = ApiClient(auth);
      final gameService = GameService(apiClient);
      try {
        await gameService.deleteGame(game.id!);
        _loadGames();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Game deleted')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Manage Games')),
      body: MaxWidth(
        maxWidth: 900,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _games.length,
                itemBuilder: (context, index) {
                  final game = _games[index];
                  return ListTile(
                    leading: GameImage(
                      imagePath: game.image,
                      width: 50,
                      height: 50,
                    ),
                    title: Text(game.title),
                    subtitle: Text('\$${game.price.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEditGameScreen(game: game),
                              ),
                            );
                            if (result == true) _loadGames();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteGame(game),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditGameScreen()),
          );
          if (result == true) _loadGames();
        },
      ),
    );
  }
}
