import 'package:flutter/material.dart';
import '../app_config.dart';
import '../utils/theme.dart';

// Shows the app inside a phone sized frame on wide screens.
class WebFrame extends StatelessWidget {
  final Widget child;
  const WebFrame({super.key, required this.child});

  static const double _phoneWidth = 412;
  static const double _phoneMaxHeight = 880;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;

    if (screen.width < 600) return child;

    final height = (screen.height - 48).clamp(560.0, _phoneMaxHeight);
    final frameSize = Size(_phoneWidth, height);

    return ColoredBox(
      color: const Color(0xFF0E1411),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 1.1,
                  colors: [
                    AppTheme.primaryGreen.withValues(alpha: 0.22),
                    const Color(0xFF0E1411),
                  ],
                ),
              ),
            ),
          ),
          if (screen.width >= 1000)
            Positioned(
              left: 48,
              top: 0,
              bottom: 0,
              width: (screen.width - _phoneWidth) / 2 - 96,
              child: const _SidePanel(),
            ),
          Center(
            child: Container(
              width: frameSize.width,
              height: frameSize.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFF2A332E), width: 6),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: MediaQuery(
                  data: media.copyWith(
                    size: Size(frameSize.width - 12, frameSize.height - 12),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel();

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(
      color: Color(0xFFB7C2BC),
      fontSize: 15,
      height: 1.5,
    );
    return DefaultTextStyle(
      style: muted,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NovaPlay',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Game store app made with Flutter and a Node.js REST API.',
            style: TextStyle(color: Colors.white, fontSize: 18, height: 1.4),
          ),
          if (AppConfig.demoMode) ...[
            const SizedBox(height: 24),
            const Text('Demo version with sample data, no server needed.'),
            const SizedBox(height: 8),
            const Text(
              'Login: demo / demo1234',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
