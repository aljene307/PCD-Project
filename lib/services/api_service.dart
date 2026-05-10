import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FaoQuestion {
  final String id;
  final String question;
  final List<String> options;

  const FaoQuestion({
    required this.id,
    required this.question,
    required this.options,
  });

  factory FaoQuestion.fromJson(Map<String, dynamic> json) => FaoQuestion(
        id: json['id'] as String,
        question: json['question'] as String,
        options: (json['options'] as List).cast<String>(),
      );
}

class CropRecommendation {
  final String cropCode;
  final String cropName;
  final int suitabilityIndexPercentage;
  final double regionalSharePercentage;
  final String suitabilityLabel;
  final bool isSuitable;
  final int? actualYield;
  final int? potentialRegionalYield;
  final int? yieldGap;

  const CropRecommendation({
    required this.cropCode,
    required this.cropName,
    required this.suitabilityIndexPercentage,
    required this.regionalSharePercentage,
    required this.suitabilityLabel,
    required this.isSuitable,
    this.actualYield,
    this.potentialRegionalYield,
    this.yieldGap,
  });
}

class CropInfoData {
  final String commonName;
  final String? scientificName;
  final String? lifeForm;
  final String? physiology;
  final String? habit;
  final String? category;
  final String? lifeSpan;
  final String? plantAttributes;
  final String? notes;

  const CropInfoData({
    required this.commonName,
    this.scientificName,
    this.lifeForm,
    this.physiology,
    this.habit,
    this.category,
    this.lifeSpan,
    this.plantAttributes,
    this.notes,
  });

  String get displayName {
    if (commonName.isEmpty) return '';
    return '${commonName[0].toUpperCase()}${commonName.substring(1)}';
  }

  String get primaryCategory => category?.split(',').first.trim() ?? '';

  factory CropInfoData.fromJson(Map<String, dynamic> json) => CropInfoData(
        commonName: json['common_name'] as String? ?? '',
        scientificName: json['scientific_name'] as String?,
        lifeForm: json['life_form'] as String?,
        physiology: json['physiology'] as String?,
        habit: json['habit'] as String?,
        category: json['category'] as String?,
        lifeSpan: json['life_span'] as String?,
        plantAttributes: json['plant_attributes'] as String?,
        notes: json['notes'] as String?,
      );
}

class CropCalendar {
  final String cropCode;
  final int growthDays;
  final String plantingDate;
  final String harvestDate;

  const CropCalendar({
    required this.cropCode,
    required this.growthDays,
    required this.plantingDate,
    required this.harvestDate,
  });

  factory CropCalendar.fromJson(Map<String, dynamic> json) => CropCalendar(
        cropCode: json['crop_code'] as String,
        growthDays: (json['growth_days'] as num).toInt(),
        plantingDate: json['planting_date'] as String,
        harvestDate: json['harvest_date'] as String,
      );
}

class EconomicResult {
  final String cropName;
  final double cropCost;
  final double cropYield;
  final double farmPrice;
  final double grossRevenue;
  final double netRevenue;

  const EconomicResult({
    required this.cropName,
    required this.cropCost,
    required this.cropYield,
    required this.farmPrice,
    required this.grossRevenue,
    required this.netRevenue,
  });

  factory EconomicResult.fromJson(Map<String, dynamic> json) => EconomicResult(
        cropName: json['crop_name'] as String,
        cropCost: (json['crop_cost'] as num).toDouble(),
        cropYield: (json['crop_yield'] as num).toDouble(),
        farmPrice: (json['farm_price'] as num).toDouble(),
        grossRevenue: (json['gross_revenue'] as num).toDouble(),
        netRevenue: (json['net_revenue'] as num).toDouble(),
      );
}

class SoilLayer {
  final String code;
  final double? ph;
  final double? oc;
  final String? txt;
  final String? drg;
  final double? cecSoil;
  final double? cecClay;
  final double? teb;
  final double? bs;
  final double? esp;
  final double? ec;
  final double? ccb;
  final double? gyp;
  final double? grc;
  final double? rsd;

  const SoilLayer({
    required this.code,
    this.ph,
    this.oc,
    this.txt,
    this.drg,
    this.cecSoil,
    this.cecClay,
    this.teb,
    this.bs,
    this.esp,
    this.ec,
    this.ccb,
    this.gyp,
    this.grc,
    this.rsd,
  });

  factory SoilLayer.fromJson(String code, Map<String, dynamic> json) =>
      SoilLayer(
        code: code,
        ph: _d(json['pH']),
        oc: _d(json['OC']),
        txt: json['TXT'] as String?,
        drg: json['DRG'] as String?,
        cecSoil: _d(json['CEC_soil']),
        cecClay: _d(json['CEC_clay']),
        teb: _d(json['TEB']),
        bs: _d(json['BS']),
        esp: _d(json['ESP']),
        ec: _d(json['EC']),
        ccb: _d(json['CCB']),
        gyp: _d(json['GYP']),
        grc: _d(json['GRC']),
        rsd: _d(json['RSD']),
      );

  static double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
}

class SoilConstraintData {
  final double nutrientAvailability;
  final double nutrientRetentionCapacity;
  final double rootingConditions;
  final double oxygenAvailability;
  final double salinityAndSodicity;
  final double workability;
  final String mostLimitingFactor;

  const SoilConstraintData({
    required this.nutrientAvailability,
    required this.nutrientRetentionCapacity,
    required this.rootingConditions,
    required this.oxygenAvailability,
    required this.salinityAndSodicity,
    required this.workability,
    required this.mostLimitingFactor,
  });

  int get sq1 => (nutrientAvailability * 100).round().clamp(0, 100);
  int get sq2 => (nutrientRetentionCapacity * 100).round().clamp(0, 100);
  int get sq3 => (rootingConditions * 100).round().clamp(0, 100);
  int get sq4 => (oxygenAvailability * 100).round().clamp(0, 100);
  int get sq5 => (salinityAndSodicity * 100).round().clamp(0, 100);
  int get sq6 => (workability * 100).round().clamp(0, 100);

  String get topIssueLabel => mostLimitingFactor
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  factory SoilConstraintData.fromJson(Map<String, dynamic> json) =>
      SoilConstraintData(
        nutrientAvailability:
            (json['nutrient_availability'] as num).toDouble(),
        nutrientRetentionCapacity:
            (json['nutrient_retention_capacity'] as num).toDouble(),
        rootingConditions:
            (json['rooting_conditions'] as num).toDouble(),
        oxygenAvailability:
            (json['oxygen_availability'] as num).toDouble(),
        salinityAndSodicity:
            (json['salinity_and_sodicity'] as num).toDouble(),
        workability: (json['workability'] as num).toDouble(),
        mostLimitingFactor: json['most_limiting_factor'] as String,
      );
}

class LabMeasurement {
  final String attribute;
  final String isoMethod;
  final String unit;
  final num value;

  const LabMeasurement({
    required this.attribute,
    required this.isoMethod,
    required this.unit,
    required this.value,
  });

  factory LabMeasurement.fromJson(Map<String, dynamic> json) => LabMeasurement(
        attribute: json['attribute'] as String,
        isoMethod: json['iso_method'] as String,
        unit: json['unit'] as String,
        value: json['value'] as num,
      );

  Map<String, dynamic> toJson() => {
        'attribute': attribute,
        'iso_method': isoMethod,
        'unit': unit,
        'value': value,
      };
}

class ApiService {
  static const _base = 'https://lafayette-classifieds-settlement-parish.trycloudflare.com';
  static const _localBase = 'http://127.0.0.1:8000';

  static const _headers = {
    'accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static const _getHeaders = {
    'accept': 'application/json',
  };

  static Future<void> postOnboarding({
    required String userId,
    required bool labReportExists,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/onboarding'),
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'lab_report_exists': labReportExists,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Onboarding request failed (${response.statusCode})');
    }
  }

  static Future<void> postSubmitInput({
    required String userId,
    required double latitude,
    required double longitude,
    required String inputLevel,
    required String waterSupply,
    String? irrigationType,
    List<LabMeasurement>? labMeasurements,
  }) async {
    final body = <String, dynamic>{
      'coord': [latitude, longitude],
      'input_level': inputLevel,
      'user_id': userId,
      'water_supply': waterSupply,
      if (irrigationType != null) 'irrigation_type': irrigationType,
      if (labMeasurements != null && labMeasurements.isNotEmpty)
        'lab_report': {
          for (final m in labMeasurements)
            m.attribute: {
              'iso_method': m.isoMethod,
              'unit': m.unit,
              'value': m.value,
            },
        },
    };

    final response = await http.post(
      Uri.parse('$_base/submit-input'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      String detail = 'Request failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }
  }

  static Future<List<FaoQuestion>> getFaoQuestions(String userId) async {
    final response = await http.get(
      Uri.parse('$_base/wrb-decision/get-questions/$userId'),
      headers: _getHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load questions (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = decoded['data']['questions'] as List<dynamic>;
    return list
        .map((q) => FaoQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  /// Report path: GET /report/crop-recommendations/{user_id}
  /// Maps yield-based response to CropRecommendation for reuse in RanksScreen.
  static Future<List<CropRecommendation>> getReportCropRecommendations(
    String userId,
  ) async {
    final url = '$_base/report/crop-recommendations/$userId';
    debugPrint('[ReportCrops] GET $url');

    final http.Response response;
    try {
      response = await http.get(Uri.parse(url), headers: _getHeaders);
    } catch (netErr) {
      debugPrint('[ReportCrops] Network-level error: $netErr');
      rethrow;
    }

    debugPrint('[ReportCrops] status=${response.statusCode}');
    final preview = response.body.length > 400
        ? response.body.substring(0, 400)
        : response.body;
    debugPrint('[ReportCrops] body=$preview');

    if (response.statusCode != 200) {
      String detail = 'Server error ${response.statusCode} on /report/crop-recommendations';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    final Map<String, dynamic> decoded;
    final List<dynamic> list;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rawData = decoded['data'];
      if (rawData is Map<String, dynamic>) {
        list = rawData['suitability'] as List<dynamic>;
      } else if (rawData is List<dynamic>) {
        list = rawData;
      } else {
        throw Exception('Unexpected data format in response');
      }
    } catch (parseErr) {
      debugPrint('[ReportCrops] Parse error: $parseErr');
      rethrow;
    }

    final results = <CropRecommendation>[];
    for (final s in list) {
      final sm = s as Map<String, dynamic>;
      final hasYield = sm['has_yield'] as bool;
      final actualYield = (sm['actual_yield'] as num?)?.toInt() ?? 0;
      final potentialYield =
          (sm['potential_regional_yield'] as num?)?.toInt() ?? 0;
      final yieldGapPct = (sm['yield_gap_pct'] as num?)?.toDouble();
      final yieldGap = (sm['yield_gap'] as num?)?.toInt() ?? 0;

      // Drop entries with zero actual and zero potential — truly no data.
      if (!hasYield && potentialYield == 0) continue;

      // Yield-achievement percentage as a suitability proxy (0–100).
      final suitabilityPct = potentialYield > 0
          ? ((actualYield / potentialYield) * 100).clamp(0.0, 100.0).round()
          : 0;

      // Derive a label the card's colour-coding already understands.
      final String label;
      if (!hasYield) {
        label = 'Marginal';
      } else if (yieldGapPct != null && yieldGapPct <= 55) {
        label = 'Highly Suitable';
      } else if (yieldGapPct != null && yieldGapPct <= 75) {
        label = 'Suitable';
      } else {
        label = 'Marginal';
      }

      // Regional-share proxy: invert the yield-gap percentage.
      final regionalShare =
          yieldGapPct != null ? (100.0 - yieldGapPct).clamp(0.0, 100.0) : 0.0;

      results.add(CropRecommendation(
        cropCode: sm['crop_code'] as String,
        cropName: sm['crop_name'] as String,
        suitabilityIndexPercentage: suitabilityPct,
        regionalSharePercentage: regionalShare,
        suitabilityLabel: label,
        isSuitable: hasYield,
        actualYield: actualYield,
        potentialRegionalYield: potentialYield,
        yieldGap: yieldGap,
      ));
    }

    return results;
  }

  /// Global path: GET /global/crop-recommendations/{user_id}
  static Future<List<CropRecommendation>> getCropRecommendations(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('$_base/global/crop-recommendations/$userId'),
      headers: _getHeaders,
    );

    if (response.statusCode != 200) {
      String detail =
          'Failed to load recommendations (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    debugPrint('[getCropRecommendations] raw: ${response.body}');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;

    final suitabilityList = data['suitability'] as List<dynamic>;
    final yieldList = data['yield'] as List<dynamic>;
    debugPrint('[getCropRecommendations] suitability count: ${suitabilityList.length}, yield count: ${yieldList.length}');

    final yieldByCode = <String, Map<String, dynamic>>{
      for (final y in yieldList)
        (y as Map<String, dynamic>)['crop_code'] as String: y,
    };

    final results = <CropRecommendation>[];
    for (final s in suitabilityList) {
      final sm = s as Map<String, dynamic>;
      final isSuitable = sm['is_suitable'] as bool;
      final rawPct = (sm['suitability_index_percentage'] as num).toDouble();
      final pct = rawPct > 1.0 ? rawPct.round() : (rawPct * 100).round();
      if (!isSuitable && pct == 0) continue;

      final code = sm['crop_code'] as String;
      final yd = yieldByCode[code];

      final rawRegional = (sm['regional_share_percentage'] as num).toDouble();
      final regional = rawRegional > 1.0 ? rawRegional : rawRegional * 100.0;

      results.add(CropRecommendation(
        cropCode: code,
        cropName: sm['crop_name'] as String,
        suitabilityIndexPercentage: pct,
        regionalSharePercentage: regional,
        suitabilityLabel: sm['suitability_label'] as String,
        isSuitable: isSuitable,
        actualYield: yd != null ? (yd['actual_yield'] as num?)?.toInt() : null,
        potentialRegionalYield: yd != null
            ? (yd['potential_regional_yield'] as num?)?.toInt()
            : null,
        yieldGap:
            yd != null ? (yd['yield_gap'] as num?)?.toInt() : null,
      ));
    }

    return results;
  }

  static Future<List<CropInfoData>> getCropsInfo() async {
    final response = await http.get(
      Uri.parse('$_base/crops-info'),
      headers: _getHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load crops info (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    return data.values
        .map((v) => CropInfoData.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CropCalendar>> getCropCalendar(String userId) async {
    final response = await http.get(
      Uri.parse('$_base/calendar/$userId'),
      headers: _getHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load calendar (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = decoded['data'] as List<dynamic>;
    return list
        .map((e) => CropCalendar.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<EconomicResult> postEconomicsSuitability({
    required String cropName,
    required double cropCost,
    required double cropYield,
    required double farmPrice,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/economics/suitability'),
      headers: _headers,
      body: jsonEncode({
        'crop_name': cropName,
        'crop_cost': cropCost,
        'crop_yield': cropYield,
        'farm_price': farmPrice,
      }),
    );

    if (response.statusCode != 200) {
      String detail = 'Request failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return EconomicResult.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  /// Report path: GET /report/your-augmented-soil-properties/{user_id}
  /// Same layer structure as getSoilProperties but enriched with lab data.
  static Future<List<SoilLayer>> getReportSoilProperties(String userId) async {
    final response = await http.get(
      Uri.parse('$_base/report/your-augmented-soil-properties/$userId'),
      headers: _getHeaders,
    );

    if (response.statusCode != 200) {
      String detail = 'Failed to load soil properties (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    const codes = ['D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7'];
    return codes
        .where((c) => data.containsKey(c))
        .map((c) => SoilLayer.fromJson(c, data[c] as Map<String, dynamic>))
        .toList();
  }

  static Future<List<SoilLayer>> getSoilProperties(String userId) async {
    final response = await http.get(
      Uri.parse('$_base/your-hwsd-soil-properties/$userId'),
      headers: _getHeaders,
    );

    if (response.statusCode != 200) {
      String detail = 'Failed to load soil properties (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    const codes = ['D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7'];
    return codes
        .where((c) => data.containsKey(c))
        .map((c) => SoilLayer.fromJson(c, data[c] as Map<String, dynamic>))
        .toList();
  }

  /// Report path: GET /report/soil-constraint-factor/{user_id}
  /// Returns per-crop constraint data; looks up the specific crop by name.
  static Future<SoilConstraintData> getReportSoilConstraintFactor({
    required String userId,
    required String cropName,
  }) async {
    final response = await http.get(
      Uri.parse('$_base/report/soil-constraint-factor/$userId'),
      headers: _getHeaders,
    );

    if (response.statusCode != 200) {
      String detail = 'Failed to load soil data (${response.statusCode})';
      try {
        final d = jsonDecode(response.body) as Map<String, dynamic>;
        if (d['detail'] is String) detail = d['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;

    // Look up the specific crop; fall back to case-insensitive, then first entry.
    Map<String, dynamic>? cropData =
        data[cropName] as Map<String, dynamic>?;
    if (cropData == null) {
      final key = data.keys.firstWhere(
        (k) => k.toLowerCase() == cropName.toLowerCase(),
        orElse: () => '',
      );
      if (key.isNotEmpty) cropData = data[key] as Map<String, dynamic>;
    }
    cropData ??= data.values.first as Map<String, dynamic>;

    return SoilConstraintData.fromJson(cropData);
  }

  static Future<SoilConstraintData> getSoilConstraintFactor(
      String userId) async {
    final response = await http.get(
      Uri.parse('$_base/global/soil-constraint-factor/$userId'),
      headers: _getHeaders,
    );

    if (response.statusCode != 200) {
      String detail =
          'Failed to load soil data (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return SoilConstraintData.fromJson(
        decoded['data'] as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> getCropsNeeds(String userId) async {
    final response = await http.get(
      Uri.parse('$_base/crops-needs/$userId'),
      headers: _getHeaders,
    );

    if (response.statusCode != 200) {
      String detail = 'Failed to load crops needs (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    // Response is { "data": { "wheat": {...}, "maize": {...}, ... } }
    return decoded['data'] as Map<String, dynamic>;
  }

  static Future<void> postFaoAnswers({
    required String userId,
    required Map<String, String> answers,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/wrb-decision/post-answers'),
      headers: _headers,
      body: jsonEncode({
        'answers': answers,
        'user_id': userId,
      }),
    );

    if (response.statusCode != 200) {
      String detail = 'Request failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }
  }

  /// Returns raw soil layer dict {D1: {...}, D2: {...}, ...} for advisor init.
  static Future<Map<String, dynamic>> getSoilLayersRaw(String userId) async {
    final response = await http.get(
      Uri.parse('$_base/your-hwsd-soil-properties/$userId'),
      headers: _getHeaders,
    );

    if (response.statusCode != 200) {
      String detail = 'Failed to load soil layers (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['data'] as Map<String, dynamic>;
  }

  /// Report path: GET /report/your-augmented-soil-properties/{user_id}
  /// Returns raw soil layer dict {D1: {...}, D2: {...}, ...} for advisor init.
  static Future<Map<String, dynamic>> getReportSoilLayersRaw(
      String userId) async {
    final response = await http.get(
      Uri.parse('$_base/report/your-augmented-soil-properties/$userId'),
      headers: _getHeaders,
    );

    if (response.statusCode != 200) {
      String detail = 'Failed to load soil layers (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['data'] as Map<String, dynamic>;
  }

  /// Create a new advisor session; returns the session_id.
  static Future<String> initAdvisorSession({
    required String userId,
    required Map<String, dynamic> soilLayers,
    required Map<String, dynamic> cropRequirements,
  }) async {
    final response = await http.post(
      Uri.parse('$_localBase/advisor/session/init'),
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'soil_layers': soilLayers,
        'crop_requirements': cropRequirements,
      }),
    );

    debugPrint('[Advisor/init] status=${response.statusCode}');
    debugPrint('[Advisor/init] body=${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');

    if (response.statusCode != 200) {
      String detail = 'Failed to start advisor session (${response.statusCode})';
      try {
        final d = jsonDecode(response.body) as Map<String, dynamic>;
        if (d['detail'] is String) detail = d['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    // Try top-level first, then wrapped under 'data'.
    final data = decoded['data'];
    final sessionId = decoded['session_id'] as String? ??
        (data is Map ? data['session_id'] as String? : null);
    if (sessionId == null) {
      throw Exception('session_id not found in response. Body: ${response.body}');
    }
    return sessionId;
  }

  /// Send a chat message; returns the AI reply string.
  static Future<String> sendAdvisorMessage({
    required String sessionId,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$_localBase/advisor/chat/message'),
      headers: _headers,
      body: jsonEncode({
        'session_id': sessionId,
        'message': message,
      }),
    );

    debugPrint('[Advisor/msg] status=${response.statusCode}');
    debugPrint('[Advisor/msg] body=${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');

    if (response.statusCode != 200) {
      String detail = 'Failed to send message (${response.statusCode})';
      try {
        final d = jsonDecode(response.body) as Map<String, dynamic>;
        if (d['detail'] is String) detail = d['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    // Try common reply key names at top-level and under 'data'.
    final reply = decoded['reply'] as String? ??
        decoded['response'] as String? ??
        decoded['message'] as String? ??
        decoded['content'] as String? ??
        (data is Map ? data['reply'] as String? : null) ??
        (data is Map ? data['response'] as String? : null) ??
        (data is Map ? data['message'] as String? : null) ??
        (data is String ? data : null);
    if (reply == null) {
      throw Exception('No reply key in response. Body: ${response.body}');
    }
    return reply;
  }

  /// Step 1: Send PDF to local OCR service → returns extracted measurements.
  static Future<List<LabMeasurement>> postLabExtractFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('$_localBase/lab/extract/file');
    final request = http.MultipartRequest('POST', uri)
      ..headers['accept'] = 'application/json'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      String detail = 'OCR extraction failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = decoded['measurements'] as List<dynamic>;
    return list
        .map((e) => LabMeasurement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Step 2: Forward extracted measurements to the main backend.
  static Future<void> postLabReport({
    required String userId,
    required List<LabMeasurement> measurements,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/lab-report'),
      headers: _headers,
      body: jsonEncode({
        'lab_report': {
          for (final m in measurements)
            m.attribute: {
              'iso_method': m.isoMethod,
              'unit': m.unit,
              'value': m.value,
            },
        },
        'user_id': userId,
      }),
    );

    if (response.statusCode != 200) {
      String detail = 'Failed to save lab report (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) detail = decoded['detail'] as String;
      } catch (_) {}
      throw Exception(detail);
    }
  }
}
