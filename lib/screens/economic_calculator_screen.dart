import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class EconomicCalculatorScreen extends StatefulWidget {
  final String cropName;
  const EconomicCalculatorScreen({super.key, required this.cropName});

  @override
  State<EconomicCalculatorScreen> createState() =>
      _EconomicCalculatorScreenState();
}

class _EconomicCalculatorScreenState extends State<EconomicCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _costCtrl = TextEditingController();
  final _yieldCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _loading = false;
  EconomicResult? _result;

  String get _displayName {
    final n = widget.cropName;
    if (n.isEmpty) return n;
    return '${n[0].toUpperCase()}${n.substring(1)}';
  }

  @override
  void dispose() {
    _costCtrl.dispose();
    _yieldCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;

    final cost = double.parse(_costCtrl.text.trim());
    final yieldVal = double.parse(_yieldCtrl.text.trim());
    final price = double.parse(_priceCtrl.text.trim());

    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final result = await ApiService.postEconomicsSuitability(
        cropName: widget.cropName,
        cropCost: cost,
        cropYield: yieldVal,
        farmPrice: price,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(cropName: _displayName),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Input card ──────────────────────────────────────────
                    _InputCard(
                      costCtrl: _costCtrl,
                      yieldCtrl: _yieldCtrl,
                      priceCtrl: _priceCtrl,
                    ).animate().fadeIn(duration: 380.ms).slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 380.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 20),

                    // ── Calculate button ────────────────────────────────────
                    _CalcButton(loading: _loading, onTap: _calculate)
                        .animate(delay: 80.ms)
                        .fadeIn(duration: 350.ms),

                    // ── Results ─────────────────────────────────────────────
                    if (_result != null) ...[
                      const SizedBox(height: 28),
                      _ResultsSection(result: _result!)
                          .animate()
                          .fadeIn(duration: 420.ms)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            duration: 420.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String cropName;
  const _Header({required this.cropName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
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
                width: 38,
                height: 38,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ECONOMIC ANALYSIS',
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.cream.withValues(alpha: 0.65),
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cropName,
                  style: AppTextStyles.headingXL.copyWith(fontSize: 28),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your farm data to calculate expected profit',
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.cream.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input card ───────────────────────────────────────────────────────────────

class _InputCard extends StatelessWidget {
  final TextEditingController costCtrl;
  final TextEditingController yieldCtrl;
  final TextEditingController priceCtrl;

  const _InputCard({
    required this.costCtrl,
    required this.yieldCtrl,
    required this.priceCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
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
                  Icons.edit_note_rounded,
                  size: 20,
                  color: AppColors.forestMid,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Enter Your Farm Data',
                style: AppTextStyles.headingS.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _UnitField(
            controller: costCtrl,
            label: 'Production Cost',
            hint: 'e.g. 1200',
            unit: 'TND/ha',
            icon: Icons.payments_rounded,
            validator: (v) => _required(v, 'Production cost'),
          ),
          const SizedBox(height: 14),
          _UnitField(
            controller: yieldCtrl,
            label: 'Expected Yield',
            hint: 'e.g. 3.5',
            unit: 't/ha',
            icon: Icons.scale_rounded,
            validator: (v) => _required(v, 'Expected yield'),
          ),
          const SizedBox(height: 14),
          _UnitField(
            controller: priceCtrl,
            label: 'Farm Price',
            hint: 'e.g. 0.8',
            unit: 'TND/kg',
            icon: Icons.sell_rounded,
            validator: (v) => _required(v, 'Farm price'),
          ),
        ],
      ),
    );
  }

  static String? _required(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
    return null;
  }
}

class _UnitField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String unit;
  final IconData icon;
  final FormFieldValidator<String>? validator;

  const _UnitField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.unit,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyS.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMuted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\.]')),
          ],
          style: AppTextStyles.bodyM,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.inkMuted),
            prefixIcon: Icon(icon, size: 18, color: AppColors.forestMid),
            suffix: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.creamSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                unit,
                style: AppTextStyles.bodyS.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            filled: true,
            fillColor: AppColors.cream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.creamSoft, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.creamSoft, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.forestMid, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Calculate button ─────────────────────────────────────────────────────────

class _CalcButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _CalcButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: loading
                ? LinearGradient(
                    colors: [
                      AppColors.amber.withValues(alpha: 0.6),
                      AppColors.terracotta.withValues(alpha: 0.6),
                    ],
                  )
                : AppGradients.amberWarm,
            borderRadius: BorderRadius.circular(16),
            boxShadow: loading ? [] : AppShadows.amberGlow,
          ),
          child: InkWell(
            onTap: loading ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Calculate',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Results section ──────────────────────────────────────────────────────────

class _ResultsSection extends StatelessWidget {
  final EconomicResult result;
  const _ResultsSection({required this.result});

  @override
  Widget build(BuildContext context) {
    final isProfit = result.netRevenue > 0;
    final isBreakEven = result.netRevenue == 0;

    final (String summaryEmoji, String summaryText, Color summaryColor) =
        isProfit
            ? (
                '✅',
                'This crop is profitable on your farm',
                AppColors.success,
              )
            : isBreakEven
                ? ('⚠️', 'This crop breaks even', AppColors.amber)
                : (
                    '❌',
                    'This crop is not profitable at these prices',
                    AppColors.error,
                  );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            const Text('📊', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Profit Analysis Results',
              style: AppTextStyles.headingS.copyWith(fontSize: 17),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Two big result cards
        Row(
          children: [
            Expanded(
              child: _RevenueCard(
                label: 'Gross Revenue',
                value: result.grossRevenue,
                unit: 'TND/ha',
                isPositive: result.grossRevenue > 0,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _RevenueCard(
                label: 'Net Revenue',
                value: result.netRevenue,
                unit: 'TND/ha',
                isPositive: isProfit,
                isNegative: result.netRevenue < 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Input recap
        _InputRecapCard(result: result),
        const SizedBox(height: 16),

        // Summary banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: summaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: summaryColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Text(summaryEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  summaryText,
                  style: AppTextStyles.bodyM.copyWith(
                    color: summaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final bool isPositive;
  final bool isNegative;

  const _RevenueCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.isPositive,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent =
        isNegative ? AppColors.error : AppColors.success;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.30), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              color: accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value.toStringAsFixed(0),
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: accent,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              color: accent.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputRecapCard extends StatelessWidget {
  final EconomicResult result;
  const _InputRecapCard({required this.result});

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
          Text(
            'Inputs used',
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RecapItem(
                  label: 'Cost',
                  value: result.cropCost.toStringAsFixed(0),
                  unit: 'TND/ha',
                ),
              ),
              Expanded(
                child: _RecapItem(
                  label: 'Yield',
                  value: result.cropYield.toStringAsFixed(1),
                  unit: 't/ha',
                ),
              ),
              Expanded(
                child: _RecapItem(
                  label: 'Price',
                  value: result.farmPrice.toStringAsFixed(2),
                  unit: 'TND/kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecapItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _RecapItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          style: AppTextStyles.label.copyWith(fontSize: 14),
        ),
        Text(
          unit,
          style: AppTextStyles.bodyS.copyWith(
            fontSize: 10,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}
