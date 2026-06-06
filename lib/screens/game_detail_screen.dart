import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../providers/owned_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_icon.dart';
import 'buy_screen.dart';
import '../widgets/game_image.dart';

class GameDetailScreen extends StatelessWidget {
  final Game game;
  const GameDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final ownedProvider = Provider.of<OwnedProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final isOwned = ownedProvider.isOwned(game.id);
    final inCart = cartProvider.isInCart(game.id!);

    return Scaffold(
      appBar: AppBar(
        title: Text(game.title),
        actions: const [CartIcon()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GameImage(
                imagePath: game.image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(game.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              game.price == 0 ? "FREE" : "\$${game.price}",
              style: TextStyle(fontSize: 18, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 16),
            const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(game.description),
            const SizedBox(height: 16),
            const Text("Computer Requirements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("OS: Windows 10\nCPU: Intel i5\nRAM: 8GB\nGPU: GTX 960\nStorage: 20GB"),
            const SizedBox(height: 16),
            const Text("Rating", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Row(children: [
              Icon(Icons.star, color: Colors.amber),
              Icon(Icons.star, color: Colors.amber),
              Icon(Icons.star, color: Colors.amber),
              Icon(Icons.star, color: Colors.amber),
              Icon(Icons.star_half, color: Colors.amber),
              SizedBox(width: 8),
              Text("4.5/5"),
            ]),
            const SizedBox(height: 16),
            const Text("Content Rating", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("PEGI 12"),
            const SizedBox(height: 30),
            // Purchase button
            SizedBox(
              width: double.infinity,
              child: isOwned
                  ? ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This game is already in your Library.')),
                  );
                  Navigator.pop(context);
                },
                child: const Text("VIEW IN LIBRARY"),
              )
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BuyScreen(game: game))),
                child: const Text("BUY NOW"),
              ),
            ),
            // Add to Cart button (only if not owned)
            if (!isOwned) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: inCart ? null : () => cartProvider.addToCart(game.id!),
                  icon: Icon(inCart ? Icons.check : Icons.add_shopping_cart),
                  label: Text(inCart ? 'Already in Cart' : 'Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}