import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/app_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// ─── Depth metadata ───────────────────────────────────────────────────────────

const _kDepths = [
  (code: 'D1', range: '0–20 cm'),
  (code: 'D2', range: '20–40 cm'),
  (code: 'D3', range: '40–60 cm'),
  (code: 'D4', range: '60–80 cm'),
  (code: 'D5', range: '80–100 cm'),
  (code: 'D6', range: '100–120 cm'),
  (code: 'D7', range: '120–140 cm'),
];

const _kLayerColors = [
  Color(0xFFDDB88A),
  Color(0xFFC99E6E),
  Color(0xFFB58554),
  Color(0xFFA16C3A),
  Color(0xFF8D5320),
  Color(0xFF793A06),
  Color(0xFF622B00),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class MySoilScreen extends StatefulWidget {
  const MySoilScreen({super.key});

  @override
  State<MySoilScreen> createState() => _MySoilScreenState();
}

class _MySoilScreenState extends State<MySoilScreen> {
  bool _loading = true;
  String? _error;
  List<SoilLayer> _layers = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final layers = AppSession.hasLabData
          ? await ApiService.getReportSoilProperties(AppSession.userId)
          : await ApiService.getSoilProperties(AppSession.userId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _layers = layers;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          _Header(),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.forestMid,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : _error != null && _layers.isEmpty
                    ? _ErrorCard(message: _error!)
                    : _Body(
                        layers: _layers,
                        selectedIndex: _selectedIndex,
                        onSelect: (i) =>
                            setState(() => _selectedIndex = i),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 18,
        20,
        24,
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
                  'My Soil Profile',
                  style: AppTextStyles.headingL.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 4),
                Text(
                  'Soil properties by depth layer',
                  style: AppTextStyles.bodyM.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Text('🪱', style: TextStyle(fontSize: 36)),
        ],
      ),
    );
  }
}

// ─── Error card ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyM.copyWith(color: AppColors.error),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Main body ────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final List<SoilLayer> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _Body({
    required this.layers,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final selected =
        selectedIndex < layers.length ? layers[selectedIndex] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PART 1 — Depth selector
        _DepthSelector(
          layers: layers,
          selectedIndex: selectedIndex,
          onSelect: onSelect,
        ).animate().fadeIn(duration: 380.ms).slideY(
              begin: 0.04,
              end: 0,
              duration: 380.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 16),

        // PART 2 — Layer detail panel
        if (selected != null)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position:
                    Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                        .animate(anim),
                child: child,
              ),
            ),
            child: _LayerDetailPanel(
              key: ValueKey(selected.code),
              layer: selected,
              depthRange: selectedIndex < _kDepths.length
                  ? _kDepths[selectedIndex].range
                  : '',
            ),
          ).animate(delay: 80.ms).fadeIn(duration: 350.ms),
        const SizedBox(height: 24),

        // PART 3 — pH chart
        if (layers.isNotEmpty)
          _DepthBarChart(
            title: 'pH Across Depth Layers',
            layers: layers,
            getValue: (l) => l.ph,
            maxValue: 14,
            colorForValue: _phColor,
            unit: '',
            decimals: 1,
            xTicks: const [0, 2, 4, 6, 8, 10, 12, 14],
          ).animate(delay: 160.ms).fadeIn(duration: 380.ms),
        const SizedBox(height: 16),

        // PART 4 — Organic Carbon chart
        if (layers.isNotEmpty)
          _DepthBarChart(
            title: 'Organic Carbon (%) Across Depth Layers',
            layers: layers,
            getValue: (l) => l.oc,
            maxValue: _ocMax(layers),
            colorForValue: _ocColor,
            unit: '%',
            decimals: 2,
            xTicks: _ocTicks(layers),
          ).animate(delay: 200.ms).fadeIn(duration: 380.ms),
      ],
    );
  }

  static Color _phColor(double v) {
    if (v < 5.5) return AppColors.error;
    if (v <= 7.0) return AppColors.forestMid;
    if (v <= 8.5) return AppColors.amber;
    return AppColors.error;
  }

  static Color _ocColor(double v) {
    final t = (v / 5.0).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFF74C69D), AppColors.forestDark, t)!;
  }

  static double _ocMax(List<SoilLayer> layers) {
    double max = 3;
    for (final l in layers) {
      if (l.oc != null && l.oc! > max) max = l.oc!;
    }
    return (max * 1.2).ceilToDouble().clamp(1, 20).toDouble();
  }

  static List<double> _ocTicks(List<SoilLayer> layers) {
    final max = _ocMax(layers);
    final step = max <= 4 ? 1.0 : max <= 8 ? 2.0 : 5.0;
    final ticks = <double>[];
    for (double t = 0; t <= max + step / 2; t += step) {
      ticks.add(t);
    }
    return ticks;
  }
}

// ─── PART 1 — Depth Selector ──────────────────────────────────────────────────

class _DepthSelector extends StatelessWidget {
  final List<SoilLayer> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _DepthSelector({
    required this.layers,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Text('🪨', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'Select Depth Layer',
                  style: AppTextStyles.label.copyWith(fontSize: 13),
                ),
                const Spacer(),
                Text(
                  selectedIndex < _kDepths.length
                      ? _kDepths[selectedIndex].range
                      : '',
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1ECE0)),
          for (int i = 0; i < _kDepths.length; i++) _DepthBand(
                index: i,
                isSelected: i == selectedIndex,
                hasData: i < layers.length,
                onTap: () => onSelect(i),
              ),
        ],
      ),
    );
  }
}

class _DepthBand extends StatelessWidget {
  final int index;
  final bool isSelected;
  final bool hasData;
  final VoidCallback onTap;

  const _DepthBand({
    required this.index,
    required this.isSelected,
    required this.hasData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = index < _kLayerColors.length
        ? _kLayerColors[index]
        : _kLayerColors.last;
    final bg = isSelected
        ? baseColor.withValues(alpha: 0.18)
        : baseColor.withValues(alpha: 0.08);
    final textColor =
        isSelected ? AppColors.ink : AppColors.inkMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          border: isSelected
              ? const Border(
                  left: BorderSide(color: AppColors.amber, width: 4),
                )
              : const Border(
                  left: BorderSide(color: Colors.transparent, width: 4),
                ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Row(
          children: [
            // Color swatch
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            // Code
            SizedBox(
              width: 28,
              child: Text(
                _kDepths[index].code,
                style: AppTextStyles.label.copyWith(
                  fontSize: 12,
                  color: isSelected ? AppColors.amber : AppColors.inkMuted,
                  fontWeight: isSelected
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Range
            Text(
              _kDepths[index].range,
              style: AppTextStyles.bodyS.copyWith(
                fontSize: 12,
                color: textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (!hasData)
              Text(
                'No data',
                style: AppTextStyles.bodyS.copyWith(
                  fontSize: 10,
                  color: AppColors.inkMuted,
                ),
              )
            else if (isSelected)
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.amber,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── PART 2 — Layer Detail Panel ─────────────────────────────────────────────

class _LayerDetailPanel extends StatelessWidget {
  final SoilLayer layer;
  final String depthRange;

  const _LayerDetailPanel({
    super.key,
    required this.layer,
    required this.depthRange,
  });

  String _fmt(double? v, {int decimals = 1}) =>
      v != null ? v.toStringAsFixed(decimals) : 'N/A';

  String _decodeDrg(String? code) {
    if (code == null) return 'N/A';
    return switch (code.toUpperCase()) {
      'VP' => 'Very Poor',
      'P' => 'Poor',
      'I' => 'Imperfect',
      'MW' => 'Moderately Well',
      'W' => 'Well',
      'E' => 'Excessive',
      _ => code,
    };
  }

  @override
  Widget build(BuildContext context) {
    final props = [
      _PropData(
        icon: Icons.science_rounded,
        iconColor: const Color(0xFF1565C0),
        name: 'pH',
        value: _fmt(layer.ph),
        unit: '',
      ),
      _PropData(
        icon: Icons.eco_rounded,
        iconColor: AppColors.forestMid,
        name: 'Organic Carbon',
        value: _fmt(layer.oc, decimals: 2),
        unit: '%',
      ),
      _PropData(
        icon: Icons.layers_rounded,
        iconColor: const Color(0xFF5D4037),
        name: 'Soil Texture',
        value: layer.txt ?? 'N/A',
        unit: '',
      ),
      _PropData(
        icon: Icons.water_drop_rounded,
        iconColor: const Color(0xFF0277BD),
        name: 'Drainage',
        value: _decodeDrg(layer.drg),
        unit: '',
      ),
      _PropData(
        icon: Icons.bolt_rounded,
        iconColor: const Color(0xFFF57F17),
        name: 'EC',
        value: _fmt(layer.ec, decimals: 2),
        unit: 'dS/m',
      ),
      _PropData(
        icon: Icons.biotech_rounded,
        iconColor: const Color(0xFF6A1B9A),
        name: 'CEC Soil',
        value: _fmt(layer.cecSoil),
        unit: 'cmol/kg',
      ),
      _PropData(
        icon: Icons.view_in_ar_rounded,
        iconColor: const Color(0xFF37474F),
        name: 'CEC Clay',
        value: _fmt(layer.cecClay),
        unit: 'cmol/kg',
      ),
      _PropData(
        icon: Icons.grass_rounded,
        iconColor: AppColors.success,
        name: 'Base Saturation',
        value: _fmt(layer.bs),
        unit: '%',
      ),
      _PropData(
        icon: Icons.water_damage_rounded,
        iconColor: const Color(0xFF00838F),
        name: 'ESP',
        value: _fmt(layer.esp),
        unit: '%',
      ),
      _PropData(
        icon: Icons.terrain_rounded,
        iconColor: const Color(0xFF78909C),
        name: 'Coarse Fragments',
        value: _fmt(layer.grc),
        unit: '%',
      ),
      _PropData(
        icon: Icons.bubble_chart_rounded,
        iconColor: const Color(0xFF8D6E63),
        name: 'Calcium Carbonate',
        value: _fmt(layer.ccb),
        unit: '%',
      ),
      _PropData(
        icon: Icons.diamond_rounded,
        iconColor: const Color(0xFF4DD0E1),
        name: 'Gypsum',
        value: _fmt(layer.gyp),
        unit: '%',
      ),
      _PropData(
        icon: Icons.public_rounded,
        iconColor: AppColors.forestDark,
        name: 'Total Exch. Bases',
        value: _fmt(layer.teb),
        unit: 'cmol/kg',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    layer.code,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  depthRange,
                  style: AppTextStyles.headingS.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.creamSoft),
          // Property grid
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: LayoutBuilder(builder: (ctx, constraints) {
              final colW = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: props
                    .map((p) => SizedBox(
                          width: colW,
                          child: _PropCard(prop: p),
                        ))
                    .toList(),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PropData {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String value;
  final String unit;
  const _PropData({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.value,
    required this.unit,
  });
}

class _PropCard extends StatelessWidget {
  final _PropData prop;
  const _PropCard({required this.prop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.creamSoft, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: prop.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(prop.icon, size: 16, color: prop.iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prop.name,
                  style: AppTextStyles.bodyS.copyWith(
                    fontSize: 10,
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  prop.unit.isEmpty
                      ? prop.value
                      : '${prop.value} ${prop.unit}',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12,
                    color: prop.value == 'N/A'
                        ? AppColors.inkMuted
                        : AppColors.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PART 3 & 4 — Depth Bar Chart ────────────────────────────────────────────

class _DepthBarChart extends StatelessWidget {
  final String title;
  final List<SoilLayer> layers;
  final double? Function(SoilLayer) getValue;
  final double maxValue;
  final Color Function(double) colorForValue;
  final String unit;
  final int decimals;
  final List<double> xTicks;

  const _DepthBarChart({
    required this.title,
    required this.layers,
    required this.getValue,
    required this.maxValue,
    required this.colorForValue,
    required this.unit,
    required this.decimals,
    required this.xTicks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingS.copyWith(fontSize: 14)),
          const SizedBox(height: 16),
          for (int i = 0; i < _kDepths.length; i++)
            _buildBarRow(i),
          const SizedBox(height: 8),
          _buildXAxis(),
        ],
      ),
    );
  }

  Widget _buildBarRow(int i) {
    final depthInfo = _kDepths[i];
    final layer = i < layers.length ? layers[i] : null;
    final value = layer != null ? getValue(layer) : null;
    final fraction = value != null
        ? (value / maxValue).clamp(0.0, 1.0)
        : 0.0;
    final barColor =
        value != null ? colorForValue(value) : AppColors.creamSoft;
    final valLabel = value != null
        ? value.toStringAsFixed(decimals) + (unit.isNotEmpty ? ' $unit' : '')
        : 'N/A';

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          // Depth label
          SizedBox(
            width: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  depthInfo.code,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 11,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  depthInfo.range,
                  style: AppTextStyles.bodyS.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
          // Bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(
                children: [
                  Container(height: 22, color: AppColors.creamSoft),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Value label
          SizedBox(
            width: 52,
            child: Text(
              valLabel,
              style: AppTextStyles.label.copyWith(
                fontSize: 10,
                color: value != null ? AppColors.ink : AppColors.inkMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXAxis() {
    return Padding(
      padding: const EdgeInsets.only(left: 88),
      child: LayoutBuilder(builder: (ctx, constraints) {
        // barW = total remaining width minus the 8px gap + 52px value label
        final barW = (constraints.maxWidth - 60).clamp(1.0, double.infinity);
        return SizedBox(
          height: 14,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final t in xTicks)
                Positioned(
                  // Centre the 20px label over the tick position; clamp so it
                  // never goes left of 0 or right of the bar area.
                  left: ((t / maxValue).clamp(0.0, 1.0) * barW - 10)
                      .clamp(0.0, barW - 10.0),
                  top: 0,
                  child: SizedBox(
                    width: 20,
                    child: Text(
                      t == t.truncateToDouble()
                          ? t.toInt().toString()
                          : t.toStringAsFixed(1),
                      style: AppTextStyles.bodyS.copyWith(fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
