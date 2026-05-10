import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable radar chart that compares "Crop Needs" vs your soil or climate.
class RadarChartCard extends StatelessWidget {
  final String title;
  final List<String> axisLabels;
  final List<double> needValues; // 0–100
  final List<double> yourValues; // 0–100
  final String yourLabel; // e.g. "Your Soil"

  const RadarChartCard({
    super.key,
    required this.title,
    required this.axisLabels,
    required this.needValues,
    required this.yourValues,
    this.yourLabel = 'Your Soil',
  });

  @override
  Widget build(BuildContext context) {
    assert(axisLabels.length == needValues.length);
    assert(axisLabels.length == yourValues.length);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingS.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          Row(
            children: [
              _LegendDot(
                color: AppColors.forestMid,
                label: yourLabel,
                filled: true,
              ),
              const SizedBox(width: 14),
              const _LegendDot(
                color: Color(0xFF3B82F6),
                label: 'Crop Needs',
              ),
            ],
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1.0,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 10,
                ),
                radarBorderData: BorderSide(
                  color: AppColors.creamSoft,
                  width: 1,
                ),
                tickBorderData: BorderSide(
                  color: AppColors.creamSoft,
                  width: 1,
                ),
                gridBorderData: BorderSide(
                  color: AppColors.creamSoft,
                  width: 1,
                ),
                titlePositionPercentageOffset: 0.18,
                getTitle: (index, angle) => RadarChartTitle(
                  text: axisLabels[index],
                  angle: 0,
                ),
                titleTextStyle: AppTextStyles.bodyS.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.forestDark,
                  fontSize: 11,
                ),
                radarBackgroundColor: Colors.transparent,
                dataSets: [
                  // Your value (green filled)
                  RadarDataSet(
                    fillColor: AppColors.forestLight.withValues(alpha: 0.30),
                    borderColor: AppColors.forestMid,
                    borderWidth: 2.5,
                    entryRadius: 3,
                    dataEntries: yourValues
                        .map((v) => RadarEntry(value: v))
                        .toList(),
                  ),
                  // Crop needs (blue line)
                  RadarDataSet(
                    fillColor: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                    borderColor: const Color(0xFF3B82F6),
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: needValues
                        .map((v) => RadarEntry(value: v))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool filled;
  const _LegendDot({
    required this.color,
    required this.label,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodyS.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Compact stat tile used in the 2×2 stats grid on the Soil Profile screen.
class AnalysisStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color accent;

  const AnalysisStatTile({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.accent = AppColors.forestMid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headingM.copyWith(
              fontSize: 22,
              color: accent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: AppTextStyles.bodyS.copyWith(
                fontSize: 11,
                color: AppColors.inkMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
