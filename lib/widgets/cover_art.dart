import 'dart:ui';
import 'package:flutter/material.dart';
import 'game_image.dart';

// The game covers are small (225px), so they look blurry when stretched.
// Instead the cover is shown close to its real size on top of a blurred,
// darkened copy of itself that fills the rest of the space.
class BlurredCover extends StatelessWidget {
  final String imagePath;

  const BlurredCover({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Transform.scale(
              scale: 1.3,
              child: GameImage(
                imagePath: imagePath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                borderRadius: 0,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xB3000000), Color(0x66000000)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CoverCard extends StatelessWidget {
  final String imagePath;
  final double size;

  const CoverCard({super.key, required this.imagePath, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: GameImage(
        imagePath: imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: 14,
      ),
    );
  }
}
