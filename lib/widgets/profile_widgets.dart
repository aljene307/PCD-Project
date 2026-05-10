import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// String output as a labeled info row with leading icon.
class StringInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StringInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.forestMid.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.forestMid),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyS.copyWith(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.label.copyWith(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Boolean output as a green ✓ / red ✗ chip.
class BoolChip extends StatelessWidget {
  final String label;
  final bool value;

  /// If true, a "true" answer is positive (green ✓). If false, a "true"
  /// answer is negative (red ✗) — useful for risks like Frost Risk: Yes.
  final bool trueIsGood;

  const BoolChip({
    super.key,
    required this.label,
    required this.value,
    this.trueIsGood = true,
  });

  @override
  Widget build(BuildContext context) {
    final positive = trueIsGood ? value : !value;
    final color = positive ? AppColors.success : AppColors.error;
    final icon = positive ? Icons.check_rounded : Icons.close_rounded;
    final answer = value ? 'Yes' : 'No';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.soft,
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyS.copyWith(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  answer,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Float output: labeled progress bar with value + unit on the right.
class FloatBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final String unit;
  final String? formatted; // overrides "value unit" display
  final Color color;

  const FloatBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.unit,
    this.formatted,
    this.color = AppColors.forestMid,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / maxValue).clamp(0.0, 1.0);
    final display = formatted ?? '$value $unit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                display,
                style: AppTextStyles.label.copyWith(
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(height: 7, color: AppColors.creamSoft),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.6), color],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title (small caps) used to group output blocks.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      child: Text(
        text,
        style: AppTextStyles.bodyS.copyWith(
          color: AppColors.inkMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          fontSize: 11,
        ),
      ),
    );
  }
}
