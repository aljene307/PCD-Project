import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/compatibility_circle.dart';

class SoilImprovementScreen extends StatelessWidget {
  final String cropName;
  final String location;

  const SoilImprovementScreen({
    super.key,
    required this.cropName,
    required this.location,
  });

  // TODO: Replace all placeholder data with backend response
  static const _actions = [
    _ActionData(
      priority: _Priority.high,
      title: 'Improve Drainage',
      description:
          'Install drainage channels to reduce waterlogging and improve oxygen availability.',
      yieldBoost: 15,
      cost: 'Medium',
      timeframe: '4–6 weeks',
      icon: Icons.water_drop_outlined,
    ),
    _ActionData(
      priority: _Priority.medium,
      title: 'Add Organic Matter',
      description:
          'Apply compost or manure to improve nutrient retention capacity and soil structure.',
      yieldBoost: 10,
      cost: 'Low',
      timeframe: '2–4 weeks',
      icon: Icons.eco_rounded,
    ),
    _ActionData(
      priority: _Priority.medium,
      title: 'pH Correction',
      description:
          'Apply agricultural lime to raise pH to the optimal range for nutrient uptake.',
      yieldBoost: 8,
      cost: 'Low',
      timeframe: '1–2 weeks',
      icon: Icons.science_rounded,
    ),
    _ActionData(
      priority: _Priority.low,
      title: 'Deep Tillage',
      description:
          'Break the hardpan layer to improve rooting depth and water infiltration.',
      yieldBoost: 12,
      cost: 'High',
      timeframe: '1 day',
      icon: Icons.agriculture_rounded,
    ),
    _ActionData(
      priority: _Priority.low,
      title: 'Potassium Amendment',
      description:
          'Apply potash fertilizer to bring potassium to the optimal level for the crop.',
      yieldBoost: 6,
      cost: 'Medium',
      timeframe: 'Immediate',
      icon: Icons.bolt_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ImprovementHeader(
              title: 'Soil Improvement Plan',
              subtitle: 'Recommendations for your farm',
              icon: Icons.terrain_rounded,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Assessment Card ─────────────────────────────────────
                _AssessmentCard(cropName: cropName, location: location)
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(
                      begin: 0.04,
                      end: 0,
                      duration: 350.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 22),

                // ── Actions section ─────────────────────────────────────
                _SectionLabel(
                  label: 'IMPROVEMENT ACTIONS',
                  subtitle: 'Ordered by priority',
                ),
                const SizedBox(height: 12),

                for (int i = 0; i < _actions.length; i++) ...[
                  _ActionCard(action: _actions[i])
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
                _SectionLabel(label: 'IMPLEMENTATION TIMELINE'),
                const SizedBox(height: 12),
                _TimelineCard(actions: _actions)
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 350.ms),

                const SizedBox(height: 22),

                // ── Expected Outcome ────────────────────────────────────
                _SectionLabel(label: 'EXPECTED OUTCOME'),
                const SizedBox(height: 12),
                _OutcomeCard()
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

// ─── Climate Improvement Screen ───────────────────────────────────────────────
// (Shares the same design — different title + actions.)
// See climate_improvement_screen.dart for the actual class.

// ─── Shared Header ───────────────────────────────────────────────────────────

class _ImprovementHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ImprovementHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

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
        gradient: AppGradients.forestRich,
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
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headingL.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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

class _AssessmentCard extends StatelessWidget {
  final String cropName;
  final String location;

  const _AssessmentCard({required this.cropName, required this.location});

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
              value: 74,
              // TODO: Replace with backend data
              label: 'Soil Health',
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
                  'Your soil has moderate health. Key improvements to drainage and nutrient retention will significantly boost $cropName yield.',
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

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? subtitle;
  const _SectionLabel({required this.label, this.subtitle});

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
          Text(
            subtitle!,
            style: AppTextStyles.bodyS.copyWith(fontSize: 11),
          ),
        ],
      ],
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────────────────────

enum _Priority { high, medium, low }

class _ActionData {
  final _Priority priority;
  final String title;
  final String description;
  final int yieldBoost;
  final String cost;
  final String timeframe;
  final IconData icon;

  const _ActionData({
    required this.priority,
    required this.title,
    required this.description,
    required this.yieldBoost,
    required this.cost,
    required this.timeframe,
    required this.icon,
  });
}

class _ActionCard extends StatelessWidget {
  final _ActionData action;
  const _ActionCard({required this.action});

  Color get _priorityColor => switch (action.priority) {
        _Priority.high => AppColors.error,
        _Priority.medium => AppColors.amber,
        _Priority.low => AppColors.success,
      };

  String get _priorityLabel => switch (action.priority) {
        _Priority.high => 'High',
        _Priority.medium => 'Medium',
        _Priority.low => 'Low',
      };

  String get _priorityEmoji => switch (action.priority) {
        _Priority.high => '🔴',
        _Priority.medium => '🟡',
        _Priority.low => '🟢',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: _priorityColor.withValues(alpha: 0.20),
        ),
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
              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _priorityColor.withValues(alpha: 0.35),
                  ),
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
          // Meta row
          Row(
            children: [
              _MetaChip(
                icon: Icons.trending_up_rounded,
                text: '+${action.yieldBoost}% yield',
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _MetaChip(
                icon: Icons.attach_money_rounded,
                text: '${action.cost} cost',
                color: AppColors.inkMuted,
              ),
              const SizedBox(width: 8),
              _MetaChip(
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MetaChip({required this.icon, required this.text, required this.color});

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

// ─── Timeline Card ────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final List<_ActionData> actions;
  const _TimelineCard({required this.actions});

  // Relative month offsets for each priority
  static int _weekOffset(_ActionData a) => switch (a.priority) {
        _Priority.high => 0,
        _Priority.medium => 2,
        _Priority.low => 4,
      };

  static int _weekDuration(_ActionData a) => switch (a.priority) {
        _Priority.high => 6,
        _Priority.medium => 4,
        _Priority.low => 2,
      };

  static Color _color(_ActionData a) => switch (a.priority) {
        _Priority.high => AppColors.error,
        _Priority.medium => AppColors.amber,
        _Priority.low => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    const weeks = 10;
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
          // Week header
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
          // Legend
          Row(
            children: [
              const SizedBox(width: 100),
              _LegendDot(color: AppColors.error, label: 'High'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.amber, label: 'Medium'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.success, label: 'Low'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

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
        Text(
          label,
          style: AppTextStyles.bodyS.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

// ─── Outcome Card ─────────────────────────────────────────────────────────────

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.forestDark.withValues(alpha: 0.06),
            AppColors.forestMid.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.forestMid.withValues(alpha: 0.20),
        ),
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
                child: _BeforeAfterTile(
                  label: 'Before',
                  score: 74,
                  color: AppColors.amber,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.forestMid,
                      size: 22,
                    ),
                    Text(
                      '+17%',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.success,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _BeforeAfterTile(
                  label: 'After',
                  score: 91,
                  color: AppColors.success,
                ),
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
                    'Implementing all actions could improve your soil match from 74% to ~91% and boost yield by up to 35%.',
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

class _BeforeAfterTile extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _BeforeAfterTile({
    required this.label,
    required this.score,
    required this.color,
  });

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
            style: AppTextStyles.headingM.copyWith(
              fontSize: 26,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Match',
            style: AppTextStyles.bodyS.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
