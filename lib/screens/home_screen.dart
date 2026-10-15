import 'dart:async';
import 'package:flutter/gestures.dart';
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
import '../providers/owned_provider.dart';
import '../services/api_client.dart';
import '../services/game_service.dart';
import '../models/game.dart';
import '../widgets/cart_icon.dart';
import '../widgets/game_image.dart';
import '../widgets/max_width.dart';

// screens wider than this get a side navigation rail instead of the bottom bar
const double _wideLayout = 900;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<String> _titles = const [
    "Home",
    "Library",
    "Downloads",
    "Settings",
    "Admin",
  ];
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
      filtered = filtered
          .where(
            (game) =>
                game.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
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

  void _openGame(Game game) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
    );
  }

  Future<void> _openAdmin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminScreen()),
    );
    _loadGames(); // Refresh home screen after returning from admin
  }

  Widget _buildSearchAndFilter(bool inline) {
    final search = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by game title...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
    final filter = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Filter: '),
        DropdownButton<String>(
          value: _selectedFilter,
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Games')),
            DropdownMenuItem(value: 'A-Z', child: Text('A-Z')),
            DropdownMenuItem(value: 'Z-A', child: Text('Z-A')),
            DropdownMenuItem(
              value: 'LowToHigh',
              child: Text('Price: Low to High'),
            ),
            DropdownMenuItem(
              value: 'HighToLow',
              child: Text('Price: High to Low'),
            ),
          ],
          onChanged: (value) => setState(() => _selectedFilter = value!),
        ),
      ],
    );

    if (inline) {
      return Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 16),
          filter,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [search, const SizedBox(height: 4), filter],
    );
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
        final displayGames = _applyFiltersAndSort(List.of(allGames));

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            const maxContent = 1200.0;
            final side = width > maxContent + 48
                ? (width - maxContent) / 2
                : 16.0;
            final columns = width >= 1100
                ? 4
                : width >= 760
                ? 3
                : width >= 520
                ? 2
                : 1;
            final carouselHeight = (width * 0.3).clamp(190.0, 340.0);
            final titleStyle = Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 16, side, 8),
                  sliver: SliverToBoxAdapter(
                    child: _buildSearchAndFilter(width >= 600),
                  ),
                ),
                if (featuredGames.isNotEmpty && _searchQuery.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side, 8, side, 8),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        height: carouselHeight,
                        child: _FeaturedCarousel(
                          games: featuredGames,
                          onOpen: _openGame,
                          showArrows: width >= 600,
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 20, side, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'All games'
                          : '${displayGames.length} result${displayGames.length == 1 ? '' : 's'}',
                      style: titleStyle,
                    ),
                  ),
                ),
                if (displayGames.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No games match your search.')),
                    ),
                  )
                else if (columns == 1)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side - 8, 0, side - 8, 16),
                    sliver: SliverList.builder(
                      itemCount: displayGames.length,
                      itemBuilder: (context, index) => _GameListTile(
                        game: displayGames[index],
                        onTap: () => _openGame(displayGames[index]),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side, 8, side, 32),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: displayGames.length,
                      itemBuilder: (context, index) => _GameCard(
                        game: displayGames[index],
                        onTap: () => _openGame(displayGames[index]),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHome();
      case 1:
        return MaxWidth(
          child: LibraryScreen(onStartDownload: _startDownloadFromLibrary),
        );
      case 2:
        return MaxWidth(
          child: DownloadsScreen(
            gameToDownload: _gameToDownload,
            onDownloadStarted: _onDownloadStarted,
          ),
        );
      case 3:
        return const MaxWidth(maxWidth: 700, child: SettingsScreen());
      case 4:
        return AdminScreen();
      default:
        return _buildHome();
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
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
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildRail(BuildContext context, bool extended) {
    final primary = Theme.of(context).primaryColor;
    return NavigationRail(
      extended: extended,
      minExtendedWidth: 220,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      selectedIndex: _selectedIndex <= 3 ? _selectedIndex : null,
      onDestinationSelected: (index) {
        if (index == 4) {
          _openAdmin();
        } else if (index == 5) {
          _showLogoutDialog(context);
        } else {
          setState(() => _selectedIndex = index);
        }
      },
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: extended
            ? Text(
                'NovaPlay',
                style: TextStyle(
                  color: primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              )
            : Icon(Icons.sports_esports, color: primary, size: 32),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(Icons.library_books),
          label: Text('Library'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.download_outlined),
          selectedIcon: Icon(Icons.download),
          label: Text('Downloads'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          label: Text('Admin'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.logout, color: Colors.red),
          label: Text('Logout'),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  "NovaPlay",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.watch<ProfileProvider>().displayName,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
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
            onTap: () {
              Navigator.pop(context);
              _openAdmin();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= _wideLayout;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: const [CartIcon()],
      ),
      drawer: wide ? null : _buildDrawer(context),
      body: wide
          ? Row(
              children: [
                _buildRail(context, width >= 1200),
                const VerticalDivider(width: 1),
                Expanded(child: _getScreen()),
              ],
            )
          : _getScreen(),
      bottomNavigationBar: !wide && _selectedIndex <= 3
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (index <= 3) setState(() => _selectedIndex = index);
              },
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_books),
                  label: 'Library',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.download),
                  label: 'Downloads',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
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

String _priceLabel(Game game) =>
    game.price == 0 ? "FREE" : "\$${game.price.toStringAsFixed(2)}";

// Featured games, auto-advances and can be dragged with a mouse on the web.
class _FeaturedCarousel extends StatefulWidget {
  final List<Game> games;
  final void Function(Game) onOpen;
  final bool showArrows;

  const _FeaturedCarousel({
    required this.games,
    required this.onOpen,
    required this.showArrows,
  });

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _go(_page + 1));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) {
    if (!_controller.hasClients) return;
    final target = page % widget.games.length;
    _controller.animateToPage(
      target < 0 ? widget.games.length - 1 : target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _arrow(IconData icon, VoidCallback onPressed) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.games.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                final game = widget.games[index];
                return GestureDetector(
                  onTap: () => widget.onOpen(game),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GameImage(
                        imagePath: game.image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                            stops: [0.45, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 28,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _priceLabel(game),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (widget.showArrows) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _arrow(Icons.chevron_left, () => _go(_page - 1)),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _arrow(Icons.chevron_right, () => _go(_page + 1)),
              ),
            ),
          ],
          Positioned(
            right: 20,
            bottom: 12,
            child: Row(
              children: [
                for (var i = 0; i < widget.games.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(left: 6),
                    width: i == _page ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Game card for the grid on wider screens.
class _GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final owned = context.watch<OwnedProvider>().isOwned(game.id);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: GameImage(
                imagePath: game.image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                borderRadius: 0,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        game.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _priceLabel(game),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (owned)
                          const Text(
                            'In library',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Compact row used on phones.
class _GameListTile extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const _GameListTile({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              GameImage(imagePath: game.image, width: 84, height: 84),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _priceLabel(game),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
