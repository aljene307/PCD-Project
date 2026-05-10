import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/app_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../utils/page_transitions.dart';
import 'proceed_screen.dart';

class _SoilParam {
  final String label;
  final String attribute;
  final String isoMethod;
  final String unit;
  final TextEditingController controller = TextEditingController();

  _SoilParam({
    required this.label,
    required this.attribute,
    required this.isoMethod,
    required this.unit,
  });

  void dispose() => controller.dispose();
}

class ManualLabReportScreen extends StatefulWidget {
  const ManualLabReportScreen({super.key});

  @override
  State<ManualLabReportScreen> createState() => _ManualLabReportScreenState();
}

class _ManualLabReportScreenState extends State<ManualLabReportScreen> {
  bool _submitting = false;

  final _params = [
    _SoilParam(label: 'pH', attribute: 'pH', isoMethod: 'NF EN ISO 10390 (2022)', unit: '---'),
    _SoilParam(label: 'Conductivité', attribute: 'Conductivité', isoMethod: 'ISO 11265 (2025)', unit: 'mS/Cm'),
    _SoilParam(label: 'Salinité', attribute: 'Salinité', isoMethod: 'ISO 11265 (2025)', unit: '%'),
    _SoilParam(label: 'Humidité', attribute: 'Humidité', isoMethod: 'MA ISO 11465 (2025)', unit: '%'),
    _SoilParam(label: 'Matière sèche', attribute: 'Matière sèche', isoMethod: 'MA ISO 11465 (2025)', unit: '%'),
    _SoilParam(label: 'Matière Organique', attribute: 'Matière Organique', isoMethod: 'RODIER (2009)', unit: '%'),
    _SoilParam(label: 'Azote total', attribute: 'Azote total', isoMethod: 'ISO 13878 (2020)', unit: '%'),
    _SoilParam(label: 'Rapport C/N', attribute: 'Rapport C/N', isoMethod: 'RODIER (2009)', unit: '---'),
    _SoilParam(label: 'Souffre', attribute: 'Souffre', isoMethod: 'ISO 15178 (2000)', unit: '%'),
    _SoilParam(label: 'Taux de carbone', attribute: 'Taux de carbone', isoMethod: 'ISO 10694 (2020)', unit: '%'),
    _SoilParam(label: 'Carbonates de Calcium', attribute: 'Carbonates de Calcium', isoMethod: 'ISO 10693 (2021)', unit: '%'),
    _SoilParam(label: 'Phosphore', attribute: 'Phosphore', isoMethod: 'ISO 11047 (2023)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Potassium', attribute: 'Potassium', isoMethod: 'ISO 11047 (2023)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Magnésium', attribute: 'Magnésium', isoMethod: 'ISO 11047 (2023)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Calcium', attribute: 'Calcium', isoMethod: 'ISO 11047 (2023)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Manganèse', attribute: 'Manganèse', isoMethod: 'ISO 11047 (2023)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Bore', attribute: 'Bore', isoMethod: 'ISO 11047 (2023)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Cuivre', attribute: 'Cuivre', isoMethod: 'ISO 11047 (2023)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Fer', attribute: 'Fer', isoMethod: 'ISO 11047 (2023)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Zinc', attribute: 'Zinc', isoMethod: 'ISO 11047 (2023)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Molybdène', attribute: 'Molybdène', isoMethod: 'ISO 11047 (2023)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Calcium échangeable', attribute: 'Calcium échangeable', isoMethod: 'ISO 11260 (2018)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Magnésium échangeable', attribute: 'Magnésium échangeable', isoMethod: 'ISO 11260 (2018)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Potassium échangeable', attribute: 'Potassium échangeable', isoMethod: 'ISO 11260 (2018)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Phosphore échangeable', attribute: 'Phosphore échangeable', isoMethod: 'ISO 11260 (2018)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Sodium échangeable', attribute: 'Sodium échangeable', isoMethod: 'ISO 11260 (2018)', unit: 'g/Kg MS'),
    _SoilParam(label: 'Calcaire actif', attribute: 'Calcaire actif', isoMethod: 'NF X 31-106 (2002)', unit: '%'),
  ];

  @override
  void dispose() {
    for (final p in _params) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final measurements = _params
        .where((p) => p.controller.text.trim().isNotEmpty)
        .map((p) {
          final v = double.tryParse(p.controller.text.trim());
          if (v == null) return null;
          return LabMeasurement(
            attribute: p.attribute,
            isoMethod: p.isoMethod,
            unit: p.unit,
            value: v,
          );
        })
        .whereType<LabMeasurement>()
        .toList();

    if (measurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one measurement to continue.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.postLabReport(
        userId: AppSession.userId,
        measurements: measurements,
      );
      AppSession.labMeasurements = measurements;
      AppSession.labReportExists = false;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          FadeSlidePageRoute(page: const ProceedScreen()),
        );
      }
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              itemCount: _params.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ParamCard(param: _params[i])
                  .animate(delay: (i * 35).ms)
                  .fadeIn(duration: 320.ms)
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    duration: 320.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: CustomButton(
                label: _submitting ? 'Submitting…' : 'Submit Measurements',
                trailingIcon: _submitting ? null : Icons.check_rounded,
                onPressed: _submitting ? null : _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        22,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.forestRich,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.12),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enter Lab Measurements',
            style: AppTextStyles.headingL.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Fill in the values from your soil report. Leave blank if unavailable.',
            style: AppTextStyles.bodyM.copyWith(
              color: Colors.white.withValues(alpha: 0.70),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParamCard extends StatelessWidget {
  final _SoilParam param;
  const _ParamCard({required this.param});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  param.label,
                  style: AppTextStyles.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.forestMid.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        param.unit,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.forestMid,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      param.isoMethod,
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 96,
            child: TextField(
              controller: param.controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyM.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                hintText: '—',
                hintStyle: TextStyle(
                  color: AppColors.inkMuted.withValues(alpha: 0.35),
                  fontSize: 20,
                ),
                filled: true,
                fillColor: AppColors.creamSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.forestMid,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
