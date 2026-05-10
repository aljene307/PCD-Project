import 'package:flutter/material.dart';
import 'crop_analysis.dart';

/// Layout style for the metrics section of an SQ/CP detail screen.
enum SqMetricLayout { progressBars, statCards, indicators }

/// One row inside the metrics section.
/// - For [SqMetricLayout.progressBars]: uses [percent] and [status]
/// - For [SqMetricLayout.statCards]: uses [value], [unit] and [icon]
/// - For [SqMetricLayout.indicators]: uses [value] and [status]
class SqMetric {
  final String name;
  final String value;
  final String? unit;
  final int? percent;
  final IconData? icon;
  final ParameterStatus? status;

  const SqMetric({
    required this.name,
    required this.value,
    this.unit,
    this.percent,
    this.icon,
    this.status,
  });
}

/// Rich extras (impact text, tips, layout, metrics) per SQ/CP code.
class SqExtras {
  final SqMetricLayout layout;
  final List<SqMetric> metrics;
  final String impact;
  final List<String> tips;

  const SqExtras({
    required this.layout,
    required this.metrics,
    required this.impact,
    required this.tips,
  });
}

/// Catalog of SQ1-SQ6 + CP1-CP6 placeholder content.
/// TODO: Replace with backend data
class SqDetailsCatalog {
  static SqExtras forCode(String code) {
    switch (code) {
      // ── Soil Quality ───────────────────────────────────────────────────
      case 'SQ1':
        return const SqExtras(
          layout: SqMetricLayout.progressBars,
          metrics: [
            SqMetric(
              name: 'Nitrogen',
              value: '78%',
              percent: 78,
              status: ParameterStatus.good,
            ),
            SqMetric(
              name: 'Phosphorus',
              value: '65%',
              percent: 65,
              status: ParameterStatus.fair,
            ),
            SqMetric(
              name: 'Potassium',
              value: '81%',
              percent: 81,
              status: ParameterStatus.good,
            ),
            SqMetric(
              name: 'pH Balance',
              value: '70%',
              percent: 70,
              status: ParameterStatus.good,
            ),
          ],
          impact:
              'High nutrient availability increases yield potential by up to 40%.',
          tips: [
            'Apply a balanced NPK fertilizer based on soil test recommendations.',
            'Incorporate compost or aged manure to boost organic matter.',
            'Test soil pH annually and adjust with lime or sulfur as needed.',
          ],
        );

      case 'SQ2':
        return const SqExtras(
          layout: SqMetricLayout.progressBars,
          metrics: [
            SqMetric(
              name: 'Cation Exchange Capacity',
              value: '55%',
              percent: 55,
              status: ParameterStatus.fair,
            ),
            SqMetric(
              name: 'Organic Matter %',
              value: '48%',
              percent: 48,
              status: ParameterStatus.poor,
            ),
            SqMetric(
              name: 'Base Saturation',
              value: '70%',
              percent: 70,
              status: ParameterStatus.good,
            ),
          ],
          impact:
              'Good retention prevents fertilizer waste and protects groundwater.',
          tips: [
            'Add organic matter (compost, cover crops) to raise CEC.',
            'Avoid over-tilling — preserve soil structure and humus.',
            'Use slow-release fertilizers to minimize leaching losses.',
          ],
        );

      case 'SQ3':
        return const SqExtras(
          layout: SqMetricLayout.statCards,
          metrics: [
            SqMetric(
              name: 'Soil Depth',
              value: '85',
              unit: 'cm',
              icon: Icons.height_rounded,
              status: ParameterStatus.good,
            ),
            SqMetric(
              name: 'Bulk Density',
              value: '1.32',
              unit: 'g/cm³',
              icon: Icons.compress_rounded,
              status: ParameterStatus.good,
            ),
            SqMetric(
              name: 'Texture Class',
              value: 'Clay Loam',
              icon: Icons.layers_rounded,
              status: ParameterStatus.good,
            ),
            SqMetric(
              name: 'Stoniness',
              value: 'Low (<5%)',
              icon: Icons.scatter_plot_rounded,
              status: ParameterStatus.excellent,
            ),
          ],
          impact:
              'Healthy rooting depth boosts drought resilience and nutrient uptake.',
          tips: [
            'Avoid heavy machinery on wet soil — it causes compaction.',
            'Deep tillage every 3-4 years can break compacted layers.',
            'Plant deep-rooted cover crops to naturally aerate the soil.',
          ],
        );

      case 'SQ4':
        return const SqExtras(
          layout: SqMetricLayout.indicators,
          metrics: [
            SqMetric(
              name: 'Drainage Class',
              value: 'Poorly Drained',
              status: ParameterStatus.poor,
            ),
            SqMetric(
              name: 'Flooding Risk',
              value: 'Moderate',
              status: ParameterStatus.fair,
            ),
            SqMetric(
              name: 'Waterlogging',
              value: '38 days/year',
              status: ParameterStatus.poor,
            ),
          ],
          impact:
              'Poor drainage can reduce yields by 20-50% in sensitive crops.',
          tips: [
            'Install subsurface drainage or open ditches to remove excess water.',
            'Build raised beds for moisture-sensitive crops.',
            'Add organic matter to improve soil structure and infiltration.',
          ],
        );

      case 'SQ5':
        return const SqExtras(
          layout: SqMetricLayout.progressBars,
          metrics: [
            SqMetric(
              name: 'Electrical Conductivity',
              value: '0.4 dS/m',
              percent: 88,
              status: ParameterStatus.excellent,
            ),
            SqMetric(
              name: 'Sodium Adsorption Ratio',
              value: '2.1',
              percent: 90,
              status: ParameterStatus.excellent,
            ),
            SqMetric(
              name: 'Sodicity Risk',
              value: 'Very Low',
              percent: 92,
              status: ParameterStatus.excellent,
            ),
          ],
          impact:
              'Low salt levels mean unrestricted water uptake and full yield potential.',
          tips: [
            'Maintain good drainage to prevent salt accumulation.',
            'Use clean irrigation water — test EC before extended use.',
            'Apply gypsum if sodicity rises above safe thresholds.',
          ],
        );

      case 'SQ6':
        return const SqExtras(
          layout: SqMetricLayout.indicators,
          metrics: [
            SqMetric(
              name: 'Aluminum Toxicity',
              value: 'No Risk',
              status: ParameterStatus.excellent,
            ),
            SqMetric(
              name: 'Manganese Toxicity',
              value: 'No Risk',
              status: ParameterStatus.excellent,
            ),
            SqMetric(
              name: 'Acidity Level',
              value: 'pH 6.8 (Optimal)',
              status: ParameterStatus.excellent,
            ),
          ],
          impact:
              'No toxic elements detected — crops can express full genetic potential.',
          tips: [
            'Continue regular soil tests to detect changes early.',
            'Avoid heavy metal-contaminated amendments.',
            'Maintain pH near neutral to keep toxic metals immobile.',
          ],
        );

      // ── Climate Profile ────────────────────────────────────────────────
      case 'CP1':
        return const SqExtras(
          layout: SqMetricLayout.progressBars,
          metrics: [
            SqMetric(
              name: 'Mean Annual Temp',
              value: '18.4°C',
              percent: 78,
              status: ParameterStatus.good,
            ),
            SqMetric(
              name: 'Growing Season Avg',
              value: '22.1°C',
              percent: 80,
              status: ParameterStatus.good,
            ),
            SqMetric(
              name: 'Diurnal Range',
              value: '14.5°C',
              percent: 70,
              status: ParameterStatus.good,
            ),
          ],
          impact:
              'A favorable temperature regime drives healthy crop development.',
          tips: [
            'Use shade nets during peak heat for sensitive crops.',
            'Mulch heavily to moderate soil temperature swings.',
            'Time sowing to align with the optimal temperature window.',
          ],
        );

      case 'CP2':
        return const SqExtras(
          layout: SqMetricLayout.progressBars,
          metrics: [
            SqMetric(
              name: 'Annual Rainfall',
              value: '420 mm',
              percent: 60,
              status: ParameterStatus.fair,
            ),
            SqMetric(
              name: 'Rainfall in Growing Season',
              value: '280 mm',
              percent: 65,
              status: ParameterStatus.fair,
            ),
            SqMetric(
              name: 'Distribution Evenness',
              value: 'Winter Dominant',
              percent: 55,
              status: ParameterStatus.fair,
            ),
          ],
          impact:
              'Uneven rainfall can lead to drought stress during critical phases.',
          tips: [
            'Install drip irrigation to deliver water precisely when needed.',
            'Build small reservoirs to capture winter rainfall for summer use.',
            'Mulch generously to retain soil moisture between rains.',
          ],
        );

      case 'CP3':
        return const SqExtras(
          layout: SqMetricLayout.progressBars,
          metrics: [
            SqMetric(
              name: 'Average Humidity',
              value: '62%',
              percent: 68,
              status: ParameterStatus.good,
            ),
            SqMetric(
              name: 'Morning Humidity',
              value: '78%',
              percent: 75,
              status: ParameterStatus.good,
            ),
            SqMetric(
              name: 'Disease Risk Index',
              value: 'Moderate',
              percent: 60,
              status: ParameterStatus.fair,
            ),
          ],
          impact:
              'Balanced humidity supports growth without inviting disease.',
          tips: [
            'Use drip rather than overhead irrigation to keep foliage dry.',
            'Space plants for good airflow and faster drying.',
            'Scout regularly for fungal symptoms during humid spells.',
          ],
        );

      case 'CP4':
        return const SqExtras(
          layout: SqMetricLayout.statCards,
          metrics: [
            SqMetric(
              name: 'Annual Sunshine',
              value: '2680',
              unit: 'hrs',
              icon: Icons.wb_sunny_rounded,
              status: ParameterStatus.excellent,
            ),
            SqMetric(
              name: 'Daily Avg',
              value: '7.3',
              unit: 'hrs',
              icon: Icons.light_mode_rounded,
              status: ParameterStatus.excellent,
            ),
            SqMetric(
              name: 'Cloudy Days',
              value: '68',
              unit: 'days',
              icon: Icons.cloud_outlined,
              status: ParameterStatus.good,
            ),
            SqMetric(
              name: 'Solar Index',
              value: 'Very High',
              icon: Icons.bolt_rounded,
              status: ParameterStatus.excellent,
            ),
          ],
          impact:
              'Abundant sunshine maximizes photosynthesis and yield potential.',
          tips: [
            'Use light-reflective mulches to maximize energy capture.',
            'Match crop varieties to long-day growing conditions.',
            'Consider shade structures for heat-sensitive vegetables.',
          ],
        );

      case 'CP5':
        return const SqExtras(
          layout: SqMetricLayout.indicators,
          metrics: [
            SqMetric(
              name: 'Average Wind Speed',
              value: '3.2 m/s',
              status: ParameterStatus.good,
            ),
            SqMetric(
              name: 'Peak Gusts',
              value: '12 m/s',
              status: ParameterStatus.fair,
            ),
            SqMetric(
              name: 'Erosion Risk',
              value: 'Low',
              status: ParameterStatus.good,
            ),
          ],
          impact:
              'Moderate wind aids transpiration but can damage tall crops.',
          tips: [
            'Plant windbreaks (cypress, eucalyptus) along prevailing wind edges.',
            'Stake or trellis tall crops to prevent lodging.',
            'Use cover crops in winter to prevent topsoil erosion.',
          ],
        );

      case 'CP6':
        return const SqExtras(
          layout: SqMetricLayout.indicators,
          metrics: [
            SqMetric(
              name: 'Frost Days/Year',
              value: '18 days',
              status: ParameterStatus.poor,
            ),
            SqMetric(
              name: 'Last Spring Frost',
              value: 'Mid April',
              status: ParameterStatus.fair,
            ),
            SqMetric(
              name: 'First Autumn Frost',
              value: 'Late November',
              status: ParameterStatus.fair,
            ),
          ],
          impact:
              'Frost events can wipe out flowering crops in a single night.',
          tips: [
            'Delay transplanting until the last spring frost has passed.',
            'Use frost cloth or sprinklers on cold nights to protect blossoms.',
            'Choose late-flowering varieties in frost-prone areas.',
          ],
        );

      default:
        return const SqExtras(
          layout: SqMetricLayout.progressBars,
          metrics: [],
          impact: 'No additional context available for this parameter.',
          tips: [],
        );
    }
  }
}
