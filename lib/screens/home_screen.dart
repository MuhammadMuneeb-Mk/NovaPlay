import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'admin_screen.dart';
import 'auth/login_screen.dart';
import 'settings_screen.dart';
import 'library_screen.dart';
import 'downloads_screen.dart';
import 'game_detail_screen.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/game_service.dart';
import '../models/game.dart';
import '../widgets/cart_icon.dart';
import '../widgets/game_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<String> _titles = const ["Home", "Library", "Downloads", "Settings", "Admin"];
  Game? _gameToDownload;
  Future<List<Game>>? _futureGames;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  void _loadGames() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final apiClient = ApiClient(auth);
    final gameService = GameService(apiClient);
    setState(() {
      _futureGames = gameService.fetchGames();
    });
  }

  List<Game> _applyFiltersAndSort(List<Game> games) {
    List<Game> filtered = games;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((game) =>
          game.title.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    if (_selectedFilter == 'A-Z') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else if (_selectedFilter == 'Z-A') {
      filtered.sort((a, b) => b.title.compareTo(a.title));
    } else if (_selectedFilter == 'LowToHigh') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedFilter == 'HighToLow') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startDownloadFromLibrary(Game game) {
    setState(() {
      _selectedIndex = 2;
      _gameToDownload = game;
    });
  }

  void _onDownloadStarted() {
    setState(() {
      _gameToDownload = null;
    });
  }

  Widget _buildHome() {
    return FutureBuilder<List<Game>>(
      future: _futureGames,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final allGames = snapshot.data ?? [];
        final featuredGames = allGames.take(5).toList();
        final displayGames = _applyFiltersAndSort(allGames);

        return Column(
          children: [
            // 1. Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by game title...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            // 2. Filter dropdown
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
                      DropdownMenuItem(value: 'A-Z', child: Text('A-Z')),
                      DropdownMenuItem(value: 'Z-A', child: Text('Z-A')),
                      DropdownMenuItem(value: 'LowToHigh', child: Text('Price: Low to High')),
                      DropdownMenuItem(value: 'HighToLow', child: Text('Price: High to Low')),
                    ],
                    onChanged: (value) => setState(() => _selectedFilter = value!),
                  ),
                ],
              ),
            ),
            // 3. Carousel (only if there are featured games)
            if (featuredGames.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: featuredGames.length,
                  itemBuilder: (context, index) {
                    final game = featuredGames[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetailScreen(game: game))),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            GameImage(imagePath: game.image, width: double.infinity, height: 200, fit: BoxFit.cover),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                color: Colors.black54,
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  game.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            // 4. Game list (scrollable)
            Expanded(
              child: ListView.builder(
                itemCount: displayGames.length,
                itemBuilder: (context, index) {
                  final game = displayGames[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetailScreen(game: game))),
                    child: Card(
                      margin: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          GameImage(imagePath: game.image, width: 80, height: 80),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(game.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(game.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(game.price == 0 ? "FREE" : "\$${game.price}", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
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


  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0: return _buildHome();
      case 1: return LibraryScreen(onStartDownload: _startDownloadFromLibrary);
      case 2: return DownloadsScreen(gameToDownload: _gameToDownload, onDownloadStarted: _onDownloadStarted);
      case 3: return const SettingsScreen();
      case 4: return AdminScreen();
      default: return _buildHome();
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    Provider.of<CartProvider>(context, listen: false).clearCart();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex]), actions: const [CartIcon()]),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("NovaPlay", style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(context.watch<ProfileProvider>().displayName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            _drawerItem(Icons.home, "Home", 0),
            _drawerItem(Icons.library_books, "Library", 1),
            _drawerItem(Icons.download, "Downloads", 2),
            _drawerItem(Icons.settings, "Settings", 3),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Admin"),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                _loadGames(); // Refresh home screen after returning from admin
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
      body: _getScreen(),
      bottomNavigationBar: _selectedIndex <= 3
          ? BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index <= 3) setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Downloads'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      )
          : null,
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}