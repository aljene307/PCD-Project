import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../data/crop_analysis.dart';
import '../data/sq_details.dart';
import '../widgets/compatibility_circle.dart';
import '../widgets/section_card.dart';

/// Detail page for a single SQ (soil quality) or CP (climate) parameter.
/// Layout varies based on the parameter code (progress bars / stat cards /
/// indicators).
class SqDetailScreen extends StatelessWidget {
  final AnalysisParameter param;
  final String cropName;

  const SqDetailScreen({
    super.key,
    required this.param,
    required this.cropName,
  });

  @override
  Widget build(BuildContext context) {
    final extras = SqDetailsCatalog.forCode(param.code);

    return Scaffold(
      backgroundColor: AppColors.cream,
      // FIX: SingleChildScrollView ensures graceful overflow on small screens.
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ParamHeader(param: param, cropName: cropName),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large circular gauge (color shifts on threshold)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.card,
                    ),
                    child: Center(
                      child: CompatibilityCircle(
                        // TODO: Replace with backend data
                        value: param.currentValue,
                        label: 'Current value vs ideal',
                      ),
                    ),
                  ).animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: 14),
                  // What is this?
                  SectionCard(
                    title: 'What is this?',
                    icon: Icons.help_outline_rounded,
                    accent: AppColors.forestMid,
                    // TODO: Replace with backend data
                    child: Text(
                      param.description,
                      style: AppTextStyles.bodyM,
                    ),
                  ).animate(delay: 80.ms).fadeIn(duration: 350.ms),
                  const SizedBox(height: 12),
                  // Your Soil vs Crop Need (two stat boxes side by side)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          // TODO: Replace with backend data
                          title: 'YOUR VALUE',
                          value: '${param.currentValue}',
                          unit: '/100',
                          chip: param.status.label,
                          chipColor: param.status.color,
                          accent: param.status.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStatCard(
                          // TODO: Replace with backend data
                          title: 'CROP NEEDS',
                          value: param.needDisplay,
                          unit: '',
                          chip: 'Required',
                          chipColor: AppColors.forestMid,
                          accent: AppColors.forestMid,
                        ),
                      ),
                    ],
                  ).animate(delay: 160.ms).fadeIn(duration: 350.ms),
                  const SizedBox(height: 12),
                  // Metrics section (varies by layout)
                  if (extras.metrics.isNotEmpty)
                    _MetricsSection(extras: extras)
                        .animate(delay: 240.ms)
                        .fadeIn(duration: 350.ms),
                  if (extras.metrics.isNotEmpty) const SizedBox(height: 12),
                  // Impact card (amber tint)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.amber.withValues(alpha: 0.18),
                          AppColors.amber.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            color: AppColors.amber,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Impact on Your Crop',
                                style: AppTextStyles.headingS.copyWith(
                                  fontSize: 14,
                                  color: AppColors.amber,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                // TODO: Replace with backend data
                                extras.impact,
                                style: AppTextStyles.bodyM,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 320.ms).fadeIn(duration: 350.ms),
                  const SizedBox(height: 12),
                  // Improvement tips
                  if (extras.tips.isNotEmpty)
                    SectionCard(
                      title: 'Improvement Tips',
                      icon: Icons.tips_and_updates_rounded,
                      accent: AppColors.forestLight,
                      // TODO: Replace with backend data
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final tip in extras.tips)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: 8,
                                      right: 12,
                                    ),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.forestLight,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: AppTextStyles.bodyM,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ).animate(delay: 400.ms).fadeIn(duration: 350.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _ParamHeader extends StatelessWidget {
  final AnalysisParameter param;
  final String cropName;
  const _ParamHeader({required this.param, required this.cropName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        22,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.forest,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.14),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              '${param.code} · $cropName',
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.amber,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${param.code} — ${param.name}',
            style: AppTextStyles.headingXL.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Stat Card (Your Value / Crop Needs) ──────────────────────────────

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String chip;
  final Color chipColor;
  final Color accent;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.chip,
    required this.chipColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyles.headingL.copyWith(
                    fontSize: 24,
                    color: accent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 2),
                  child: Text(
                    unit,
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              chip,
              style: AppTextStyles.bodyS.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Metrics Section ───────────────────────────────────────────────────────

class _MetricsSection extends StatelessWidget {
  final SqExtras extras;
  const _MetricsSection({required this.extras});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.forestMid.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: AppColors.forestMid,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Detailed Metrics',
                style: AppTextStyles.headingS.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          switch (extras.layout) {
            SqMetricLayout.progressBars => _ProgressBarsBody(metrics: extras.metrics),
            SqMetricLayout.statCards => _StatCardsBody(metrics: extras.metrics),
            SqMetricLayout.indicators => _IndicatorsBody(metrics: extras.metrics),
          },
        ],
      ),
    );
  }
}

class _ProgressBarsBody extends StatelessWidget {
  final List<SqMetric> metrics;
  const _ProgressBarsBody({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < metrics.length; i++) ...[
          _ProgressBarRow(metric: metrics[i]),
          if (i != metrics.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  final SqMetric metric;
  const _ProgressBarRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    final color =
        metric.status?.color ?? AppColors.forestMid;
    final pct = (metric.percent ?? 0) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                metric.name,
                style: AppTextStyles.label.copyWith(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              metric.value,
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(
                height: 8,
                color: AppColors.creamSoft,
              ),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.7), color],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCardsBody extends StatelessWidget {
  final List<SqMetric> metrics;
  const _StatCardsBody({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        for (final m in metrics) _StatTile(metric: m),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final SqMetric metric;
  const _StatTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    final color = metric.status?.color ?? AppColors.forestMid;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (metric.icon != null) ...[
                Icon(metric.icon, size: 18, color: color),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  metric.name,
                  style: AppTextStyles.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  metric.value,
                  style: AppTextStyles.headingS.copyWith(
                    fontSize: 17,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (metric.unit != null)
                Padding(
                  padding: const EdgeInsets.only(left: 3, bottom: 2),
                  child: Text(
                    metric.unit!,
                    style: AppTextStyles.bodyS.copyWith(
                      fontSize: 11,
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndicatorsBody extends StatelessWidget {
  final List<SqMetric> metrics;
  const _IndicatorsBody({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < metrics.length; i++) ...[
          _IndicatorRow(metric: metrics[i]),
          if (i != metrics.length - 1)
            Divider(
              color: AppColors.creamSoft,
              height: 16,
              thickness: 1,
            ),
        ],
      ],
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final SqMetric metric;
  const _IndicatorRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    final color = metric.status?.color ?? AppColors.forestMid;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _iconForStatus(metric.status),
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.name,
                style: AppTextStyles.label.copyWith(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                metric.value,
                style: AppTextStyles.bodyS.copyWith(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        if (metric.status != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              metric.status!.label,
              style: AppTextStyles.bodyS.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  IconData _iconForStatus(ParameterStatus? s) {
    switch (s) {
      case ParameterStatus.excellent:
      case ParameterStatus.good:
        return Icons.check_circle_rounded;
      case ParameterStatus.fair:
        return Icons.warning_amber_rounded;
      case ParameterStatus.poor:
        return Icons.error_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}
