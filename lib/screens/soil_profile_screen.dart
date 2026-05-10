import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import '../data/app_session.dart';
import '../data/coord_history.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../data/crop_analysis.dart';
import '../widgets/compatibility_circle.dart';
import '../widgets/custom_button.dart';
import '../widgets/radar_chart_card.dart';
import '../utils/page_transitions.dart';
import 'economic_calculator_screen.dart';

enum ProfileTab { soil, climate }

class SoilProfileScreen extends StatefulWidget {
  final String cropName;
  final String cropCode;
  final String cropEmoji;
  final ProfileTab initialTab;

  const SoilProfileScreen({
    super.key,
    required this.cropName,
    required this.cropCode,
    required this.cropEmoji,
    this.initialTab = ProfileTab.soil,
  });

  @override
  State<SoilProfileScreen> createState() => _SoilProfileScreenState();
}

class _SoilProfileScreenState extends State<SoilProfileScreen> {
  late ProfileTab _tab;
  late CropAnalysis _analysis;
  bool _soilLoading = true;

  String _growthText = '...';
  String _plantDate = '...';
  String _harvestDate = '...';

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _analysis = CropAnalysis.placeholderFor(widget.cropName, widget.cropEmoji);
    _loadCalendar();
    _loadSoilConstraint();
  }

  bool _calCodeMatches(String calCode, String recCode) {
    if (calCode.isEmpty || recCode.isEmpty) return false;
    final c = calCode.toUpperCase();
    final r = recCode.toUpperCase();
    return c == r || c.startsWith(r) || r.startsWith(c);
  }

  Future<void> _loadCalendar() async {
    try {
      final entries = await ApiService.getCropCalendar(AppSession.userId);
      final match = entries
          .where((e) => _calCodeMatches(e.cropCode, widget.cropCode))
          .firstOrNull;
      if (!mounted) return;
      setState(() {
        if (match != null) {
          _growthText = '${match.growthDays} days';
          _plantDate = match.plantingDate;
          _harvestDate = match.harvestDate;
        } else {
          _growthText = 'N/A';
          _plantDate = 'N/A';
          _harvestDate = 'N/A';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _growthText = 'N/A';
        _plantDate = 'N/A';
        _harvestDate = 'N/A';
      });
    }
  }

  static ParameterStatus _statusFor(int v) {
    if (v >= 85) return ParameterStatus.excellent;
    if (v >= 70) return ParameterStatus.good;
    if (v >= 50) return ParameterStatus.fair;
    return ParameterStatus.poor;
  }

  Future<void> _loadSoilConstraint() async {
    try {
      final data = AppSession.hasLabData
          ? await ApiService.getReportSoilConstraintFactor(
              userId: AppSession.userId,
              cropName: widget.cropName,
            )
          : await ApiService.getSoilConstraintFactor(AppSession.userId);
      if (!mounted) return;
      final sq = [data.sq1, data.sq2, data.sq3, data.sq4, data.sq5, data.sq6];
      setState(() {
        _soilLoading = false;
        _analysis = CropAnalysis(
          cropName: _analysis.cropName,
          cropEmoji: _analysis.cropEmoji,
          location: _analysis.location,
          soilMatch: _analysis.soilMatch,
          climateMatch: _analysis.climateMatch,
          topSoilIssue: data.topIssueLabel,
          topSoilIssueDesc: 'Most limiting soil factor',
          topClimateIssue: _analysis.topClimateIssue,
          topClimateIssueDesc: _analysis.topClimateIssueDesc,
          growthDays: _analysis.growthDays,
          plantDate: _analysis.plantDate,
          harvestDate: _analysis.harvestDate,
          climateParams: _analysis.climateParams,
          soilParams: [
            for (int i = 0; i < _analysis.soilParams.length; i++)
              AnalysisParameter(
                code: _analysis.soilParams[i].code,
                name: _analysis.soilParams[i].name,
                description: _analysis.soilParams[i].description,
                currentValue: sq[i],
                needValue: 70,
                currentDisplay: '${sq[i]}/100',
                needDisplay: '>70/100',
                status: _statusFor(sq[i]),
              ),
          ],
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _soilLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  bool get _isSoil => _tab == ProfileTab.soil;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _AnalysisHeader(
              analysis: _analysis,
              tab: _tab,
              onTabChanged: (t) => setState(() => _tab = t),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            sliver: SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _isSoil
                    ? _ProfileBody(
                        key: const ValueKey('soil'),
                        analysis: _analysis,
                        isSoil: true,
                        params: _analysis.soilParams,
                        soilLoading: _soilLoading,
                        onCalculate: () => Navigator.of(context).push(
                          FadeSlidePageRoute(
                            page: EconomicCalculatorScreen(
                              cropName: widget.cropName,
                            ),
                          ),
                        ),
                        growthText: _growthText,
                        plantDate: _plantDate,
                        harvestDate: _harvestDate,
                      )
                    : const _ClimateProfileTab(key: ValueKey('climate')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Body ────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final CropAnalysis analysis;
  final bool isSoil;
  final bool soilLoading;
  final List<AnalysisParameter> params;
  final VoidCallback onCalculate;
  final String growthText;
  final String plantDate;
  final String harvestDate;

  const _ProfileBody({
    super.key,
    required this.analysis,
    required this.isSoil,
    required this.soilLoading,
    required this.params,
    required this.onCalculate,
    required this.growthText,
    required this.plantDate,
    required this.harvestDate,
  });

  @override
  Widget build(BuildContext context) {
    final score = isSoil ? analysis.soilMatch : analysis.climateMatch;
    final topIssue =
        isSoil ? analysis.topSoilIssue : analysis.topClimateIssue;
    final topIssueDesc =
        isSoil ? analysis.topSoilIssueDesc : analysis.topClimateIssueDesc;
    final accent =
        isSoil ? AppColors.forestMid : const Color(0xFF1B6E8C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Match Score Card ──────────────────────────────────────────────
        _MatchScoreCard(
          score: score,
          isSoil: isSoil,
          topIssue: topIssue,
          topIssueDesc: topIssueDesc,
          growthText: growthText,
          plantDate: plantDate,
          harvestDate: harvestDate,
        ).animate().fadeIn(duration: 350.ms).slideY(
              begin: 0.04,
              end: 0,
              duration: 350.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 18),

        // ── Radar Chart + Comparison Table ───────────────────────────────
        if (isSoil && soilLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.forestMid,
                strokeWidth: 2.5,
              ),
            ),
          )
        else ...[
          RadarChartCard(
            title: isSoil
                ? 'Soil Compatibility Analysis'
                : 'Climate Compatibility Analysis',
            yourLabel: isSoil ? 'Your Soil' : 'Your Climate',
            axisLabels: params.map((p) => p.code).toList(),
            yourValues: params.map((p) => p.currentValue.toDouble()).toList(),
            needValues: params.map((p) => p.needValue.toDouble()).toList(),
          ).animate(delay: 80.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          _ComparisonTable(params: params, isSoil: isSoil, accent: accent)
              .animate(delay: 140.ms)
              .fadeIn(duration: 350.ms),
        ],

        // ── CTA Buttons (soil tab only) ───────────────────────────────────
        if (isSoil) ...[
          const SizedBox(height: 22),
          CustomButton(
            label: '💰 Calculate Profit',
            trailingIcon: Icons.trending_up_rounded,
            onPressed: onCalculate,
          ),
        ],

      ],
    );
  }
}

// ─── Match Score Card ────────────────────────────────────────────────────────

class _MatchScoreCard extends StatelessWidget {
  final int score;
  final bool isSoil;
  final String topIssue;
  final String topIssueDesc;
  final String growthText;
  final String plantDate;
  final String harvestDate;

  const _MatchScoreCard({
    required this.score,
    required this.isSoil,
    required this.topIssue,
    required this.topIssueDesc,
    required this.growthText,
    required this.plantDate,
    required this.harvestDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular score
              SizedBox(
                width: 100,
                child: CompatibilityCircle(
                  value: score,
                  label: isSoil ? 'Soil Match' : 'Climate Match',
                  size: 90,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSoil ? 'Soil Match Score' : 'Climate Match Score',
                      style: AppTextStyles.label.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    // Top issue badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 13,
                            color: AppColors.amber,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Top issue: $topIssue',
                              style: AppTextStyles.bodyS.copyWith(
                                color: AppColors.amber,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      topIssueDesc,
                      style: AppTextStyles.bodyS.copyWith(fontSize: 11),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.creamSoft, height: 1),
          const SizedBox(height: 12),
          // Growth info pills
          Row(
            children: [
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: 'Growth',
                value: growthText,
              ),
              const SizedBox(width: 8),
              _InfoPill(
                icon: Icons.spa_rounded,
                label: 'Plant',
                value: plantDate,
              ),
              const SizedBox(width: 8),
              _InfoPill(
                icon: Icons.agriculture_rounded,
                label: 'Harvest',
                value: harvestDate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.creamSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.forestMid),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.bodyS.copyWith(
                fontSize: 10,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.label.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Comparison Table ────────────────────────────────────────────────────────

class _ComparisonTable extends StatelessWidget {
  final List<AnalysisParameter> params;
  final bool isSoil;
  final Color accent;

  const _ComparisonTable({
    required this.params,
    required this.isSoil,
    required this.accent,
  });

  static IconData _iconFor(String code) {
    return switch (code) {
      'SQ1' => Icons.eco_rounded,
      'SQ2' => Icons.water_drop_rounded,
      'SQ3' => Icons.grass_rounded,
      'SQ4' => Icons.air_rounded,
      'SQ5' => Icons.science_rounded,
      'SQ6' => Icons.warning_amber_rounded,
      'CP1' => Icons.thermostat_rounded,
      'CP2' => Icons.water_rounded,
      'CP3' => Icons.cloud_rounded,
      'CP4' => Icons.wb_sunny_rounded,
      'CP5' => Icons.air_rounded,
      'CP6' => Icons.ac_unit_rounded,
      _ => Icons.analytics_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              isSoil
                  ? 'Your Soil vs Crop Requirements'
                  : 'Your Climate vs Crop Requirements',
              style: AppTextStyles.headingS.copyWith(fontSize: 14),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(
              children: [
                const SizedBox(width: 34),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Parameter',
                    style: AppTextStyles.bodyS.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      _legendDot(const Color(0xFF3B82F6)),
                      const SizedBox(width: 4),
                      Text(
                        'Crop Need',
                        style: AppTextStyles.bodyS.copyWith(fontSize: 9),
                      ),
                      const SizedBox(width: 10),
                      _legendDot(AppColors.forestMid),
                      const SizedBox(width: 4),
                      Text(
                        isSoil ? 'Your Soil' : 'Your Climate',
                        style: AppTextStyles.bodyS.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    'Status',
                    style: AppTextStyles.bodyS.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.creamSoft, height: 1),
          for (int i = 0; i < params.length; i++) ...[
            _ComparisonRow(
              param: params[i],
              icon: _iconFor(params[i].code),
              isSoil: isSoil,
            ),
            if (i != params.length - 1)
              Divider(
                color: AppColors.creamSoft,
                height: 1,
                indent: 14,
                endIndent: 14,
              ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  static Widget _legendDot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _ComparisonRow extends StatelessWidget {
  final AnalysisParameter param;
  final IconData icon;
  final bool isSoil;

  const _ComparisonRow({
    required this.param,
    required this.icon,
    required this.isSoil,
  });

  @override
  Widget build(BuildContext context) {
    final cropFrac = (param.needValue / 100).clamp(0.0, 1.0);
    final yourFrac = (param.currentValue / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: param.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: param.status.color),
          ),
          const SizedBox(width: 8),

          // Code + short name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  param.code,
                  style: AppTextStyles.bodyS.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: param.status.color,
                  ),
                ),
                Text(
                  param.name.length > 14
                      ? '${param.name.substring(0, 13)}…'
                      : param.name,
                  style: AppTextStyles.label.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Dual bars
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crop needs bar (blue)
                _MiniBar(
                  fraction: cropFrac,
                  value: param.needValue,
                  color: const Color(0xFF3B82F6),
                  label: 'Need',
                ),
                const SizedBox(height: 4),
                // Your value bar (status color)
                _MiniBar(
                  fraction: yourFrac,
                  value: param.currentValue,
                  color: param.status.color,
                  label: isSoil ? 'Soil' : 'Clim',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status chip
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            decoration: BoxDecoration(
              color: param.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: param.status.color.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              param.status.label,
              style: AppTextStyles.bodyS.copyWith(
                color: param.status.color,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double fraction;
  final int value;
  final Color color;
  final String label;

  const _MiniBar({
    required this.fraction,
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            label,
            style: AppTextStyles.bodyS.copyWith(fontSize: 9, color: color),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: AppColors.creamSoft),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: AppTextStyles.bodyS.copyWith(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _AnalysisHeader extends StatelessWidget {
  final CropAnalysis analysis;
  final ProfileTab tab;
  final ValueChanged<ProfileTab> onTabChanged;

  const _AnalysisHeader({
    required this.analysis,
    required this.tab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        20,
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
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(analysis.cropEmoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  analysis.cropName,
                  style: AppTextStyles.headingXL.copyWith(
                    fontSize: 28,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.place_outlined, color: Colors.white70, size: 13),
              const SizedBox(width: 4),
              Text(
                analysis.location,
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.cream.withValues(alpha: 0.80),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CROP ANALYSIS',
                  style: AppTextStyles.bodyS.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 9,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ProfileTabs(value: tab, onChanged: onTabChanged),
        ],
      ),
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  final ProfileTab value;
  final ValueChanged<ProfileTab> onChanged;
  const _ProfileTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabPill(
              label: 'Soil Profile',
              icon: Icons.terrain_rounded,
              active: value == ProfileTab.soil,
              onTap: () => onChanged(ProfileTab.soil),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabPill(
              label: 'Climate Profile',
              icon: Icons.cloud_rounded,
              active: value == ProfileTab.climate,
              onTap: () => onChanged(ProfileTab.climate),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      decoration: BoxDecoration(
        color: active ? AppColors.amber : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: active ? AppShadows.amberGlow : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLIMATE PROFILE TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _TodayClimate {
  final double currentTemp;
  final int weatherCode;
  final double windspeed;
  final double maxTemp;
  final double minTemp;
  final double avgHumidity;
  final double totalPrecip;
  final double avgSoilTemp;
  final List<double> hourlyTemps;

  const _TodayClimate({
    required this.currentTemp,
    required this.weatherCode,
    required this.windspeed,
    required this.maxTemp,
    required this.minTemp,
    required this.avgHumidity,
    required this.totalPrecip,
    required this.avgSoilTemp,
    required this.hourlyTemps,
  });

  String get farmingTip {
    if (currentTemp > 35) return '⚠️ Very hot today — water your crops early morning';
    if (totalPrecip > 5) return '💧 Rain expected today — no irrigation needed';
    if (avgHumidity > 80) return '🍄 High humidity — watch for fungal diseases';
    if (windspeed > 40) return '🌬️ Strong winds today — protect young plants';
    return '✅ Good farming conditions today';
  }
}

class _ClimateProfileTab extends StatefulWidget {
  const _ClimateProfileTab({super.key});

  @override
  State<_ClimateProfileTab> createState() => _ClimateProfileTabState();
}

class _ClimateProfileTabState extends State<_ClimateProfileTab> {
  bool _loading = true;
  String? _error;
  _TodayClimate? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final coords = await CoordHistory.load();
      final double lat;
      final double lon;
      if (coords.isNotEmpty) {
        lat = coords.first.lat;
        lon = coords.first.lon;
      } else {
        lat = 33.8;
        lon = 9.5;
      }

      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current_weather=true'
        '&hourly=temperature_2m,relativehumidity_2m,precipitation'
        ',windspeed_10m,soil_temperature_0cm,soil_moisture_0_1cm'
        '&forecast_days=1'
        '&timezone=Africa%2FTunis',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Weather API error ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;

      final cw = json['current_weather'] as Map<String, dynamic>;
      final h = json['hourly'] as Map<String, dynamic>;

      List<double> parseDoubles(List raw) =>
          raw.map((v) => (v as num?)?.toDouble() ?? 0.0).toList();

      final temps = parseDoubles(h['temperature_2m'] as List);
      final humidity = parseDoubles(h['relativehumidity_2m'] as List);
      final precip = parseDoubles(h['precipitation'] as List);
      final soilTemps = parseDoubles(h['soil_temperature_0cm'] as List);

      double listAvg(List<double> l) =>
          l.isEmpty ? 0.0 : l.reduce((a, b) => a + b) / l.length;

      final maxTemp = temps.isEmpty ? 0.0 : temps.reduce((a, b) => a > b ? a : b);
      final minTemp = temps.isEmpty ? 0.0 : temps.reduce((a, b) => a < b ? a : b);
      final avgHumidity = listAvg(humidity);
      final totalPrecip = precip.isEmpty ? 0.0 : precip.reduce((a, b) => a + b);
      final avgSoilTemp = listAvg(soilTemps);

      setState(() {
        _data = _TodayClimate(
          currentTemp: (cw['temperature'] as num).toDouble(),
          weatherCode: (cw['weathercode'] as num).toInt(),
          windspeed: (cw['windspeed'] as num).toDouble(),
          maxTemp: maxTemp,
          minTemp: minTemp,
          avgHumidity: avgHumidity,
          totalPrecip: totalPrecip,
          avgSoilTemp: avgSoilTemp,
          hourlyTemps: temps,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1B6E8C),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Text('🌩️', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: AppTextStyles.bodyS.copyWith(color: AppColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final d = _data!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TempGaugeCard(data: d)
            .animate()
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.04, end: 0, duration: 350.ms),
        const SizedBox(height: 16),
        _TodayStatsGrid(data: d)
            .animate(delay: 80.ms)
            .fadeIn(duration: 350.ms),
        const SizedBox(height: 16),
        _HourlyTempChart(temps: d.hourlyTemps)
            .animate(delay: 160.ms)
            .fadeIn(duration: 350.ms),
        const SizedBox(height: 16),
        _ClimateFarmingTip(tip: d.farmingTip)
            .animate(delay: 240.ms)
            .fadeIn(duration: 350.ms),
      ],
    );
  }
}

// ─── Hero gauge card ──────────────────────────────────────────────────────────

class _TempGaugeCard extends StatelessWidget {
  final _TodayClimate data;
  const _TempGaugeCard({required this.data});

  static String _icon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code == 45 || code == 48) return '🌫️';
    if ({51, 53, 55, 61, 63, 65}.contains(code)) return '🌧️';
    if ({71, 73, 75}.contains(code)) return '❄️';
    if ({80, 81, 82}.contains(code)) return '🌦️';
    if ({95, 96, 99}.contains(code)) return '⛈️';
    return '🌤️';
  }

  static String _label(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 3) return 'Partly Cloudy';
    if (code == 45 || code == 48) return 'Foggy';
    if (code == 51 || code == 53 || code == 55) return 'Drizzle';
    if (code == 61 || code == 63 || code == 65) return 'Rain';
    if (code == 71 || code == 73 || code == 75) return 'Snow';
    if (code == 80 || code == 81 || code == 82) return 'Showers';
    if (code == 95 || code == 96 || code == 99) return 'Thunderstorm';
    return 'Cloudy';
  }

  @override
  Widget build(BuildContext context) {
    final fraction = ((data.currentTemp + 10) / 60).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: CustomPaint(
              painter: _TempGaugePainter(fraction),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${data.currentTemp.toStringAsFixed(1)}°',
                      style: AppTextStyles.headingXL
                          .copyWith(fontSize: 26, height: 1),
                    ),
                    Text(
                      'Current',
                      style: AppTextStyles.bodyS.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_icon(data.weatherCode),
                    style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 6),
                Text(
                  _label(data.weatherCode),
                  style: AppTextStyles.headingS.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.air_rounded,
                        size: 13, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${data.windspeed.toStringAsFixed(0)} km/h',
                      style: AppTextStyles.bodyS.copyWith(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TempGaugePainter extends CustomPainter {
  final double fraction;
  const _TempGaugePainter(this.fraction);

  Color get _arcColor {
    if (fraction < 0.30) return const Color(0xFF64B5F6);
    if (fraction < 0.55) return const Color(0xFF81C784);
    if (fraction < 0.75) return const Color(0xFFFFB74D);
    return const Color(0xFFE57373);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = 135 * math.pi / 180.0;
    const sweepAngle = 270 * math.pi / 180.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * fraction,
        false,
        Paint()
          ..color = _arcColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TempGaugePainter old) => old.fraction != fraction;
}

// ─── Today's stats 2×3 grid ───────────────────────────────────────────────────

class _TodayStatsGrid extends StatelessWidget {
  final _TodayClimate data;
  const _TodayStatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Stats",
            style: AppTextStyles.headingS.copyWith(fontSize: 15)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: '🌡️',
                label: 'Max Temp',
                value: '${data.maxTemp.toStringAsFixed(1)}°C',
                bg: const Color(0xFFFFEBEE),
                fg: const Color(0xFFE53935),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                emoji: '🌡️',
                label: 'Min Temp',
                value: '${data.minTemp.toStringAsFixed(1)}°C',
                bg: const Color(0xFFE3F2FD),
                fg: const Color(0xFF1976D2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: '💧',
                label: 'Humidity',
                value: '${data.avgHumidity.toStringAsFixed(0)}%',
                bg: const Color(0xFFE0F2F1),
                fg: const Color(0xFF00897B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                emoji: '🌧️',
                label: 'Precipitation',
                value: '${data.totalPrecip.toStringAsFixed(1)} mm',
                bg: const Color(0xFFE8EAF6),
                fg: const Color(0xFF3949AB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: '💨',
                label: 'Wind Speed',
                value: '${data.windspeed.toStringAsFixed(0)} km/h',
                bg: const Color(0xFFF3F3F3),
                fg: const Color(0xFF546E7A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                emoji: '🌱',
                label: 'Soil Temp',
                value: '${data.avgSoilTemp.toStringAsFixed(1)}°C',
                bg: const Color(0xFFFFF3E0),
                fg: const Color(0xFF795548),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyS.copyWith(
                    fontSize: 10,
                    color: fg.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 13,
                    color: fg,
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

// ─── Hourly temperature mini-chart ────────────────────────────────────────────

class _HourlyTempChart extends StatelessWidget {
  final List<double> temps;
  const _HourlyTempChart({required this.temps});

  @override
  Widget build(BuildContext context) {
    if (temps.isEmpty) return const SizedBox.shrink();

    final spots = temps
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final rawMin = temps.reduce((a, b) => a < b ? a : b);
    final rawMax = temps.reduce((a, b) => a > b ? a : b);
    final range = rawMax - rawMin;
    final pad = range < 5 ? (5 - range) / 2 + 1 : 1.5;
    final yMin = (rawMin - pad).floorToDouble();
    final yMax = (rawMax + pad).ceilToDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.creamSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded,
                  size: 16, color: Color(0xFFE65100)),
              const SizedBox(width: 6),
              Text(
                "Today's Temperature by Hour",
                style: AppTextStyles.headingS.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 23,
                minY: yMin,
                maxY: yMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.inkMuted.withValues(alpha: 0.10),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}°',
                        style: AppTextStyles.bodyS.copyWith(
                          fontSize: 8,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      interval: 6,
                      getTitlesWidget: (v, _) {
                        final hr = v.toInt();
                        if (hr % 6 != 0) return const SizedBox();
                        return Text(
                          '${hr}h',
                          style: AppTextStyles.bodyS.copyWith(
                            fontSize: 8,
                            color: AppColors.inkMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFE65100),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFE65100).withValues(alpha: 0.08),
                    ),
                  ),
                ],
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Farming tip card ─────────────────────────────────────────────────────────

class _ClimateFarmingTip extends StatelessWidget {
  final String tip;
  const _ClimateFarmingTip({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.forestMid.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.forestMid.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.forestMid.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                size: 20, color: AppColors.forestMid),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Farming Tip',
                  style: AppTextStyles.headingS.copyWith(
                    fontSize: 13,
                    color: AppColors.forestMid,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: AppTextStyles.bodyM.copyWith(
                    fontSize: 13,
                    color: AppColors.ink,
                    height: 1.5,
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
