import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlaceholderSectionScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const PlaceholderSectionScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headingL.copyWith(color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(
                'Coming soon',
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.forestMid.withValues(alpha: 0.08),
                        ),
                        child: Icon(icon, size: 44, color: AppColors.forestMid),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        description,
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.inkMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // TODO: Connect to backend / build out this section.
                      Text(
                        'TODO • build this section',
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.terracotta,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
