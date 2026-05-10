import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/crop_analysis.dart';

/// Tappable parameter row used in soil/climate breakdown lists.
/// Shows code, progress bar, fraction (e.g. "52/85"), status chip, chevron.
class BreakdownTile extends StatelessWidget {
  final AnalysisParameter param;
  final VoidCallback onTap;
  final bool showChevron;

  const BreakdownTile({
    super.key,
    required this.param,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (param.currentValue / 100).clamp(0.0, 1.0);
    final needFrac = (param.needValue / 100).clamp(0.0, 1.0);

    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppShadows.soft,
            border: Border.all(color: AppColors.creamSoft),
          ),
          child: Row(
            children: [
              // Param code badge
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      param.status.color.withValues(alpha: 0.18),
                      param.status.color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  param.code,
                  style: AppTextStyles.label.copyWith(
                    color: param.status.color,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      param.name,
                      style: AppTextStyles.label.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _DualProgress(
                      current: progress,
                      need: needFrac,
                      color: param.status.color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      param.currentDisplay,
                      style: AppTextStyles.bodyS.copyWith(
                        fontSize: 11,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusChip(status: param.status),
              if (showChevron) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.inkMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DualProgress extends StatelessWidget {
  final double current;
  final double need;
  final Color color;

  const _DualProgress({
    required this.current,
    required this.need,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            children: [
              // Track
              Container(
                width: w,
                decoration: BoxDecoration(
                  color: AppColors.creamSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              // Need marker (faint)
              Positioned(
                left: (need * w).clamp(0, w - 2),
                child: Container(
                  width: 2,
                  height: 8,
                  color: AppColors.ink.withValues(alpha: 0.35),
                ),
              ),
              // Current value bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                width: current * w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.7), color],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ParameterStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.bodyS.copyWith(
          color: status.color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Compact nutrient breakdown row (used inside SQ Detail).
class NutrientRowCard extends StatelessWidget {
  final NutrientRow nutrient;
  const NutrientRowCard({super.key, required this.nutrient});

  @override
  Widget build(BuildContext context) {
    final progress = (nutrient.soilValue / 100).clamp(0.0, 1.0);
    final need = (nutrient.needValue / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nutrient.name,
                  style: AppTextStyles.label.copyWith(fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: nutrient.status.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  nutrient.status == ParameterStatus.good
                      ? 'OK'
                      : nutrient.status.label,
                  style: AppTextStyles.bodyS.copyWith(
                    color: nutrient.status.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DualProgress(
            current: progress,
            need: need,
            color: nutrient.status.color,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soil: ${nutrient.soilValue}',
                style: AppTextStyles.bodyS.copyWith(fontSize: 11),
              ),
              Text(
                'Need: ${nutrient.needValue}',
                style: AppTextStyles.bodyS.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
