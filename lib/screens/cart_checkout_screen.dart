import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../providers/cart_provider.dart';
import '../providers/owned_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/purchase_service.dart';
import '../app_config.dart';

class CartCheckoutScreen extends StatefulWidget {
  final List<Game> cartGames;
  const CartCheckoutScreen({super.key, required this.cartGames});

  @override
  State<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController =
      TextEditingController(text: AppConfig.demoMode ? '4242 4242 4242 4242' : '');

  double get subtotal => widget.cartGames.fold(0, (sum, g) => sum + g.price);
  double get tax => subtotal * 0.10;
  double get total => subtotal + tax;

  @override
  void dispose() {
    _cardNumberController.dispose();
    super.dispose();
  }

  Future<void> _processPurchase() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final apiClient = ApiClient(auth);
      final purchaseService = PurchaseService(apiClient);
      final ownedProvider = Provider.of<OwnedProvider>(context, listen: false);
      final cart = Provider.of<CartProvider>(context, listen: false);

      // Purchase each game in cart
      for (final game in widget.cartGames) {
        try {
          await purchaseService.purchaseGame(game.id!);
          ownedProvider.addOwned(game.id!);
          cart.removeFromCart(game.id!);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to purchase ${game.title}: $e')),
          );
          return;
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Purchase Successful"),
          content: Text("You bought ${widget.cartGames.length} game(s) for \$${total.toStringAsFixed(2)}. They will appear in your Library."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout Cart")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Items in Cart", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...widget.cartGames.map((game) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(game.title),
                            Text("\$${game.price.toStringAsFixed(2)}"),
                          ],
                        ),
                      )),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("Subtotal:"),
                        Text("\$${subtotal.toStringAsFixed(2)}"),
                      ]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("Tax (10%):"),
                        Text("\$${tax.toStringAsFixed(2)}"),
                      ]),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("Total:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("\$${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Payment Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: "Card Number",
                  helperText: AppConfig.demoMode
                      ? "Demo only, don't enter a real card"
                      : null,
                  helperMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Enter card number";
                  if (value.replaceAll(" ", "").length < 16) return "Enter valid 16-digit card number";
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: _processPurchase,
                  child: const Text("Confirm Purchase"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}