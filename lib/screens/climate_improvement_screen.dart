import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/compatibility_circle.dart';

/// Climate Improvement Plan — same structure as Soil Improvement but
/// focused on climate-adaptation recommendations.
class ClimateImprovementScreen extends StatelessWidget {
  final String cropName;
  final String location;

  const ClimateImprovementScreen({
    super.key,
    required this.cropName,
    required this.location,
  });

  // TODO: Replace all placeholder data with backend response
  static const _actions = [
    _CliActionData(
      priority: _CliPriority.high,
      title: 'Frost Protection',
      description:
          'Install row covers or use windbreaks to protect ${'crops'} from frost events during sensitive growth stages.',
      yieldBoost: 14,
      cost: 'Medium',
      timeframe: '1–2 days',
      icon: Icons.ac_unit_rounded,
    ),
    _CliActionData(
      priority: _CliPriority.high,
      title: 'Irrigation System',
      description:
          'Implement drip or sprinkler irrigation to compensate for rainfall deficit of ~80mm during growing season.',
      yieldBoost: 18,
      cost: 'High',
      timeframe: '2–4 weeks',
      icon: Icons.water_rounded,
    ),
    _CliActionData(
      priority: _CliPriority.medium,
      title: 'Wind Shelter',
      description:
          'Plant windbreak hedges or install temporary windbreaks to reduce wind stress on crops.',
      yieldBoost: 7,
      cost: 'Low',
      timeframe: '1 week',
      icon: Icons.air_rounded,
    ),
    _CliActionData(
      priority: _CliPriority.medium,
      title: 'Shade Management',
      description:
          'Use shade nets during peak heat months to reduce heat stress and maintain optimal temperature.',
      yieldBoost: 9,
      cost: 'Medium',
      timeframe: '3–5 days',
      icon: Icons.wb_shade_rounded,
    ),
    _CliActionData(
      priority: _CliPriority.low,
      title: 'Mulching',
      description:
          'Apply organic mulch to conserve soil moisture and moderate soil temperature during dry periods.',
      yieldBoost: 6,
      cost: 'Low',
      timeframe: 'Immediate',
      icon: Icons.layers_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _CliHeader(),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Assessment Card ─────────────────────────────────────
                _CliAssessmentCard(cropName: cropName, location: location)
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(
                      begin: 0.04,
                      end: 0,
                      duration: 350.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 22),

                // ── Actions ─────────────────────────────────────────────
                _CliSectionLabel(
                  label: 'CLIMATE ADAPTATION ACTIONS',
                  subtitle: 'Ordered by priority',
                ),
                const SizedBox(height: 12),

                for (int i = 0; i < _actions.length; i++) ...[
                  _CliActionCard(action: _actions[i])
                      .animate(delay: (80 + i * 60).ms)
                      .fadeIn(duration: 320.ms)
                      .slideX(
                        begin: 0.04,
                        end: 0,
                        duration: 320.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  if (i != _actions.length - 1) const SizedBox(height: 10),
                ],

                const SizedBox(height: 22),

                // ── Timeline ────────────────────────────────────────────
                _CliSectionLabel(label: 'IMPLEMENTATION TIMELINE'),
                const SizedBox(height: 12),
                _CliTimelineCard(actions: _actions)
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 350.ms),

                const SizedBox(height: 22),

                // ── Expected Outcome ────────────────────────────────────
                _CliSectionLabel(label: 'EXPECTED OUTCOME'),
                const SizedBox(height: 12),
                _CliOutcomeCard()
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 350.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _CliHeader extends StatelessWidget {
  const _CliHeader();

  static const _climateGrad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A2C3D), Color(0xFF0F3D54), Color(0xFF1B6E8C)],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: _climateGrad,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.cloud_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Climate Improvement Plan',
                      style: AppTextStyles.headingL.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Recommendations for your farm',
                      style: AppTextStyles.bodyM.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
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

// ─── Assessment Card ──────────────────────────────────────────────────────────

class _CliAssessmentCard extends StatelessWidget {
  final String cropName;
  final String location;
  const _CliAssessmentCard({required this.cropName, required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: CompatibilityCircle(
              value: 68,
              // TODO: Replace with backend data
              label: 'Climate Match',
              size: 88,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Assessment',
                  style: AppTextStyles.label.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your climate has moderate suitability. Managing frost risk and rainfall deficit will significantly improve $cropName performance.',
                  // TODO: Replace with backend data
                  style: AppTextStyles.bodyS.copyWith(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      size: 12,
                      color: AppColors.inkMuted,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        location,
                        style: AppTextStyles.bodyS.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

// ─── Shared widgets (climate-themed) ─────────────────────────────────────────

class _CliSectionLabel extends StatelessWidget {
  final String label;
  final String? subtitle;
  const _CliSectionLabel({required this.label, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyS.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            fontSize: 11,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppTextStyles.bodyS.copyWith(fontSize: 11)),
        ],
      ],
    );
  }
}

// ─── Action data model ────────────────────────────────────────────────────────

enum _CliPriority { high, medium, low }

class _CliActionData {
  final _CliPriority priority;
  final String title;
  final String description;
  final int yieldBoost;
  final String cost;
  final String timeframe;
  final IconData icon;

  const _CliActionData({
    required this.priority,
    required this.title,
    required this.description,
    required this.yieldBoost,
    required this.cost,
    required this.timeframe,
    required this.icon,
  });
}

// ─── Action Card ──────────────────────────────────────────────────────────────

class _CliActionCard extends StatelessWidget {
  final _CliActionData action;
  const _CliActionCard({required this.action});

  Color get _priorityColor => switch (action.priority) {
        _CliPriority.high => AppColors.error,
        _CliPriority.medium => AppColors.amber,
        _CliPriority.low => AppColors.success,
      };

  String get _priorityLabel => switch (action.priority) {
        _CliPriority.high => 'High',
        _CliPriority.medium => 'Medium',
        _CliPriority.low => 'Low',
      };

  String get _priorityEmoji => switch (action.priority) {
        _CliPriority.high => '🔴',
        _CliPriority.medium => '🟡',
        _CliPriority.low => '🟢',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
        border: Border.all(color: _priorityColor.withValues(alpha: 0.20)),
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
                  color: _priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, size: 18, color: _priorityColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.title,
                  style: AppTextStyles.headingS.copyWith(fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _priorityColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '$_priorityEmoji $_priorityLabel',
                  style: AppTextStyles.bodyS.copyWith(
                    color: _priorityColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            action.description,
            style: AppTextStyles.bodyM.copyWith(
              fontSize: 13,
              color: AppColors.inkMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _CliMetaChip(
                icon: Icons.trending_up_rounded,
                text: '+${action.yieldBoost}% yield',
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _CliMetaChip(
                icon: Icons.attach_money_rounded,
                text: '${action.cost} cost',
                color: AppColors.inkMuted,
              ),
              const SizedBox(width: 8),
              _CliMetaChip(
                icon: Icons.schedule_rounded,
                text: action.timeframe,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CliMetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _CliMetaChip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.creamSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline ─────────────────────────────────────────────────────────────────

class _CliTimelineCard extends StatelessWidget {
  final List<_CliActionData> actions;
  const _CliTimelineCard({required this.actions});

  static int _weekOffset(_CliActionData a) => switch (a.priority) {
        _CliPriority.high => 0,
        _CliPriority.medium => 2,
        _CliPriority.low => 5,
      };

  static int _weekDuration(_CliActionData a) => switch (a.priority) {
        _CliPriority.high => 4,
        _CliPriority.medium => 3,
        _CliPriority.low => 2,
      };

  static Color _color(_CliActionData a) => switch (a.priority) {
        _CliPriority.high => AppColors.error,
        _CliPriority.medium => AppColors.amber,
        _CliPriority.low => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    const weeks = 8;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 100),
              ...List.generate(
                weeks,
                (i) => Expanded(
                  child: Text(
                    'W${i + 1}',
                    style: AppTextStyles.bodyS.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.creamSoft, height: 1),
          const SizedBox(height: 8),
          for (final action in actions) ...[
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    action.title,
                    style: AppTextStyles.bodyS.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final cellW = constraints.maxWidth / weeks;
                      final start = _weekOffset(action);
                      final dur = _weekDuration(action);
                      final clampedDur =
                          (start + dur > weeks ? weeks - start : dur)
                              .clamp(1, weeks);
                      return Stack(
                        children: [
                          Container(height: 22, color: Colors.transparent),
                          Positioned(
                            left: start * cellW,
                            width: clampedDur * cellW,
                            top: 0,
                            height: 22,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _color(action).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                action.title.split(' ').first,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 100),
              _CliLegendDot(color: AppColors.error, label: 'High'),
              const SizedBox(width: 12),
              _CliLegendDot(color: AppColors.amber, label: 'Medium'),
              const SizedBox(width: 12),
              _CliLegendDot(color: AppColors.success, label: 'Low'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CliLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _CliLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodyS.copyWith(fontSize: 10)),
      ],
    );
  }
}

// ─── Outcome Card ─────────────────────────────────────────────────────────────

class _CliOutcomeCard extends StatelessWidget {
  const _CliOutcomeCard();

  static const _climateAccent = Color(0xFF1B6E8C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _climateAccent.withValues(alpha: 0.06),
            _climateAccent.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _climateAccent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Projected Outcome',
            style: AppTextStyles.headingS.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 3),
          Text(
            '// TODO: Replace with backend response',
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 10,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CliBAT(label: 'Before', score: 68, color: AppColors.amber),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: _climateAccent,
                      size: 22,
                    ),
                    Text(
                      '+19%',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.success,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _CliBAT(label: 'After', score: 87, color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Implementing climate adaptations could improve your climate match from 68% to ~87% and increase crop resilience significantly.',
                    // TODO: Replace with backend data
                    style: AppTextStyles.bodyS.copyWith(
                      fontSize: 12,
                      color: AppColors.forestDark,
                      height: 1.5,
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

class _CliBAT extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const _CliBAT({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score%',
            style: AppTextStyles.headingM.copyWith(fontSize: 26, color: color),
          ),
          const SizedBox(height: 2),
          Text('Match', style: AppTextStyles.bodyS.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
