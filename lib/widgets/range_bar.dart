import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Visual range bar used in the Crop Detail screen for pH and Temperature.
/// Shows a graduated colored gradient with the optimal range highlighted.
class RangeBar extends StatelessWidget {
  final String title;
  final String optimalLabel; // e.g. "6.0 pH - 8.0 pH"
  final double scaleMin;
  final double scaleMax;
  final double rangeStart;
  final double rangeEnd;
  final List<Color> gradient;
  final List<String> ticks; // optional tick labels

  const RangeBar({
    super.key,
    required this.title,
    required this.optimalLabel,
    required this.scaleMin,
    required this.scaleMax,
    required this.rangeStart,
    required this.rangeEnd,
    required this.gradient,
    this.ticks = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.label),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final span = scaleMax - scaleMin;
            final startFrac = ((rangeStart - scaleMin) / span).clamp(0.0, 1.0);
            final endFrac = ((rangeEnd - scaleMin) / span).clamp(0.0, 1.0);
            final tooltipCenter = (startFrac + endFrac) / 2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient bar with highlighted optimal range
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Faded gradient (full range)
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: gradient
                              .map((c) => c.withValues(alpha: 0.35))
                              .toList(),
                        ),
                      ),
                    ),
                    // Highlighted optimal range (full saturation + glow)
                    Positioned(
                      left: startFrac * width,
                      width: (endFrac - startFrac) * width,
                      top: -2,
                      bottom: -2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(colors: gradient),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.last.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tooltip pointer + bubble
                    Positioned(
                      top: 22,
                      left: (tooltipCenter * width) - 50,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomPaint(
                            size: const Size(12, 6),
                            painter: _TrianglePainter(),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              optimalLabel,
                              style: AppTextStyles.bodyS.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (ticks.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ticks
                        .map(
                          (t) => Text(
                            t,
                            style: AppTextStyles.bodyS.copyWith(
                              fontSize: 10,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 36),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
