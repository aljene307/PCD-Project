import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/app_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import 'ranks_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  static const _steps = [
    'Processing soil composition',
    'Matching climate patterns',
    'Calculating yield potential',
    'Generating recommendations',
  ];

  late final AnimationController _ringCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _progressCtrl;
  int _currentStep = 0;
  Timer? _stepTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..forward();

    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1000), (t) {
      if (!mounted) return;
      if (_currentStep < _steps.length) {
        setState(() => _currentStep++);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final crops = AppSession.labReportExists
          ? await ApiService.getReportCropRecommendations(AppSession.userId)
          : await ApiService.getCropRecommendations(AppSession.userId);

      if (!mounted) return;
      AppSession.hasCompletedOnboarding = true;
      Navigator.of(context).pushReplacement(
        FadeOnlyPageRoute(page: RanksScreen(crops: crops)),
      );
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString()
          .replaceFirst('ClientException: ', '')
          .replaceFirst('Exception: ', '');
      setState(() => _error = raw);
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _currentStep = 0;
    });
    _progressCtrl.reset();
    _progressCtrl.forward();
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1000), (t) {
      if (!mounted) return;
      if (_currentStep < _steps.length) {
        setState(() => _currentStep++);
      } else {
        t.cancel();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loadingBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.loadingDark),
        child: SafeArea(
          child: _error != null ? _buildErrorState() : _buildLoadingState(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: Colors.white.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _retry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: AppGradients.amberWarm,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.amberGlow,
                ),
                child: Text(
                  'Retry',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          _AnimatedLogo(ringCtrl: _ringCtrl, pulseCtrl: _pulseCtrl),
          const SizedBox(height: 38),
          Text(
            'Analyzing Your Soil Data...',
            style: AppTextStyles.headingM.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Our model is matching your inputs to thousands of growth profiles.',
            style: AppTextStyles.bodyS.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          _StepList(currentStep: _currentStep, steps: _steps),
          const Spacer(flex: 3),
          _ProgressBar(controller: _progressCtrl),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  final AnimationController ringCtrl;
  final AnimationController pulseCtrl;

  const _AnimatedLogo({required this.ringCtrl, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, __) {
              final scale = 0.95 + pulseCtrl.value * 0.15;
              return Container(
                width: 140 * scale,
                height: 140 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.amber.withValues(
                        alpha: 0.20 - pulseCtrl.value * 0.08,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: ringCtrl,
            builder: (_, __) {
              return Transform.rotate(
                angle: ringCtrl.value * 6.283,
                child: CustomPaint(
                  size: const Size(120, 120),
                  painter: _RingPainter(),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, __) {
              final scale = 1 + pulseCtrl.value * 0.08;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.forestLight, AppColors.forestMid],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forestLight.withValues(alpha: 0.5),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.amber.withValues(alpha: 0),
          AppColors.amber,
          AppColors.terracotta,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.4,
      3.4,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => false;
}

class _StepList extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  const _StepList({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++)
          if (i < currentStep)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: AppTextStyles.bodyM.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideX(
              begin: -0.05,
              end: 0,
              duration: 350.ms,
              curve: Curves.easeOutCubic,
            ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AnimationController controller;
  const _ProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 6,
        color: Colors.white.withValues(alpha: 0.08),
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: controller.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppGradients.amberWarm,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
