import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:proco/constants/app_colors.dart';

/// App-wide loading indicator: an animated stack of rippling sine-wave lines,
/// drawn in the same blue used in the onboarding chat. This is the same mark
/// shown on the onboarding "Let's take you on the shore" bridge screen, minus
/// the caption and at a slightly smaller default size, so it can stand in for
/// `CircularProgressIndicator` anywhere a page or section is loading.
///
/// Usage:
/// ```dart
/// const Center(child: WaveLoader())
/// ```
/// Use [WaveLoader.small] for inline/button-sized contexts.
///
/// The wave colour is centralised here — it always uses [kWaveLoaderColor]
/// (currently [kSend], the onboarding chat blue). Change it in one place below
/// rather than per call site.
class WaveLoader extends StatefulWidget {
  const WaveLoader({super.key, this.width, this.height});

  /// Compact variant suited to buttons and tight inline spaces.
  const WaveLoader.small({super.key}) : width = 44, height = 22;

  /// Logical width before `.w` scaling. Defaults to 120.
  final double? width;

  /// Logical height before `.h` scaling. Defaults to 64.
  final double? height;

  @override
  State<WaveLoader> createState() => _WaveLoaderState();
}

/// Single source of truth for the loader's wave colour. Edit this to recolour
/// every loader in the app at once.
const Color kWaveLoaderColor = kSend;

class _WaveLoaderState extends State<WaveLoader>
    with SingleTickerProviderStateMixin {
  // Drives the rippling motion of the wave lines.
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (widget.width ?? 120).w,
      height: (widget.height ?? 64).h,
      child: AnimatedBuilder(
        animation: _waveCtrl,
        builder: (context, _) => CustomPaint(
          painter: _WaveStackPainter(progress: _waveCtrl.value),
        ),
      ),
    );
  }
}

/// Paints a stack of horizontal sine-wave lines that ripple sideways — the
/// animated cousin of the drawer's `Icons.waves_rounded` mark.
class _WaveStackPainter extends CustomPainter {
  _WaveStackPainter({required this.progress});

  /// 0..1 looping phase from the controller.
  final double progress;

  static const int _lines = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.height / (_lines + 1);
    final amplitude = gap * 0.55;

    for (var i = 0; i < _lines; i++) {
      // Front lines (higher i) are more opaque; the stack recedes upward.
      final opacity = 0.30 + 0.70 * (i / (_lines - 1));
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..color = kWaveLoaderColor.withValues(alpha: opacity);

      final baseY = gap * (i + 1);
      // Each line is phase-shifted so the stack ripples rather than moving in
      // lockstep.
      final phase = progress * 2 * math.pi + i * (math.pi / 3);

      final path = Path();
      for (double x = 0; x <= size.width; x += 2) {
        final y =
            baseY +
            amplitude * math.sin((x / size.width) * 2 * math.pi * 1.6 + phase);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveStackPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
