import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Large circular compatibility score (0-100). Color shifts based on value.
class CompatibilityCircle extends StatefulWidget {
  final int value; // 0–100
  final String label;
  final double size;

  const CompatibilityCircle({
    super.key,
    required this.value,
    required this.label,
    this.size = 150,
  });

  @override
  State<CompatibilityCircle> createState() => _CompatibilityCircleState();
}

class _CompatibilityCircleState extends State<CompatibilityCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _colorFor(int v) {
    if (v >= 70) return AppColors.success;
    if (v >= 50) return AppColors.amber;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(widget.value);
    // Use intrinsic Column height (no fixed SizedBox) to avoid overflow.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              final progress = (widget.value / 100) * _anim.value;
              return CustomPaint(
                painter: _CompatPainter(progress: progress, color: color),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(widget.value * _anim.value).round()}%',
                        style: AppTextStyles.headingL.copyWith(
                          color: color,
                          fontSize: widget.size < 120 ? 22 : 30,
                        ),
                      ),
                      Text(
                        'match',
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.inkMuted,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                          fontSize: widget.size < 120 ? 10 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyS.copyWith(
            color: AppColors.inkMuted,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _CompatPainter extends CustomPainter {
  final double progress; // 0–1
  final Color color;

  _CompatPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.creamSoft
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    // Progress arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CompatPainter old) =>
      old.progress != progress || old.color != color;
}
