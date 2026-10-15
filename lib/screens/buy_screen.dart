import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../providers/cart_provider.dart';
import '../providers/owned_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/purchase_service.dart';
import '../app_config.dart';

class BuyScreen extends StatefulWidget {
  final Game game;
  const BuyScreen({super.key, required this.game});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController =
      TextEditingController(text: AppConfig.demoMode ? '4242 4242 4242 4242' : '');

  double get tax => widget.game.price * 0.10;
  double get total => widget.game.price + tax;

  @override
  void dispose() {
    _cardNumberController.dispose();
    super.dispose();
  }

  void _processPurchase() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.isInCart(widget.game.id!)) {
      cart.removeFromCart(widget.game.id!);
    }
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final apiClient = ApiClient(auth);
      final purchaseService = PurchaseService(apiClient);
      try {
        await purchaseService.purchaseGame(widget.game.id!);
        // Add to local owned provider
        Provider.of<OwnedProvider>(context, listen: false).addOwned(widget.game.id!);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Purchase Successful"),
            content: Text("You bought ${widget.game.title} for \$${total.toStringAsFixed(2)}. It will appear in your Library."),
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
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
                    children: [
                      Text(widget.game.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Subtotal:"), Text("\$${widget.game.price.toStringAsFixed(2)}")]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Tax (10%):"), Text("\$${tax.toStringAsFixed(2)}")]),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total:", style: TextStyle(fontWeight: FontWeight.bold)), Text("\$${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
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