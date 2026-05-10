import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FormCard extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FormCard({
    super.key,
    required this.label,
    required this.child,
    this.icon,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.forestMid.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.forestDark),
                ),
                const SizedBox(width: 10),
              ],
              Text(label, style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class StepHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  const StepHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              if (onBack != null)
                _CircleIconButton(icon: Icons.arrow_back, onTap: onBack!),
              if (onBack != null) const SizedBox(width: 12),
              Text(
                'Step $currentStep of $totalSteps',
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.cream.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: AppGradients.amberWarm,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: AppTextStyles.headingL.copyWith(color: Colors.white),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.cream.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
