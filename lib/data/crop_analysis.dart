import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ParameterStatus { excellent, good, fair, poor }

extension ParameterStatusX on ParameterStatus {
  String get label => switch (this) {
    ParameterStatus.excellent => 'Excellent',
    ParameterStatus.good => 'Good',
    ParameterStatus.fair => 'Fair',
    ParameterStatus.poor => 'Poor',
  };

  Color get color => switch (this) {
    ParameterStatus.excellent => AppColors.forestMid,
    ParameterStatus.good => AppColors.success,
    ParameterStatus.fair => AppColors.amber,
    ParameterStatus.poor => AppColors.error,
  };
}

/// A single soil-quality (SQ) parameter or climate parameter.
class AnalysisParameter {
  final String code; // e.g. "SQ1" or "Temp"
  final String name; // e.g. "Nutrient Availability"
  final String description; // longer explanation
  final int currentValue; // 0–100
  final int needValue; // 0–100
  final String unit; // e.g. "%", "°C", "mm"
  final String currentDisplay; // e.g. "52/85"
  final String needDisplay; // e.g. "85"
  final ParameterStatus status;
  final List<NutrientRow> subBreakdown; // optional sub-items (nutrients, etc.)

  const AnalysisParameter({
    required this.code,
    required this.name,
    required this.description,
    required this.currentValue,
    required this.needValue,
    this.unit = '%',
    required this.currentDisplay,
    required this.needDisplay,
    required this.status,
    this.subBreakdown = const [],
  });
}

class NutrientRow {
  final String name;
  final int soilValue;
  final int needValue;
  final ParameterStatus status;

  const NutrientRow({
    required this.name,
    required this.soilValue,
    required this.needValue,
    required this.status,
  });
}

/// A complete soil + climate compatibility analysis for a given crop.
class CropAnalysis {
  final String cropName;
  final String cropEmoji;
  final String location;
  final int soilMatch; // %
  final int climateMatch; // %
  final String topSoilIssue;
  final String topSoilIssueDesc;
  final String topClimateIssue;
  final String topClimateIssueDesc;
  final int growthDays;
  final String plantDate;
  final String harvestDate;
  final List<AnalysisParameter> soilParams;
  final List<AnalysisParameter> climateParams;

  const CropAnalysis({
    required this.cropName,
    required this.cropEmoji,
    required this.location,
    required this.soilMatch,
    required this.climateMatch,
    required this.topSoilIssue,
    required this.topSoilIssueDesc,
    required this.topClimateIssue,
    required this.topClimateIssueDesc,
    required this.growthDays,
    required this.plantDate,
    required this.harvestDate,
    required this.soilParams,
    required this.climateParams,
  });

  /// TODO: Connect to backend — replace with real per-crop analysis from API.
  factory CropAnalysis.placeholderFor(String cropName, String emoji) {
    return CropAnalysis(
      cropName: cropName,
      cropEmoji: emoji,
      location: 'Sidi Bouzid, Tunisia',
      soilMatch: 74,
      climateMatch: 81,
      topSoilIssue: 'Nitrogen',
      topSoilIssueDesc: 'Below crop need',
      topClimateIssue: 'Frost risk',
      topClimateIssueDesc: 'Slightly elevated',
      growthDays: 110,
      plantDate: '13 Apr',
      harvestDate: '1 May',
      // TODO: Replace with backend data
      soilParams: const [
        AnalysisParameter(
          code: 'SQ1',
          name: 'Nutrient Availability',
          description:
              'Capacity of the soil to supply essential macro and micronutrients to crops.',
          currentValue: 72,
          needValue: 65,
          currentDisplay: '72/100',
          needDisplay: '>65/100',
          status: ParameterStatus.good,
        ),
        AnalysisParameter(
          code: 'SQ2',
          name: 'Nutrient Retention Capacity',
          description:
              'Ability of the soil to hold nutrients and prevent them from leaching out.',
          currentValue: 58,
          needValue: 70,
          currentDisplay: '58/100',
          needDisplay: '>70/100',
          status: ParameterStatus.fair,
        ),
        AnalysisParameter(
          code: 'SQ3',
          name: 'Rooting Conditions',
          description:
              'Physical conditions that affect root penetration and development.',
          currentValue: 81,
          needValue: 70,
          currentDisplay: '81/100',
          needDisplay: '>70/100',
          status: ParameterStatus.good,
        ),
        AnalysisParameter(
          code: 'SQ4',
          name: 'Oxygen Availability',
          description:
              'Drainage and aeration conditions in the active root zone.',
          currentValue: 45,
          needValue: 70,
          currentDisplay: '45/100',
          needDisplay: '>70/100',
          status: ParameterStatus.poor,
        ),
        AnalysisParameter(
          code: 'SQ5',
          name: 'Excess Salts',
          description:
              'Salt concentration that may limit water uptake by crops.',
          currentValue: 88,
          needValue: 70,
          currentDisplay: '88/100',
          needDisplay: '>70/100',
          status: ParameterStatus.excellent,
        ),
        AnalysisParameter(
          code: 'SQ6',
          name: 'Toxicities',
          description:
              'Presence of elements harmful to crop growth (aluminum, manganese, etc.).',
          currentValue: 91,
          needValue: 70,
          currentDisplay: '91/100',
          needDisplay: '>70/100',
          status: ParameterStatus.excellent,
        ),
      ],
      // TODO: Replace with backend data
      climateParams: const [
        AnalysisParameter(
          code: 'CP1',
          name: 'Temperature Regime',
          description:
              'Average growing-season temperature compared to the crop optimum.',
          currentValue: 78,
          needValue: 70,
          unit: '°C',
          currentDisplay: '78/100',
          needDisplay: '>70/100',
          status: ParameterStatus.good,
        ),
        AnalysisParameter(
          code: 'CP2',
          name: 'Rainfall Distribution',
          description:
              'Cumulative rainfall and seasonality during the growth window.',
          currentValue: 60,
          needValue: 70,
          unit: 'mm',
          currentDisplay: '60/100',
          needDisplay: '>70/100',
          status: ParameterStatus.fair,
        ),
        AnalysisParameter(
          code: 'CP3',
          name: 'Humidity Levels',
          description: 'Average relative humidity during key growth phases.',
          currentValue: 68,
          needValue: 65,
          unit: '%',
          currentDisplay: '68/100',
          needDisplay: '>65/100',
          status: ParameterStatus.good,
        ),
        AnalysisParameter(
          code: 'CP4',
          name: 'Sunshine Hours',
          description: 'Daily sunlight exposure during growing season.',
          currentValue: 84,
          needValue: 70,
          unit: 'h',
          currentDisplay: '84/100',
          needDisplay: '>70/100',
          status: ParameterStatus.excellent,
        ),
        AnalysisParameter(
          code: 'CP5',
          name: 'Wind Conditions',
          description:
              'Prevailing wind speeds and risk of mechanical damage.',
          currentValue: 70,
          needValue: 70,
          unit: 'km/h',
          currentDisplay: '70/100',
          needDisplay: '>70/100',
          status: ParameterStatus.good,
        ),
        AnalysisParameter(
          code: 'CP6',
          name: 'Frost Risk',
          description: 'Probability of frost events during the growth window.',
          currentValue: 45,
          needValue: 70,
          unit: '%',
          currentDisplay: '45/100',
          needDisplay: '>70/100',
          status: ParameterStatus.poor,
        ),
      ],
    );
  }
}
