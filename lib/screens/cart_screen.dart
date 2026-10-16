import 'package:flutter/material.dart';
import '../widgets/max_width.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/owned_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/game_service.dart';
import '../models/game.dart';
import '../widgets/cart_icon.dart';
import '../widgets/game_image.dart';
import 'cart_checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Game> _cartGames = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCartGames();
  }

  Future<void> _loadCartGames() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final apiClient = ApiClient(auth);
    final gameService = GameService(apiClient);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final ownedProvider = Provider.of<OwnedProvider>(context, listen: false);
    try {
      final allGames = await gameService.fetchGames();
      // Remove any cart item that is already owned
      final toRemove = cart.itemIds
          .where((id) => ownedProvider.isOwned(id))
          .toList();
      for (var id in toRemove) {
        cart.removeFromCart(id);
      }
      final gamesInCart = allGames
          .where((g) => cart.itemIds.contains(g.id))
          .toList();
      setState(() {
        _cartGames = gamesInCart;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading cart: $e')));
    }
  }

  void _removeItem(Game game) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.removeFromCart(game.id!);
    setState(() {
      _cartGames.remove(game);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${game.title} removed from cart')));
  }

  double get totalPrice => _cartGames.fold(0, (sum, g) => sum + g.price);

  void _checkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartCheckoutScreen(cartGames: _cartGames),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: const [CartIcon()],
      ),
      body: MaxWidth(
        maxWidth: 760,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _cartGames.isEmpty
            ? const Center(child: Text('Your cart is empty'))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cartGames.length,
                      itemBuilder: (context, index) {
                        final game = _cartGames[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: GameImage(
                              imagePath: game.image,
                              width: 50,
                              height: 50,
                            ),
                            title: Text(game.title),
                            subtitle: Text('\$${game.price.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_shopping_cart,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeItem(game),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(fontSize: 18),
                            ),
                            Text(
                              '\$${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Checkout'),
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
