import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/app_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/leaf_backdrop.dart';
import '../utils/page_transitions.dart';
import 'proceed_screen.dart';

class UploadSoilReportScreen extends StatefulWidget {
  const UploadSoilReportScreen({super.key});

  @override
  State<UploadSoilReportScreen> createState() => _UploadSoilReportScreenState();
}

class _UploadSoilReportScreenState extends State<UploadSoilReportScreen> {
  String? _fileName;
  Uint8List? _fileBytes;
  bool _loading = false;
  String _statusText = 'Submit Report';

  Future<void> _pickFile() async {
    if (_loading) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    if (!mounted) return;
    setState(() {
      _fileName = file.name;
      _fileBytes = Uint8List.fromList(file.bytes!);
    });
  }

  Future<void> _submit() async {
    if (_fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file first')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _statusText = 'Extracting data…';
    });

    try {
      // Step 1: OCR extraction — best-effort, failure does not block navigation
      try {
        final measurements = await ApiService.postLabExtractFile(
          bytes: _fileBytes!,
          fileName: _fileName ?? 'soil_report.pdf',
        ).timeout(const Duration(seconds: 15));

        if (mounted) setState(() => _statusText = 'Saving report…');

        await ApiService.postLabReport(
          userId: AppSession.userId,
          measurements: measurements,
        );

        AppSession.labMeasurements = measurements;
      } catch (_) {
        // OCR unavailable — proceed without extracted measurements
      }

      AppSession.soilReportBytes = _fileBytes;
      AppSession.soilReportName = _fileName;

      if (mounted) {
        Navigator.of(context)
            .push(FadeSlidePageRoute(page: const ProceedScreen()));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _statusText = 'Submit Report';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _BackPill(onTap: () => Navigator.of(context).pop()),
                const Spacer(flex: 2),
                Text(
                  'Upload Soil Report',
                  style: AppTextStyles.headingL,
                ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(
                  begin: 0.15,
                  end: 0,
                  delay: 100.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
                const SizedBox(height: 10),
                Text(
                  'Upload your lab report PDF to get personalized crop recommendations',
                  style: AppTextStyles.bodyL.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w400,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                const Spacer(flex: 2),
                _UploadArea(
                  fileName: _fileName,
                  onTap: _pickFile,
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(
                  begin: 0.1,
                  end: 0,
                  delay: 300.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Only PDF files are accepted',
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.cream.withValues(alpha: 0.45),
                      letterSpacing: 0.3,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                const Spacer(flex: 3),
                CustomButton(
                  label: _statusText,
                  leadingIcon: _loading ? null : Icons.upload_file_rounded,
                  onPressed: _loading ? null : _submit,
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 500.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadArea extends StatelessWidget {
  final String? fileName;
  final VoidCallback onTap;

  const _UploadArea({required this.fileName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: fileName != null
              ? AppColors.forestLight.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.3),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
          decoration: BoxDecoration(
            color: fileName != null
                ? AppColors.forestMid.withValues(alpha: 0.25)
                : AppColors.forestDark.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: fileName != null
              ? _SelectedState(fileName: fileName!)
              : const _IdleState(),
        ),
      ),
    );
  }
}

class _IdleState extends StatelessWidget {
  const _IdleState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.picture_as_pdf_rounded,
          size: 52,
          color: Colors.white.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to upload your PDF report',
          style: AppTextStyles.bodyL.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SelectedState extends StatelessWidget {
  final String fileName;
  const _SelectedState({required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.forestLight.withValues(alpha: 0.2),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 36,
            color: AppColors.forestLight,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          fileName,
          style: AppTextStyles.bodyM.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          'Tap to change file',
          style: AppTextStyles.bodyS.copyWith(
            color: AppColors.forestLight.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _BackPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BackPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashLength = 9.0;
    const gapLength = 6.0;
    const radius = 20.0;

    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(radius),
        ),
      );

    final dashed = Path();
    for (final metric in outline.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        dashed.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }

    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color;
}
