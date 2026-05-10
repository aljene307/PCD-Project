import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/app_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/crop_card.dart';
import '../utils/page_transitions.dart';
import 'chatbot_screen.dart';
import 'crops_browser_screen.dart';
import 'my_climate_screen.dart';
import 'my_soil_screen.dart';
import 'soil_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Emoji helper
// ─────────────────────────────────────────────────────────────────────────────

String _cropEmoji(String name) {
  final n = name.toLowerCase();
  if (n.contains('wheat')) return '🌾';
  if (n.contains('barley')) return '🌾';
  if (n.contains('corn') || n.contains('maize')) return '🌽';
  if (n.contains('tomato')) return '🍅';
  if (n.contains('potato')) return '🥔';
  if (n.contains('onion')) return '🧅';
  if (n.contains('carrot')) return '🥕';
  if (n.contains('cabbage')) return '🥬';
  if (n.contains('olive')) return '🫒';
  if (n.contains('grape') || n.contains('vine')) return '🍇';
  if (n.contains('orange') || n.contains('citrus')) return '🍊';
  if (n.contains('lemon')) return '🍋';
  if (n.contains('apple')) return '🍎';
  if (n.contains('soy') || n.contains('bean')) return '🫘';
  if (n.contains('sunflower')) return '🌻';
  if (n.contains('pepper')) return '🫑';
  if (n.contains('garlic')) return '🧄';
  if (n.contains('date')) return '🌴';
  if (n.contains('fig')) return '🌿';
  return '🌿';
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class RanksScreen extends StatefulWidget {
  final List<CropRecommendation> crops;
  const RanksScreen({super.key, required this.crops});

  @override
  State<RanksScreen> createState() => _RanksScreenState();
}

class _RanksScreenState extends State<RanksScreen> {
  SortMetric _globalSort = SortMetric.suitability;
  int _visibleCount = 5;

  int get _navIndex => AppSession.currentTabIndex;
  set _navIndex(int v) => AppSession.currentTabIndex = v;

  List<CropRecommendation> _sorted() {
    final list = [...widget.crops];
    list.sort((a, b) => switch (_globalSort) {
      SortMetric.suitability => b.suitabilityIndexPercentage
          .compareTo(a.suitabilityIndexPercentage),
      SortMetric.yield_ =>
        (b.actualYield ?? 0).compareTo(a.actualYield ?? 0),
      SortMetric.regionalGrowth =>
        b.regionalSharePercentage.compareTo(a.regionalSharePercentage),
    });
    return list;
  }

  Widget _buildHomeTab() {
    final sorted = _sorted();

    debugPrint('[RanksScreen] total crops received: ${widget.crops.length}, after sort: ${sorted.length}');

    if (sorted.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _RanksHeader(
              sort: _globalSort,
              onSortChanged: (m) => setState(() {
                _globalSort = m;
                _visibleCount = 5;
              }),
            ),
          ),
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grass_rounded,
                      size: 56,
                      color: AppColors.forestLight.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recommendations found',
                      style: AppTextStyles.headingS
                          .copyWith(color: AppColors.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The analysis did not return suitable crops for your inputs. Check the browser console for API details.',
                      style: AppTextStyles.bodyM
                          .copyWith(color: AppColors.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final visible = sorted.take(_visibleCount).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _RanksHeader(
            sort: _globalSort,
            onSortChanged: (m) => setState(() {
              _globalSort = m;
              _visibleCount = 5;
            }),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          sliver: SliverList.separated(
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final crop = visible[index];
              return _RecommendationCard(
                crop: crop,
                rank: index + 1,
                onTap: () => Navigator.of(context).push(
                  FadeSlidePageRoute(
                    page: SoilProfileScreen(
                      cropName: crop.cropName,
                      cropCode: crop.cropCode,
                      cropEmoji: _cropEmoji(crop.cropName),
                    ),
                  ),
                ),
              )
                  .animate(delay: (index * 70).ms)
                  .fadeIn(duration: 380.ms)
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    duration: 380.ms,
                    curve: Curves.easeOutCubic,
                  );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            child: _visibleCount < sorted.length
                ? _ShowMoreButton(
                    onTap: () => setState(() => _visibleCount += 5),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _navIndex,
      children: [
        _buildHomeTab(),
        const MySoilScreen(),
        const MyClimateScreen(),
        const CropsBrowserScreen(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          _buildBody(),
          Positioned(
            bottom: 16,
            right: 16,
            child: _ChatbotFab(
              onTap: () => Navigator.of(context).push(
                FadeSlidePageRoute(page: const ChatbotScreen()),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recommendation card
// ─────────────────────────────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final CropRecommendation crop;
  final int rank;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.crop,
    required this.rank,
    required this.onTap,
  });

  Color _labelColor(String label) {
    final l = label.toLowerCase();
    if (l.contains('not') || l.contains('unsuitable')) return AppColors.error;
    if (l.contains('marginal')) return AppColors.amber;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = _labelColor(crop.suitabilityLabel);

    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CropThumb(rank: rank, cropName: crop.cropName),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.cropName,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricChip(
                              emoji: '🌿',
                              label: 'Suitability',
                              value: '${crop.suitabilityIndexPercentage}%',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _MetricChip(
                              emoji: '🏷️',
                              label: 'Status',
                              value: crop.suitabilityLabel,
                              valueColor: labelColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricChip(
                              emoji: '🌾',
                              label: 'Yield',
                              value: crop.actualYield != null
                                  ? '${crop.actualYield} kg/ha'
                                  : '—',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _MetricChip(
                              emoji: '📍',
                              label: 'Region',
                              value:
                                  '${crop.regionalSharePercentage.toStringAsFixed(1)}%',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CropThumb extends StatelessWidget {
  final int rank;
  final String cropName;
  const _CropThumb({required this.rank, required this.cropName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: AppGradients.cropPlaceholder,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _cropEmoji(cropName),
                style: const TextStyle(fontSize: 42),
              ),
            ),
          ),
          Positioned(
            top: -6,
            left: -6,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricChip({
    required this.emoji,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.inkMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShowMoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShowMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppGradients.amberWarm,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.amberGlow,
          ),
          child: Text(
            'Show More',
            style: AppTextStyles.button.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header + sort pill
// ─────────────────────────────────────────────────────────────────────────────

class _RanksHeader extends StatelessWidget {
  final SortMetric sort;
  final ValueChanged<SortMetric> onSortChanged;

  const _RanksHeader({required this.sort, required this.onSortChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 18,
        16,
        22,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.forest,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Crop\nRecommendations',
                  style: AppTextStyles.headingL.copyWith(
                    fontSize: 22,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Based on your soil analysis',
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.80),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _SortPill(sort: sort, onChanged: onSortChanged),
        ],
      ),
    );
  }
}

class _SortPill extends StatelessWidget {
  final SortMetric sort;
  final ValueChanged<SortMetric> onChanged;
  const _SortPill({required this.sort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tune_rounded, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          DropdownButtonHideUnderline(
            child: DropdownButton<SortMetric>(
              value: sort,
              isDense: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 17,
              ),
              dropdownColor: AppColors.forestDark,
              borderRadius: BorderRadius.circular(14),
              style: AppTextStyles.bodyS.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              items: SortMetric.values
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.science_rounded, label: 'My Soil'),
    _NavItem(icon: Icons.cloud_rounded, label: 'My Climate'),
    _NavItem(icon: Icons.grass_rounded, label: 'Crops'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              for (int i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: i == currentIndex
                                  ? AppColors.amber.withValues(alpha: 0.16)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _items[i].icon,
                              size: 23,
                              color: i == currentIndex
                                  ? AppColors.amber
                                  : AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _items[i].label,
                            style: AppTextStyles.bodyS.copyWith(
                              fontSize: 11,
                              color: i == currentIndex
                                  ? AppColors.amber
                                  : AppColors.inkMuted,
                              fontWeight: i == currentIndex
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
// Chatbot FAB
// ─────────────────────────────────────────────────────────────────────────────

class _ChatbotFab extends StatefulWidget {
  final VoidCallback onTap;
  const _ChatbotFab({required this.onTap});

  @override
  State<_ChatbotFab> createState() => _ChatbotFabState();
}

class _ChatbotFabState extends State<_ChatbotFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.forestDark.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Ask ARDHI AI',
            style: AppTextStyles.bodyS.copyWith(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) {
            final ringSize = 56.0 + _pulse.value * 14;
            return SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: ringSize,
                    height: ringSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.amber.withValues(
                          alpha: 0.6 - _pulse.value * 0.4,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                  child!,
                ],
              ),
            );
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.forestDark,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forestDark.withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.forestDark,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
