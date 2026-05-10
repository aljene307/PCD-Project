import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Decorative layered leaf shapes painted on a dark forest background.
/// Used as the onboarding/proceed backdrop.
class LeafBackdrop extends StatelessWidget {
  final Widget child;
  const LeafBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.forestRich),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _LeafPainter()),
          ),
          child,
        ],
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final leaves = <_LeafSpec>[
      _LeafSpec(
        offset: Offset(size.width * 0.85, size.height * 0.08),
        scale: 1.6,
        rotation: -0.4,
        opacity: 0.10,
      ),
      _LeafSpec(
        offset: Offset(-size.width * 0.10, size.height * 0.18),
        scale: 1.9,
        rotation: 0.6,
        opacity: 0.08,
      ),
      _LeafSpec(
        offset: Offset(size.width * 0.7, size.height * 0.55),
        scale: 1.2,
        rotation: 1.2,
        opacity: 0.06,
      ),
      _LeafSpec(
        offset: Offset(size.width * 0.15, size.height * 0.72),
        scale: 1.4,
        rotation: -1.0,
        opacity: 0.07,
      ),
    ];

    for (final l in leaves) {
      _drawLeaf(canvas, l);
    }

    // Subtle noise dots for "field" feel
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    for (int i = 0; i < 60; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), rng.nextDouble() * 1.2 + 0.4, dotPaint);
    }
  }

  void _drawLeaf(Canvas canvas, _LeafSpec spec) {
    canvas.save();
    canvas.translate(spec.offset.dx, spec.offset.dy);
    canvas.rotate(spec.rotation);
    canvas.scale(spec.scale);

    final path = Path()
      ..moveTo(0, -60)
      ..quadraticBezierTo(45, -55, 50, 0)
      ..quadraticBezierTo(45, 55, 0, 60)
      ..quadraticBezierTo(-45, 55, -50, 0)
      ..quadraticBezierTo(-45, -55, 0, -60)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.forestLight.withValues(alpha: spec.opacity * 1.2),
          Colors.white.withValues(alpha: spec.opacity * 0.4),
        ],
      ).createShader(const Rect.fromLTWH(-60, -60, 120, 120));

    canvas.drawPath(path, paint);

    // central vein
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: spec.opacity * 0.8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, -55), const Offset(0, 55), veinPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) => false;
}

class _LeafSpec {
  final Offset offset;
  final double scale;
  final double rotation;
  final double opacity;
  _LeafSpec({
    required this.offset,
    required this.scale,
    required this.rotation,
    required this.opacity,
  });
}
