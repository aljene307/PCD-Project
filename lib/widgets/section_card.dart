import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A white card with a colored vertical accent bar on the left.
/// Used throughout detail screens for section grouping.
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.accent = AppColors.forestMid,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 17, color: accent),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.headingS.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    child,
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

/// A simple bullet list helper for placeholder content.
class BulletList extends StatelessWidget {
  final List<String> items;
  final Color color;
  const BulletList({super.key, required this.items, this.color = AppColors.amber});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: Text(t, style: AppTextStyles.bodyM)),
              ],
            ),
          ),
      ],
    );
  }
}
