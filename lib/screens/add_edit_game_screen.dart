import 'package:flutter/material.dart';
import '../widgets/max_width.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../services/api_client.dart';
import '../services/game_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/game_image.dart';

class AddEditGameScreen extends StatefulWidget {
  final Game? game;
  const AddEditGameScreen({super.key, this.game});

  @override
  State<AddEditGameScreen> createState() => _AddEditGameScreenState();
}

class _AddEditGameScreenState extends State<AddEditGameScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _imageController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.game?.title ?? '');
    _imageController = TextEditingController(text: widget.game?.image ?? '');
    _descriptionController = TextEditingController(
      text: widget.game?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.game?.price.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final apiClient = ApiClient(auth);
      final gameService = GameService(apiClient);
      final game = Game(
        id: widget.game?.id,
        title: _titleController.text.trim(),
        image: _imageController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
      );
      try {
        if (widget.game == null) {
          await gameService.addGame(game);
        } else {
          await gameService.updateGame(game);
        }
        Navigator.pop(context, true);
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
      appBar: AppBar(
        title: Text(widget.game == null ? 'Add Game' : 'Edit Game'),
      ),
      body: MaxWidth(
        maxWidth: 640,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(
                    labelText: 'Image path (assets/...)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                if (_imageController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: GameImage(
                      imagePath: _imageController.text,
                      width: 100,
                      height: 100,
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
