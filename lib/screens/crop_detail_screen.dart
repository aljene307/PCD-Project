import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../data/crop_catalog.dart';
import '../widgets/compatibility_circle.dart';
import '../widgets/custom_button.dart';
import '../widgets/section_card.dart';
import '../utils/page_transitions.dart';
import 'soil_profile_screen.dart';

class CropDetailScreen extends StatelessWidget {
  final CropInfo crop;
  final int? rank;

  const CropDetailScreen({super.key, required this.crop, this.rank});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero ────────────────────────────────────────────────
            _Hero(crop: crop, rank: rank),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Climate & Temperature Card ─────────────
                  _ClimateCard(crop: crop)
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(
                        begin: 0.04,
                        end: 0,
                        duration: 350.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 12),
                  // ── Soil Requirements Card ─────────────────
                  _SoilRequirementsCard(crop: crop)
                      .animate(delay: 80.ms)
                      .fadeIn(duration: 350.ms),
                  const SizedBox(height: 12),
                  // ── Growing Info Card (4 tiles) ────────────
                  _GrowingInfoCard(crop: crop)
                      .animate(delay: 160.ms)
                      .fadeIn(duration: 350.ms),
                  const SizedBox(height: 12),
                  // ── Yield & Profit Card ────────────────────
                  _YieldProfitCard(crop: crop)
                      .animate(delay: 240.ms)
                      .fadeIn(duration: 350.ms),
                  const SizedBox(height: 12),
                  // ── Regional Info Card ─────────────────────
                  _RegionalInfoCard(crop: crop)
                      .animate(delay: 320.ms)
                      .fadeIn(duration: 350.ms),
                  const SizedBox(height: 12),
                  // ── About this crop ────────────────────────
                  SectionCard(
                    title: 'About this crop',
                    icon: Icons.info_outline_rounded,
                    accent: AppColors.forestMid,
                    // TODO: Replace with backend data
                    child: Text(crop.overview, style: AppTextStyles.bodyM),
                  ).animate(delay: 400.ms).fadeIn(duration: 350.ms),
                  const SizedBox(height: 12),
                  // ── Growing Tips ───────────────────────────
                  SectionCard(
                    title: 'Growing Tips',
                    icon: Icons.spa_rounded,
                    accent: AppColors.forestLight,
                    // TODO: Replace with backend data
                    child: BulletList(
                      items: const [
                        'Plant in early morning or late afternoon to reduce transplant shock.',
                        'Keep soil consistently moist during germination and flowering phases.',
                        'Apply balanced fertilizer every 3 weeks during peak growth.',
                      ],
                    ),
                  ).animate(delay: 480.ms).fadeIn(duration: 350.ms),
                  const SizedBox(height: 12),
                  // ── Common Diseases ────────────────────────
                  SectionCard(
                    title: 'Common Diseases',
                    icon: Icons.bug_report_rounded,
                    accent: AppColors.error,
                    // TODO: Replace with backend data
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _DiseaseRow(
                          name: 'Powdery Mildew',
                          desc: 'White fungal coating on leaves',
                        ),
                        SizedBox(height: 10),
                        _DiseaseRow(
                          name: 'Root Rot',
                          desc: 'Caused by overwatering and poor drainage',
                        ),
                        SizedBox(height: 10),
                        _DiseaseRow(
                          name: 'Aphid Infestation',
                          desc: 'Small insects clustering on new growth',
                        ),
                      ],
                    ),
                  ).animate(delay: 560.ms).fadeIn(duration: 350.ms),
                  const SizedBox(height: 22),
                  // ── Bottom buttons ─────────────────────────
                  CustomButton(
                    label: 'Check Soil Compatibility',
                    trailingIcon: Icons.terrain_rounded,
                    onPressed: () => Navigator.of(context).push(
                      FadeSlidePageRoute(
                        page: SoilProfileScreen(
                          cropName: crop.name,
                          cropCode: crop.name,
                          cropEmoji: crop.emoji,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _OutlinedGreenButton(
                    label: 'View Climate Profile',
                    icon: Icons.cloud_rounded,
                    color: const Color(0xFF1B6E8C),
                    onPressed: () => Navigator.of(context).push(
                      FadeSlidePageRoute(
                        page: SoilProfileScreen(
                          cropName: crop.name,
                          cropCode: crop.name,
                          cropEmoji: crop.emoji,
                          initialTab: ProfileTab.climate,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _OutlinedGreenButton(
                    label: 'Add to My Plan',
                    icon: Icons.bookmark_add_rounded,
                    color: AppColors.forestMid,
                    onPressed: () {
                      // TODO: Connect to backend — persist to user's plan.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.forestMid,
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            '${crop.name} added to your plan',
                            style: AppTextStyles.bodyM.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero (280px) ──────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final CropInfo crop;
  final int? rank;
  const _Hero({required this.crop, this.rank});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(gradient: crop.category.gradient),
          ),
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Large crop emoji (90px) with subtle drop shadow
          Center(
            child: Hero(
              tag: 'crop-${crop.name}',
              flightShuttleBuilder: (_, __, ___, ____, _____) => Material(
                type: MaterialType.transparency,
                child: Text(
                  crop.emoji,
                  style: const TextStyle(fontSize: 120),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  crop.emoji,
                  style: const TextStyle(fontSize: 120),
                ),
              ),
            ),
          ),
          // Gradient scrim — bottom 40% fades to black for text legibility
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 130,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
          // Top-left back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.28),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Bottom: name + category pill
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          crop.category.label.toUpperCase(),
                          style: AppTextStyles.bodyS.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        crop.name,
                        style: AppTextStyles.headingXL.copyWith(fontSize: 30),
                      ),
                      Text(
                        crop.latin,
                        style: AppTextStyles.bodyS.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (rank != null)
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.amberGlow,
                    ),
                    child: Text(
                      '#$rank',
                      style: AppTextStyles.headingS.copyWith(
                        color: Colors.white,
                        fontSize: 16,
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

// ─── Climate & Temperature Card ────────────────────────────────────────────

class _ClimateCard extends StatelessWidget {
  final CropInfo crop;
  const _ClimateCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with backend data
    final optimal = ((crop.tempMin + crop.tempMax) / 2).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.thermostat_rounded,
                  size: 19,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Climate & Temperature',
                style: AppTextStyles.headingS.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Min / Optimal / Max temp range bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TempLabel(
                label: 'Min',
                value: '${crop.tempMin}°C',
                color: const Color(0xFF3A86FF),
              ),
              _TempLabel(
                label: 'Optimal',
                value: '$optimal°C',
                color: AppColors.success,
                emphasized: true,
              ),
              _TempLabel(
                label: 'Max',
                value: '${crop.tempMax}°C',
                color: AppColors.terracotta,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 12,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF3A86FF),
                    Color(0xFF52B788),
                    Color(0xFFE76F51),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Annual rainfall water-drop gauge
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3A86FF), Color(0xFF1B6E8C)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Annual Rainfall Need',
                      style: AppTextStyles.bodyS.copyWith(
                        fontSize: 11,
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      // TODO: Replace with backend data
                      _rainfallFor(crop.waterNeed),
                      style: AppTextStyles.label.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B6E8C).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  crop.waterNeed,
                  style: AppTextStyles.bodyS.copyWith(
                    color: const Color(0xFF1B6E8C),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _rainfallFor(String need) {
    switch (need) {
      case 'High':
        return '900 — 1200 mm/year';
      case 'Low':
        return '200 — 400 mm/year';
      default:
        return '400 — 700 mm/year';
    }
  }
}

class _TempLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool emphasized;

  const _TempLabel({
    required this.label,
    required this.value,
    required this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.label.copyWith(
            color: color,
            fontSize: emphasized ? 16 : 13,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodyS.copyWith(
            fontSize: 10,
            color: AppColors.inkMuted,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

// ─── Soil Requirements Card ────────────────────────────────────────────────

class _SoilRequirementsCard extends StatelessWidget {
  final CropInfo crop;
  const _SoilRequirementsCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.forestMid.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.terrain_rounded,
                  size: 19,
                  color: AppColors.forestMid,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Soil Requirements',
                style: AppTextStyles.headingS.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // pH scale (acidic → neutral → alkaline)
          Text(
            'pH Range',
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          _PhScale(min: crop.phMin, max: crop.phMax),
          const SizedBox(height: 18),
          // Soil type chips
          Text(
            'Preferred Soil Type',
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          // TODO: Replace with backend data
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              _SoilChip(label: 'Loam'),
              _SoilChip(label: 'Sandy Loam'),
              _SoilChip(label: 'Clay Loam'),
            ],
          ),
          const SizedBox(height: 18),
          // Drainage indicator
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B6E8C).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.water_damage_rounded,
                  color: Color(0xFF1B6E8C),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Drainage Requirement',
                      style: AppTextStyles.bodyS.copyWith(
                        fontSize: 11,
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      // TODO: Replace with backend data
                      'Well-drained, no waterlogging',
                      style: AppTextStyles.label.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhScale extends StatelessWidget {
  final double min;
  final double max;
  const _PhScale({required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final startFrac = (min / 14).clamp(0.0, 1.0);
        final endFrac = (max / 14).clamp(0.0, 1.0);
        return SizedBox(
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Faded full gradient
              Container(
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE76F51).withValues(alpha: 0.40),
                      const Color(0xFFF4A261).withValues(alpha: 0.40),
                      const Color(0xFF52B788).withValues(alpha: 0.40),
                      const Color(0xFF3A86FF).withValues(alpha: 0.40),
                      const Color(0xFF8338EC).withValues(alpha: 0.40),
                    ],
                  ),
                ),
              ),
              // Highlighted optimal range
              Positioned(
                left: startFrac * w,
                width: (endFrac - startFrac) * w,
                top: -2,
                bottom: 46,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF4A261),
                        Color(0xFF52B788),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              // Tooltip
              Positioned(
                top: 22,
                left: ((startFrac + endFrac) / 2 * w) - 50,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${min.toStringAsFixed(1)} – ${max.toStringAsFixed(1)} pH',
                    style: AppTextStyles.bodyS.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _scaleLabel('Acidic'),
                    _scaleLabel('Neutral'),
                    _scaleLabel('Alkaline'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scaleLabel(String t) => Text(
        t,
        style: AppTextStyles.bodyS.copyWith(
          fontSize: 10,
          color: AppColors.inkMuted,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _SoilChip extends StatelessWidget {
  final String label;
  const _SoilChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.forestMid.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.forestMid.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyS.copyWith(
          color: AppColors.forestDark,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─── Growing Info Card (4-tile grid) ───────────────────────────────────────

class _GrowingInfoCard extends StatelessWidget {
  final CropInfo crop;
  const _GrowingInfoCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.forestLight.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  size: 19,
                  color: AppColors.forestMid,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Growing Info',
                style: AppTextStyles.headingS.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _InfoTile(
                icon: Icons.timer_rounded,
                value: '${crop.growthDays} days',
                label: 'Growth Period',
              ),
              _InfoTile(
                icon: Icons.eco_rounded,
                // TODO: Replace with backend data
                value: 'Spring',
                label: 'Planting Season',
              ),
              _InfoTile(
                icon: Icons.agriculture_rounded,
                // TODO: Replace with backend data
                value: 'Summer',
                label: 'Harvest Season',
              ),
              _InfoTile(
                icon: Icons.bar_chart_rounded,
                value: crop.difficulty,
                label: 'Difficulty',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: AppColors.forestMid),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTextStyles.headingS.copyWith(fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: AppTextStyles.bodyS.copyWith(
                  fontSize: 11,
                  color: AppColors.inkMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Yield & Profit Card ───────────────────────────────────────────────────

class _YieldProfitCard extends StatelessWidget {
  final CropInfo crop;
  const _YieldProfitCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  size: 19,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Yield & Profit',
                style: AppTextStyles.headingS.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _YieldStat(
                  emoji: '🌾',
                  // TODO: Replace with backend data
                  value: '4.2 t/ha',
                  label: 'Potential Yield',
                  color: AppColors.forestMid,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _YieldStat(
                  emoji: '💰',
                  // TODO: Replace with backend data
                  value: '\$1,240/ha',
                  label: 'Potential Profit',
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Suitability circle prominently
          Row(
            children: [
              const SizedBox(
                width: 110,
                child: CompatibilityCircle(
                  // TODO: Replace with backend data
                  value: 92,
                  label: 'Suitability',
                  size: 100,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Excellent fit',
                      style: AppTextStyles.headingS.copyWith(
                        color: AppColors.success,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // TODO: Replace with backend data
                      'Your soil and climate align very well with this crop\'s needs.',
                      style: AppTextStyles.bodyS.copyWith(fontSize: 12),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YieldStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _YieldStat({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headingS.copyWith(
              fontSize: 16,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Regional Info Card ────────────────────────────────────────────────────

class _RegionalInfoCard extends StatelessWidget {
  final CropInfo crop;
  const _RegionalInfoCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with backend data
    const companions = ['🌽', '🥕', '🫘', '🌿'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  size: 19,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Regional Info',
                style: AppTextStyles.headingS.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // "Common in your region" badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  // TODO: Replace with backend data
                  'Common in your region',
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Typical Growing Regions',
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: crop.bestRegions
                .map((r) => _RegionChip(label: r))
                .toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Best Companion Crops',
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: companions
                .map(
                  (e) => Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  final String label;
  const _RegionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyS.copyWith(
          color: AppColors.terracotta,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─── Disease Row ───────────────────────────────────────────────────────────

class _DiseaseRow extends StatelessWidget {
  final String name;
  final String desc;
  const _DiseaseRow({required this.name, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            size: 17,
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: AppTextStyles.label.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTextStyles.bodyS.copyWith(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Outlined green button ─────────────────────────────────────────────────

class _OutlinedGreenButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _OutlinedGreenButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.forestMid,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19, color: color),
        label: Text(
          label,
          style: AppTextStyles.button.copyWith(color: color),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
