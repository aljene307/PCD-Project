import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/leaf_backdrop.dart';
import '../utils/page_transitions.dart';
import 'form1_screen.dart';

class ProceedScreen extends StatelessWidget {
  const ProceedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _BackPill(onTap: () => Navigator.of(context).pop()),
                const Spacer(flex: 1),
                _FarmIllustration().animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.easeOutCubic,
                ),
                const SizedBox(height: 28),
                Text(
                  'Ready to Begin?',
                  style: AppTextStyles.headingXL,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(
                  begin: 0.15,
                  end: 0,
                  delay: 200.ms,
                  duration: 500.ms,
                ),
                const SizedBox(height: 14),
                Text(
                  "Let's get to know your farm. We'll analyze your soil and recommend the best crops for your land.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyL.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.85),
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
                const Spacer(flex: 2),
                CustomButton(
                  label: 'Proceed',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: () => Navigator.of(context).push(
                    FadeSlidePageRoute(page: const Form1Screen()),
                  ),
                ).animate().fadeIn(delay: 550.ms, duration: 500.ms).slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 550.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
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
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _FarmIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.forestLight.withValues(alpha: 0.35),
              AppColors.forestDark.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.forestDark.withValues(alpha: 0.55),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 36,
                  child: Icon(
                    Icons.terrain_rounded,
                    size: 90,
                    color: AppColors.forestLight.withValues(alpha: 0.6),
                  ),
                ),
                const Positioned(
                  top: 36,
                  child: Icon(
                    Icons.wb_sunny_rounded,
                    size: 36,
                    color: AppColors.amber,
                  ),
                ),
                Positioned(
                  bottom: 56,
                  child: Icon(
                    Icons.agriculture_rounded,
                    size: 50,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
