import 'package:flutter/material.dart';
import '../widgets/max_width.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../services/api_client.dart';
import '../services/game_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/game_image.dart';

// cover images bundled with the app (see pubspec.yaml)
const _coverImages = [
  'assets/images/minecraft.jpg',
  'assets/images/forzahorizon5.jpg',
  'assets/images/fortnite.jpg',
  'assets/images/amongus.jpg',
  'assets/images/viewfinder.jpg',
  'assets/images/warthunder.jpg',
  'assets/images/forzahorizon4.jpg',
];

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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.game?.title ?? '');
    _imageController = TextEditingController(
      text: widget.game?.image ?? _coverImages.first,
    );
    _descriptionController = TextEditingController(
      text: widget.game?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.game?.price.toStringAsFixed(2) ?? '',
    );
    // keep the preview card in sync while typing
    for (final c in [_titleController, _imageController, _priceController]) {
      c.addListener(() => setState(() {}));
    }
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final gameService = GameService(
      ApiClient(Provider.of<AuthProvider>(context, listen: false)),
    );
    final game = Game(
      id: widget.game?.id,
      title: _titleController.text.trim(),
      image: _imageController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim()),
    );
    try {
      if (widget.game == null) {
        await gameService.addGame(game);
      } else {
        await gameService.updateGame(game);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(_priceController.text.trim());
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game == null ? 'Add game' : 'Edit game'),
      ),
      body: MaxWidth(
        maxWidth: 640,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // live preview of how the game will look in the store
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      GameImage(
                        imagePath: _imageController.text,
                        width: 120,
                        height: 90,
                        borderRadius: 0,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titleController.text.isEmpty
                                  ? 'Game title'
                                  : _titleController.text,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              price == null
                                  ? '\$0.00'
                                  : '\$${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 2 ? 'Enter a title' : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cover image',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _coverImages.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final path = _coverImages[index];
                      final selected = _imageController.text == path;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _imageController.text = path,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? primary : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: GameImage(
                            imagePath: path,
                            width: 84,
                            height: 60,
                            borderRadius: 8,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(
                    labelText: 'Image path',
                    helperText: 'Pick a cover above or type an asset path',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter an image path'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter a short description'
                      : null,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (USD)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final value = double.tryParse(v?.trim() ?? '');
                    if (value == null) return 'Enter a price, e.g. 19.99';
                    if (value < 0) return 'Price cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.game == null ? 'Add game' : 'Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
