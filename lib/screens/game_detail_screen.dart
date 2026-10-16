import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../providers/owned_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_icon.dart';
import 'buy_screen.dart';
import '../widgets/max_width.dart';
import '../widgets/cover_art.dart';

class GameDetailScreen extends StatelessWidget {
  final Game game;
  const GameDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final ownedProvider = Provider.of<OwnedProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final isOwned = ownedProvider.isOwned(game.id);
    final inCart = cartProvider.isInCart(game.id!);

    const heading = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

    final buyButtons = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        isOwned
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This game is already in your Library.'),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text("VIEW IN LIBRARY"),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BuyScreen(game: game)),
                ),
                child: const Text("BUY NOW"),
              ),
        // Add to Cart button (only if not owned)
        if (!isOwned) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: inCart ? null : () => cartProvider.addToCart(game.id!),
            icon: Icon(inCart ? Icons.check : Icons.add_shopping_cart),
            label: Text(inCart ? 'Already in Cart' : 'Add to Cart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );

    final titleAndPrice = [
      Text(
        game.title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        game.price == 0 ? "FREE" : "\$${game.price.toStringAsFixed(2)}",
        style: TextStyle(fontSize: 20, color: Theme.of(context).primaryColor),
      ),
    ];

    final ratings = [
      const Text("Rating", style: heading),
      const SizedBox(height: 4),
      const Row(
        children: [
          Icon(Icons.star, color: Colors.amber),
          Icon(Icons.star, color: Colors.amber),
          Icon(Icons.star, color: Colors.amber),
          Icon(Icons.star, color: Colors.amber),
          Icon(Icons.star_half, color: Colors.amber),
          SizedBox(width: 8),
          Text("4.5/5"),
        ],
      ),
      const SizedBox(height: 16),
      const Text("Content Rating", style: heading),
      const SizedBox(height: 4),
      const Text("PEGI 12"),
    ];

    final aboutGame = [
      const Text("Description", style: heading),
      const SizedBox(height: 4),
      Text(game.description),
      const SizedBox(height: 16),
      const Text("Computer Requirements", style: heading),
      const SizedBox(height: 4),
      const Text(
        "OS: Windows 10\nCPU: Intel i5\nRAM: 8GB\nGPU: GTX 960\nStorage: 20GB",
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(game.title), actions: const [CartIcon()]),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // wide screens: picture and details on the left, buy box on the right
          if (constraints.maxWidth >= 900) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: MaxWidth(
                maxWidth: 1100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: _CoverHeader(game: game, coverSize: 240),
                          ),
                          const SizedBox(height: 24),
                          ...aboutGame,
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 2,
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...titleAndPrice,
                              const SizedBox(height: 20),
                              buyButtons,
                              const SizedBox(height: 24),
                              ...ratings,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MaxWidth(
              maxWidth: 700,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 220,
                    child: _CoverHeader(game: game, coverSize: 170),
                  ),
                  const SizedBox(height: 16),
                  ...titleAndPrice,
                  const SizedBox(height: 16),
                  ...aboutGame,
                  const SizedBox(height: 16),
                  ...ratings,
                  const SizedBox(height: 30),
                  buyButtons,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CoverHeader extends StatelessWidget {
  final Game game;
  final double coverSize;

  const _CoverHeader({required this.game, required this.coverSize});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          BlurredCover(imagePath: game.image),
          Center(
            child: Hero(
              tag: 'game-image-${game.id}',
              child: CoverCard(imagePath: game.image, size: coverSize),
            ),
          ),
        ],
      ),
    );
  }
}
