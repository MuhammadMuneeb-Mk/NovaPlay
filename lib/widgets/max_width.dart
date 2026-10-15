import 'package:flutter/material.dart';

// Keeps page content at a readable width on large screens (web/desktop).
class MaxWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const MaxWidth({super.key, this.maxWidth = 900, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
