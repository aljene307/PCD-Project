import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../data/app_session.dart';
import '../theme/app_theme.dart';

// ─── Public entry point ───────────────────────────────────────────────────────

class EcologicalNeedsSection extends StatefulWidget {
  final String cropName;
  const EcologicalNeedsSection({super.key, required this.cropName});

  @override
  State<EcologicalNeedsSection> createState() => _EcologicalNeedsSectionState();
}

class _EcologicalNeedsSectionState extends State<EcologicalNeedsSection> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _needs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await ApiService.getCropsNeeds(AppSession.userId);
      if (!mounted) return;
      // Case-insensitive match
      final key = all.keys.firstWhere(
        (k) => k.toLowerCase() == widget.cropName.toLowerCase(),
        orElse: () => '',
      );
      setState(() {
        _loading = false;
        _needs = key.isEmpty ? null : all[key] as Map<String, dynamic>?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        _SectionHeader(title: '🌱 Crop Ecological Needs'),
        const SizedBox(height: 16),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(
                color: AppColors.forestMid,
                strokeWidth: 2.5,
              ),
            ),
          )
        else if (_error != null)
          _ErrorCard(message: _error!)
        else if (_needs == null)
          _ErrorCard(
              message: 'Ecological data not available for this crop.')
        else
          _NeedsBody(needs: _needs!),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyles.headingS.copyWith(
              fontSize: 17,
              color: AppColors.forestDark,
            )),
        const SizedBox(height: 8),
        Divider(color: AppColors.creamSoft, thickness: 1.2, height: 1),
      ],
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SubHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _CardWrap extends StatelessWidget {
  final Widget child;
  const _CardWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.creamSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyM.copyWith(color: AppColors.inkMuted),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Chip helpers ─────────────────────────────────────────────────────────────

enum _ChipState { optimal, absolute, none }

_ChipState _chipState(String label, String? optStr, String? absStr) {
  final lo = label.toLowerCase();
  bool inOpt = optStr != null &&
      optStr.toLowerCase().split(',').any((s) => s.trim().contains(lo));
  bool inAbs = absStr != null &&
      absStr.toLowerCase().split(',').any((s) => s.trim().contains(lo));
  if (inOpt) return _ChipState.optimal;
  if (inAbs) return _ChipState.absolute;
  return _ChipState.none;
}

class _Chip extends StatelessWidget {
  final String label;
  final _ChipState state;
  const _Chip({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;
    final Border? border;

    switch (state) {
      case _ChipState.optimal:
        bg = AppColors.forestMid.withValues(alpha: 0.13);
        textColor = AppColors.forestDark;
        border = Border.all(color: AppColors.forestMid.withValues(alpha: 0.5));
      case _ChipState.absolute:
        bg = AppColors.amber.withValues(alpha: 0.10);
        textColor = const Color(0xFFB5600A);
        border = Border.all(color: AppColors.amber.withValues(alpha: 0.65));
      case _ChipState.none:
        bg = AppColors.creamSoft;
        textColor = AppColors.inkMuted;
        border = null;
    }

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: border,
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyS.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final String title;
  final List<String> labels;
  final String? optStr;
  final String? absStr;
  const _ChipRow({
    required this.title,
    required this.labels,
    required this.optStr,
    required this.absStr,
  });

  @override
  Widget build(BuildContext context) {
    return _CardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(title: title),
          Wrap(
            children: labels
                .map((l) =>
                    _Chip(label: l, state: _chipState(l, optStr, absStr)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Main body ────────────────────────────────────────────────────────────────

class _NeedsBody extends StatelessWidget {
  final Map<String, dynamic> needs;
  const _NeedsBody({required this.needs});

  Map<String, dynamic>? _m(String k) =>
      needs[k] as Map<String, dynamic>?;

  @override
  Widget build(BuildContext context) {
    final climate = _m('climate_needs');
    final soil = _m('soil_needs');
    final terrain = _m('terrain_needs');

    final temp = climate?['temperature'] as Map<String, dynamic>?;
    final rain = climate?['rainfall'] as Map<String, dynamic>?;
    final light = climate?['light_intensity'] as Map<String, dynamic>?;
    final ph = soil?['ph'] as Map<String, dynamic>?;
    final texture = soil?['soil_texture'] as Map<String, dynamic>?;
    final depth = soil?['soil_depth'] as Map<String, dynamic>?;
    final fertility = soil?['soil_fertility'] as Map<String, dynamic>?;
    final drainage = soil?['soil_drainage'] as Map<String, dynamic>?;
    final salinity = soil?['soil_salinity'] as Map<String, dynamic>?;
    final altitude = terrain?['altitude'] as Map<String, dynamic>?;
    final latitude = terrain?['latitude'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. pH
        _PhBar(
          optMin: _toDouble(ph?['soil_ph_opt_min']),
          optMax: _toDouble(ph?['soil_ph_opt_max']),
          absMin: _toDouble(ph?['soil_ph_abs_min']),
          absMax: _toDouble(ph?['soil_ph_abs_max']),
        ),

        // 2. Temperature
        _TempRuler(
          optMin: _toDouble(temp?['temp_opt_min']),
          optMax: _toDouble(temp?['temp_opt_max']),
          absMin: _toDouble(temp?['temp_abs_min']),
          absMax: _toDouble(temp?['temp_abs_max']),
        ),

        // 3. Rainfall
        _RainBar(
          optMin: _toDouble(rain?['rainfall_opt_min']),
          optMax: _toDouble(rain?['rainfall_opt_max']),
          absMin: _toDouble(rain?['rainfall_abs_min']),
          absMax: _toDouble(rain?['rainfall_abs_max']),
        ),

        // 4. Light intensity
        _LightRow(
          optimal: light?['light_intensity_optimal'] as String?,
          absolute: light?['light_intensity_absolute'] as String?,
        ),

        // 5. Soil texture
        _ChipRow(
          title: '🌱 Soil Texture',
          labels: const ['Heavy', 'Medium', 'Light', 'Organic'],
          optStr: texture?['soil_texture_optimal'] as String?,
          absStr: texture?['soil_texture_absolute'] as String?,
        ),

        // 6. Soil drainage
        _ChipRow(
          title: '💧 Soil Drainage',
          labels: const ['Poorly', 'Well', 'Excessive'],
          optStr: drainage?['soil_drainage_optimal'] as String?,
          absStr: drainage?['soil_drainage_absolute'] as String?,
        ),

        // 7. Soil depth
        _DepthDiagram(
          optStr: depth?['soil_depth_optimal'] as String?,
          absStr: depth?['soil_depth_absolute'] as String?,
        ),

        // 8. Soil salinity
        _ChipRow(
          title: '🧂 Soil Salinity',
          labels: const ['Low', 'Medium', 'High'],
          optStr: salinity?['soil_salinity_optimal'] as String?,
          absStr: salinity?['soil_salinity_absolute'] as String?,
        ),

        // 9. Soil fertility
        _ChipRow(
          title: '🌿 Soil Fertility',
          labels: const ['Low', 'Moderate', 'High'],
          optStr: fertility?['soil_fertility_optimal'] as String?,
          absStr: fertility?['soil_fertility_absolute'] as String?,
        ),

        // 10. Altitude & Latitude
        _TerrainCards(
          altMax: _toDouble(altitude?['altitude_abs_max']),
          latMin: _toDouble(latitude?['latitude_abs_min']),
          latMax: _toDouble(latitude?['latitude_abs_max']),
        ),
      ],
    );
  }

  static double? _toDouble(dynamic v) =>
      v == null ? null : (v as num).toDouble();
}

// ─── 1. pH Rainbow Bar ────────────────────────────────────────────────────────

class _PhBar extends StatefulWidget {
  final double? optMin, optMax, absMin, absMax;
  const _PhBar({this.optMin, this.optMax, this.absMin, this.absMax});

  @override
  State<_PhBar> createState() => _PhBarState();
}

class _PhBarState extends State<_PhBar> {
  bool _showAbs = false;

  @override
  Widget build(BuildContext context) {
    return _CardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(
            title: '🧪 Soil pH',
            trailing: TextButton(
              onPressed: () => setState(() => _showAbs = !_showAbs),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _showAbs ? 'Hide Detail' : 'See Detail',
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.forestMid,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          LayoutBuilder(builder: (ctx, constraints) {
            return _PhBarPainter(
              width: constraints.maxWidth,
              optMin: widget.optMin,
              optMax: widget.optMax,
              absMin: _showAbs ? widget.absMin : null,
              absMax: _showAbs ? widget.absMax : null,
            );
          }),
        ],
      ),
    );
  }
}

class _PhBarPainter extends StatelessWidget {
  final double width;
  final double? optMin, optMax, absMin, absMax;
  const _PhBarPainter(
      {required this.width,
      this.optMin,
      this.optMax,
      this.absMin,
      this.absMax});

  double _frac(double ph) => ((ph - 1) / 13).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    const barH = 14.0;
    const labelH = 40.0;
    const tickH = 24.0;
    const absLabelH = 40.0;
    final showAbs = absMin != null && absMax != null;
    final totalH = labelH + barH + tickH + (showAbs ? absLabelH : 0);

    return SizedBox(
      width: width,
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Absolute range label (orange) — above bar
          if (showAbs && absMin != null && absMax != null)
            _RangeLabel(
              frac1: _frac(absMin!),
              frac2: _frac(absMax!),
              totalW: width,
              topOffset: 0,
              labelH: absLabelH - 4,
              text:
                  '${absMin!.toStringAsFixed(1)} pH – ${absMax!.toStringAsFixed(1)} pH',
              borderColor: AppColors.amber,
              textColor: const Color(0xFFB5600A),
            ),

          // Optimal range label (green) — above bar
          if (optMin != null && optMax != null)
            _RangeLabel(
              frac1: _frac(optMin!),
              frac2: _frac(optMax!),
              totalW: width,
              topOffset: showAbs ? absLabelH : 0,
              labelH: labelH - 4,
              text:
                  '${optMin!.toStringAsFixed(1)} pH – ${optMax!.toStringAsFixed(1)} pH',
              borderColor: AppColors.forestMid,
              textColor: AppColors.forestDark,
            ),

          // Rainbow gradient bar
          Positioned(
            top: (showAbs ? absLabelH : 0) + labelH,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: barH,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF0000),
                      Color(0xFFFF7700),
                      Color(0xFFFFFF00),
                      Color(0xFF00CC00),
                      Color(0xFF00BBAA),
                      Color(0xFF0055FF),
                      Color(0xFF8800CC),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tick marks + numbers 1–14
          Positioned(
            top: (showAbs ? absLabelH : 0) + labelH + barH,
            left: 0,
            right: 0,
            child: _PhTicks(totalW: width),
          ),
        ],
      ),
    );
  }
}

class _RangeLabel extends StatelessWidget {
  final double frac1, frac2, totalW, topOffset, labelH;
  final String text;
  final Color borderColor, textColor;

  const _RangeLabel({
    required this.frac1,
    required this.frac2,
    required this.totalW,
    required this.topOffset,
    required this.labelH,
    required this.text,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final midFrac = (frac1 + frac2) / 2;
    const boxW = 120.0;
    double left = totalW * midFrac - boxW / 2;
    left = left.clamp(0.0, totalW - boxW);

    return Positioned(
      top: topOffset,
      left: left,
      width: boxW,
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: AppShadows.soft,
            ),
            child: Text(
              text,
              style: AppTextStyles.bodyS.copyWith(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // arrow
          CustomPaint(
            size: const Size(10, 6),
            painter: _DownArrowPainter(color: borderColor),
          ),
        ],
      ),
    );
  }
}

class _DownArrowPainter extends CustomPainter {
  final Color color;
  const _DownArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DownArrowPainter old) => old.color != color;
}

class _PhTicks extends StatelessWidget {
  final double totalW;
  const _PhTicks({required this.totalW});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Stack(
        children: [
          for (int i = 1; i <= 14; i++)
            Positioned(
              left: totalW * ((i - 1) / 13) - 6,
              top: 0,
              child: SizedBox(
                width: 12,
                child: Text(
                  '$i',
                  style: AppTextStyles.bodyS.copyWith(
                    fontSize: 9,
                    color: AppColors.inkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── 2. Temperature Ruler ─────────────────────────────────────────────────────

class _TempRuler extends StatefulWidget {
  final double? optMin, optMax, absMin, absMax;
  const _TempRuler({this.optMin, this.optMax, this.absMin, this.absMax});

  @override
  State<_TempRuler> createState() => _TempRulerState();
}

class _TempRulerState extends State<_TempRuler> {
  bool _showAbs = false;

  @override
  Widget build(BuildContext context) {
    return _CardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(
            title: '🌡️ Temperature',
            trailing: TextButton(
              onPressed: () => setState(() => _showAbs = !_showAbs),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _showAbs ? 'Hide Detail' : 'See Detail',
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.forestMid,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          LayoutBuilder(builder: (ctx, constraints) {
            return _TempRulerPaint(
              width: constraints.maxWidth,
              optMin: widget.optMin,
              optMax: widget.optMax,
              absMin: _showAbs ? widget.absMin : null,
              absMax: _showAbs ? widget.absMax : null,
            );
          }),
        ],
      ),
    );
  }
}

class _TempRulerPaint extends StatelessWidget {
  final double width;
  final double? optMin, optMax, absMin, absMax;

  static const double _scaleMin = -10;
  static const double _scaleMax = 50;
  static const double _barH = 14;
  static const double _tickAreaH = 26;

  const _TempRulerPaint(
      {required this.width,
      this.optMin,
      this.optMax,
      this.absMin,
      this.absMax});

  double _frac(double v) =>
      ((v - _scaleMin) / (_scaleMax - _scaleMin)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, _barH + _tickAreaH),
      painter: _TempPainter(
        optMin: optMin,
        optMax: optMax,
        absMin: absMin,
        absMax: absMax,
        frac: _frac,
      ),
    );
  }
}

class _TempPainter extends CustomPainter {
  final double? optMin, optMax, absMin, absMax;
  final double Function(double) frac;

  const _TempPainter(
      {required this.optMin,
      required this.optMax,
      required this.absMin,
      required this.absMax,
      required this.frac});

  static const double _barH = 14;
  static const double _barTop = 0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // Background ruler track
    final trackPaint = Paint()
      ..color = const Color(0xFFE8E4D9)
      ..style = PaintingStyle.fill;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, _barTop, w, _barH),
      const Radius.circular(7),
    );
    canvas.drawRRect(rr, trackPaint);

    // Absolute range block (orange outline)
    if (absMin != null && absMax != null) {
      final x1 = frac(absMin!) * w;
      final x2 = frac(absMax!) * w;
      final absPaint = Paint()
        ..color = AppColors.amber.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      final absStroke = Paint()
        ..color = AppColors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final absRect =
          RRect.fromRectAndRadius(Rect.fromLTWH(x1, _barTop, x2 - x1, _barH), const Radius.circular(5));
      canvas.drawRRect(absRect, absPaint);
      canvas.drawRRect(absRect, absStroke);
      // label inside
      _drawBlockLabel(
          canvas, '${absMin!.toInt()}°C – ${absMax!.toInt()}°C', x1, x2, _barTop, _barH, AppColors.amber);
    }

    // Optimal range block (green filled)
    if (optMin != null && optMax != null) {
      final x1 = frac(optMin!) * w;
      final x2 = frac(optMax!) * w;
      final optPaint = Paint()
        ..color = AppColors.forestMid.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      final optRect =
          RRect.fromRectAndRadius(Rect.fromLTWH(x1, _barTop, x2 - x1, _barH), const Radius.circular(5));
      canvas.drawRRect(optRect, optPaint);
      _drawBlockLabel(canvas, '${optMin!.toInt()}°C – ${optMax!.toInt()}°C', x1, x2, _barTop, _barH, Colors.white);
    }

    // Tick marks every 5°C from -10 to 50
    final tickPaint = Paint()
      ..color = AppColors.inkMuted
      ..strokeWidth = 1;

    const picos = [-10, -5, 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
    for (final t in picos) {
      final x = frac(t.toDouble()) * w;
      canvas.drawLine(
          Offset(x, _barTop + _barH + 2), Offset(x, _barTop + _barH + 8), tickPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: '$t',
          style: const TextStyle(
              fontSize: 8, color: Color(0xFF6B6B6B), fontFamily: 'Inter'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, _barTop + _barH + 10));
    }
  }

  void _drawBlockLabel(Canvas canvas, String text, double x1, double x2,
      double top, double h, Color textColor) {
    final mid = (x1 + x2) / 2;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            fontSize: 8,
            color: textColor,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter'),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(0, x2 - x1 - 2));
    tp.paint(canvas, Offset(mid - tp.width / 2, top + (h - tp.height) / 2));
  }

  @override
  bool shouldRepaint(_TempPainter old) => true;
}

// ─── 3. Rainfall Bar ──────────────────────────────────────────────────────────

class _RainBar extends StatefulWidget {
  final double? optMin, optMax, absMin, absMax;
  const _RainBar({this.optMin, this.optMax, this.absMin, this.absMax});

  @override
  State<_RainBar> createState() => _RainBarState();
}

class _RainBarState extends State<_RainBar> {
  bool _showAbs = false;

  @override
  Widget build(BuildContext context) {
    return _CardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(
            title: '🌧️ Rainfall',
            trailing: TextButton(
              onPressed: () => setState(() => _showAbs = !_showAbs),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _showAbs ? 'Hide Detail' : 'See Detail',
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.forestMid,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          LayoutBuilder(builder: (ctx, constraints) {
            return _RainBarPaint(
              width: constraints.maxWidth,
              optMin: widget.optMin,
              optMax: widget.optMax,
              absMin: _showAbs ? widget.absMin : null,
              absMax: _showAbs ? widget.absMax : null,
            );
          }),
        ],
      ),
    );
  }
}

class _RainBarPaint extends StatelessWidget {
  final double width;
  final double? optMin, optMax, absMin, absMax;

  static const double _scaleMax = 5000;
  static const double _barH = 14;
  static const List<int> _ticks = [0, 1000, 2000, 3000, 4000, 5000];

  const _RainBarPaint(
      {required this.width,
      this.optMin,
      this.optMax,
      this.absMin,
      this.absMax});

  double _frac(double v) => (v / _scaleMax).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, _barH + 26),
      painter: _RainPainter(
        optMin: optMin,
        optMax: optMax,
        absMin: absMin,
        absMax: absMax,
        frac: _frac,
        ticks: _ticks,
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  final double? optMin, optMax, absMin, absMax;
  final double Function(double) frac;
  final List<int> ticks;

  static const _barH = 14.0;

  const _RainPainter({
    required this.optMin,
    required this.optMax,
    required this.absMin,
    required this.absMax,
    required this.frac,
    required this.ticks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // Background gradient bar (light blue → dark blue)
    final bgPaint = Paint()
      ..shader = LinearGradient(colors: const [
        Color(0xFFD8EEFF),
        Color(0xFF1565C0),
      ]).createShader(Rect.fromLTWH(0, 0, w, _barH));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, _barH), const Radius.circular(7)),
      bgPaint,
    );

    // Absolute range block (orange outline)
    if (absMin != null && absMax != null) {
      final x1 = frac(absMin!) * w;
      final x2 = frac(absMax!) * w;
      final absRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x1, 0, x2 - x1, _barH), const Radius.circular(5));
      canvas.drawRRect(
          absRect,
          Paint()
            ..color = AppColors.amber.withValues(alpha: 0.20)
            ..style = PaintingStyle.fill);
      canvas.drawRRect(
          absRect,
          Paint()
            ..color = AppColors.amber
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      _blockLabel(canvas, '${absMin!.toInt()}–${absMax!.toInt()} mm', x1, x2,
          AppColors.amber);
    }

    // Optimal block (green)
    if (optMin != null && optMax != null) {
      final x1 = frac(optMin!) * w;
      final x2 = frac(optMax!) * w;
      final optRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x1, 0, x2 - x1, _barH), const Radius.circular(5));
      canvas.drawRRect(
          optRect,
          Paint()
            ..color = AppColors.forestMid.withValues(alpha: 0.85)
            ..style = PaintingStyle.fill);
      _blockLabel(canvas, '${optMin!.toInt()}–${optMax!.toInt()} mm', x1, x2,
          Colors.white);
    }

    // Ticks
    final tickPaint = Paint()
      ..color = const Color(0xFF6B6B6B)
      ..strokeWidth = 1;
    for (final t in ticks) {
      final x = frac(t.toDouble()) * w;
      canvas.drawLine(Offset(x, _barH + 2), Offset(x, _barH + 7), tickPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: t == 0 ? '0' : '${t ~/ 1000}k',
          style: const TextStyle(
              fontSize: 8, color: Color(0xFF6B6B6B), fontFamily: 'Inter'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, _barH + 9));
    }
  }

  void _blockLabel(Canvas canvas, String text, double x1, double x2, Color c) {
    final mid = (x1 + x2) / 2;
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: 7,
              color: c,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter')),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(0, x2 - x1 - 2));
    tp.paint(canvas, Offset(mid - tp.width / 2, (_barH - tp.height) / 2));
  }

  @override
  bool shouldRepaint(_RainPainter old) => true;
}

// ─── 4. Light Intensity ───────────────────────────────────────────────────────

class _LightRow extends StatelessWidget {
  final String? optimal, absolute;

  static const _levels = [
    (key: 'deep shade', emoji: '🌑', label: 'Deep\nShade'),
    (key: 'shade', emoji: '🌘', label: 'Shade'),
    (key: 'light shade', emoji: '🌤️', label: 'Light\nShade'),
    (key: 'very bright', emoji: '🌟', label: 'Very\nBright'),
    (key: 'bright', emoji: '☀️', label: 'Bright'),
    (key: 'clear skies', emoji: '✨', label: 'Clear\nSkies'),
  ];

  const _LightRow({this.optimal, this.absolute});

  bool _match(String? val, String key) =>
      val != null && val.toLowerCase().contains(key.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final bothNull = optimal == null && absolute == null;

    return _CardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(title: '☀️ Light Intensity'),
          if (bothNull)
            Text('N/A',
                style: AppTextStyles.bodyS.copyWith(color: AppColors.inkMuted))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _levels.map((lvl) {
                final isOpt = _match(optimal, lvl.key);
                final isAbs = _match(absolute, lvl.key);
                final isBoth = isOpt && isAbs;
                return _LightIcon(
                  emoji: lvl.emoji,
                  label: lvl.label,
                  isOptimal: isOpt || isBoth,
                  isAbsolute: isAbs && !isBoth,
                  isBoth: isBoth,
                );
              }).toList(),
            ),
          const SizedBox(height: 6),
          // Legend
          Row(
            children: [
              _dot(AppColors.amber, filled: true),
              const SizedBox(width: 4),
              Text('Optimal',
                  style: AppTextStyles.bodyS.copyWith(fontSize: 10)),
              const SizedBox(width: 12),
              _dot(AppColors.amber, filled: false),
              const SizedBox(width: 4),
              Text('Absolute',
                  style: AppTextStyles.bodyS.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _dot(Color c, {required bool filled}) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? c.withValues(alpha: 0.25) : Colors.transparent,
          border: Border.all(
              color: c,
              width: 1.5,
              style: filled ? BorderStyle.solid : BorderStyle.solid),
        ),
        child: filled
            ? null
            : CustomPaint(painter: _DashedCirclePainter(color: c)),
      );
}

class _LightIcon extends StatelessWidget {
  final String emoji, label;
  final bool isOptimal, isAbsolute, isBoth;

  const _LightIcon({
    required this.emoji,
    required this.label,
    required this.isOptimal,
    required this.isAbsolute,
    required this.isBoth,
  });

  @override
  Widget build(BuildContext context) {
    final showCircle = isOptimal || isAbsolute || isBoth;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (showCircle)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOptimal
                      ? AppColors.amber.withValues(alpha: 0.22)
                      : Colors.transparent,
                  border: isAbsolute
                      ? Border.all(
                          color: AppColors.amber,
                          width: 1.5,
                          style: BorderStyle.solid)
                      : null,
                ),
              ),
            Text(emoji, style: const TextStyle(fontSize: 20)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodyS.copyWith(fontSize: 9),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashCount = 8;
    const gapAngle = math.pi / (dashCount * 2);
    const dashAngle = math.pi / dashCount - gapAngle;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    for (int i = 0; i < dashCount * 2; i++) {
      final startAngle = i * (dashAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

// ─── 7. Soil Depth Diagram ────────────────────────────────────────────────────

class _DepthDiagram extends StatelessWidget {
  final String? optStr, absStr;

  static const _layers = [
    (key: 'shallow', label: 'Shallow', sub: '20–50 cm'),
    (key: 'medium', label: 'Medium', sub: '50–150 cm'),
    (key: 'deep', label: 'Deep', sub: '>150 cm'),
  ];

  const _DepthDiagram({this.optStr, this.absStr});

  bool _match(String? s, String key) =>
      s != null && s.toLowerCase().contains(key);

  @override
  Widget build(BuildContext context) {
    return _CardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(title: '🪏 Soil Depth'),
          Row(
            children: [
              // Depth layers column
              Expanded(
                child: Column(
                  children: _layers.map((layer) {
                    final isOpt = _match(optStr, layer.key);
                    final isAbs = _match(absStr, layer.key);
                    final bg = isOpt
                        ? AppColors.forestMid.withValues(alpha: 0.75)
                        : isAbs
                            ? AppColors.amber.withValues(alpha: 0.65)
                            : AppColors.creamSoft;
                    final textC =
                        (isOpt || isAbs) ? Colors.white : AppColors.inkMuted;
                    final borderC = isOpt
                        ? AppColors.forestMid
                        : isAbs
                            ? AppColors.amber
                            : AppColors.creamSoft;

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderC, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Text(layer.label,
                              style: AppTextStyles.label.copyWith(
                                  fontSize: 12, color: textC)),
                          const Spacer(),
                          Text(layer.sub,
                              style: AppTextStyles.bodyS.copyWith(
                                  fontSize: 10, color: textC.withValues(alpha: 0.8))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 12),
              // Legend
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DepthLegend(color: AppColors.forestMid, label: 'Optimal'),
                  const SizedBox(height: 6),
                  _DepthLegend(color: AppColors.amber, label: 'Absolute'),
                  const SizedBox(height: 6),
                  _DepthLegend(color: AppColors.creamSoft, label: 'Other'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepthLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _DepthLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyles.bodyS.copyWith(
                fontSize: 10, color: AppColors.inkMuted)),
      ],
    );
  }
}

// ─── 10. Terrain Cards ────────────────────────────────────────────────────────

class _TerrainCards extends StatelessWidget {
  final double? altMax, latMin, latMax;
  const _TerrainCards({this.altMax, this.latMin, this.latMax});

  @override
  Widget build(BuildContext context) {
    final altText =
        altMax != null ? 'Up to ${altMax!.toInt()} m' : 'No limit';
    final latText = (latMin == null && latMax == null)
        ? 'Any latitude'
        : 'Lat: ${latMin?.toStringAsFixed(0) ?? '?'}° to ${latMax?.toStringAsFixed(0) ?? '?'}°';

    return Row(
      children: [
        Expanded(
          child: _TerrainCard(
            emoji: '🏔️',
            title: 'Altitude',
            value: altText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TerrainCard(
            emoji: '🧭',
            title: 'Latitude',
            value: latText,
          ),
        ),
      ],
    );
  }
}

class _TerrainCard extends StatelessWidget {
  final String emoji, title, value;
  const _TerrainCard(
      {required this.emoji, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(title,
                  style: AppTextStyles.label.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.forestDark,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
