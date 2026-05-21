import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/app_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/leaf_backdrop.dart';
import '../utils/page_transitions.dart';
import 'proceed_screen.dart';
import 'upload_soil_report_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _loading = false;

  Future<void> _handleChoice(bool labReportExists) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      await ApiService.postOnboarding(
        userId: AppSession.userId,
        labReportExists: labReportExists,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Non-blocking — continue navigation even if the call fails or times out.
    }

    AppSession.labReportExists = labReportExists;
    if (mounted) {
      setState(() => _loading = false);
      final page = labReportExists
          ? const UploadSoilReportScreen()
          : const ProceedScreen();
      Navigator.of(context).push(FadeSlidePageRoute(page: page));
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
              children: [
                const Spacer(flex: 2),
                _Logo()
                    .animate()
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 600.ms),
                const SizedBox(height: 24),
                Text(
                  'ARDHI',
                  style: AppTextStyles.headingXL.copyWith(fontSize: 44, letterSpacing: 4),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 250.ms, duration: 600.ms).slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 250.ms,
                  duration: 600.ms,
                  curve: Curves.easeOutCubic,
                ),
                const SizedBox(height: 10),
                Text(
                  'Smart Farming Starts Here',
                  style: AppTextStyles.bodyL.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 450.ms, duration: 600.ms),
                const Spacer(flex: 3),
                CustomButton(
                  label: 'Submit a Soil Report',
                  leadingIcon: Icons.layers_rounded,
                  onPressed: _loading ? null : () => _handleChoice(true),
                ).animate().fadeIn(delay: 700.ms, duration: 500.ms).slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 700.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: 'Explore Global Database',
                  leadingIcon: Icons.public_rounded,
                  variant: ButtonVariant.outlinedLight,
                  onPressed: _loading ? null : () => _handleChoice(false),
                ).animate().fadeIn(delay: 850.ms, duration: 500.ms).slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 850.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
                const Spacer(flex: 1),
                Text(
                  'Tailored for Tunisian farmers',
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.55),
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 1100.ms, duration: 600.ms),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.amber.withValues(alpha: 0.25),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.forestDark.withValues(alpha: 0.4),
            border: Border.all(
              color: AppColors.amber.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: AppShadows.amberGlow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(42),
            child: Padding(
              padding: const EdgeInsets.all(12.0), 
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
