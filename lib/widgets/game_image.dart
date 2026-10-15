import 'package:flutter/material.dart';

class GameImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;

  const GameImage({
    super.key,
    required this.imagePath,
    this.width = 80,
    this.height = 80,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }
}