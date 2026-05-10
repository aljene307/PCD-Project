import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ecological_needs_section.dart';

// ─── Shared helpers (also imported by crops_browser_screen) ──────────────────

String cropInfoEmoji(String? category) {
  if (category == null || category.isEmpty) return '🌿';
  final c = category.toLowerCase();
  if (c.contains('cereal') || c.contains('grain')) return '🌾';
  if (c.contains('vegetable')) return '🥦';
  if (c.contains('fruit')) return '🍎';
  if (c.contains('root') || c.contains('tuber')) return '🌰';
  if (c.contains('pulse') || c.contains('legume')) return '🫘';
  if (c.contains('medicinal') || c.contains('drug') || c.contains('poison')) {
    return '💊';
  }
  if (c.contains('oil')) return '🫙';
  if (c.contains('spice') || c.contains('condiment')) return '🌶️';
  if (c.contains('sugar')) return '🍬';
  if (c.contains('fiber') || c.contains('material') || c.contains('timber')) {
    return '🌴';
  }
  if (c.contains('forage') || c.contains('pasture') || c.contains('environmental')) {
    return '🌿';
  }
  return '🌿';
}

LinearGradient cropInfoGradient(String? category) {
  if (category == null || category.isEmpty) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF74C69D), Color(0xFF2D6A4F)],
    );
  }
  final c = category.toLowerCase();
  if (c.contains('cereal') || c.contains('grain')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD4A017), Color(0xFF9A7318)],
    );
  }
  if (c.contains('vegetable')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF52B788), Color(0xFF1B5E3B)],
    );
  }
  if (c.contains('fruit')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE76F51), Color(0xFFBF4E30)],
    );
  }
  if (c.contains('root') || c.contains('tuber')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB07745), Color(0xFF7B4F2E)],
    );
  }
  if (c.contains('pulse') || c.contains('legume')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9B72CF), Color(0xFF5E3B8C)],
    );
  }
  if (c.contains('medicinal') || c.contains('drug') || c.contains('poison')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4ECDC4), Color(0xFF1A7A73)],
    );
  }
  if (c.contains('oil')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD4A017), Color(0xFF8B6914)],
    );
  }
  if (c.contains('spice') || c.contains('condiment')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE63946), Color(0xFF9D0208)],
    );
  }
  if (c.contains('fiber') || c.contains('material') || c.contains('timber')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF457B9D), Color(0xFF1D3557)],
    );
  }
  // forage / pasture / environmental / default green
  return const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF74C69D), Color(0xFF2D6A4F)],
  );
}

String _cap(String? s) {
  if (s == null || s.isEmpty) return 'N/A';
  return '${s[0].toUpperCase()}${s.substring(1)}';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class CropInfoDetailScreen extends StatefulWidget {
  final CropInfoData crop;
  const CropInfoDetailScreen({super.key, required this.crop});

  @override
  State<CropInfoDetailScreen> createState() => _CropInfoDetailScreenState();
}

class _CropInfoDetailScreenState extends State<CropInfoDetailScreen> {
  bool _notesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;
    final gradient = cropInfoGradient(crop.primaryCategory);
    final emoji = cropInfoEmoji(crop.primaryCategory);
    final categoryLabel = _cap(crop.primaryCategory.isEmpty ? null : crop.primaryCategory);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DetailHeader(
              crop: crop,
              gradient: gradient,
              emoji: emoji,
              categoryLabel: categoryLabel,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(crop: crop)
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(
                        begin: 0.04,
                        end: 0,
                        duration: 350.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  if (crop.plantAttributes != null) ...[
                    const SizedBox(height: 16),
                    _AttributesBadge(attributes: crop.plantAttributes!)
                        .animate(delay: 80.ms)
                        .fadeIn(duration: 350.ms),
                  ],
                  const SizedBox(height: 16),
                  _NotesCard(
                    notes: crop.notes,
                    expanded: _notesExpanded,
                    onToggle: () =>
                        setState(() => _notesExpanded = !_notesExpanded),
                  ).animate(delay: 120.ms).fadeIn(duration: 350.ms),
                  EcologicalNeedsSection(cropName: crop.commonName)
                      .animate(delay: 180.ms)
                      .fadeIn(duration: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  final CropInfoData crop;
  final LinearGradient gradient;
  final String emoji;
  final String categoryLabel;

  const _DetailHeader({
    required this.crop,
    required this.gradient,
    required this.emoji,
    required this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        28,
      ),
      decoration: BoxDecoration(gradient: gradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.18),
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
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 12),
          Text(
            crop.displayName,
            style: AppTextStyles.headingXL.copyWith(fontSize: 32, height: 1.1),
          ),
          if (crop.scientificName != null &&
              crop.scientificName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              crop.scientificName!,
              style: AppTextStyles.bodyM.copyWith(
                color: Colors.white.withValues(alpha: 0.80),
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              categoryLabel,
              style: AppTextStyles.bodyS.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info row (4 small cards) ─────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final CropInfoData crop;
  const _InfoRow({required this.crop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            label: 'Life Form',
            value: _cap(crop.lifeForm),
            icon: Icons.grass_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoCard(
            label: 'Life Span',
            value: _cap(crop.lifeSpan),
            icon: Icons.calendar_today_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoCard(
            label: 'Habit',
            value: _cap(crop.habit),
            icon: Icons.straighten_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoCard(
            label: 'Physiology',
            value: _cap(crop.physiology),
            icon: Icons.eco_rounded,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.forestMid),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.label.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 9,
              color: AppColors.inkMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Plant attributes badge ───────────────────────────────────────────────────

class _AttributesBadge extends StatelessWidget {
  final String attributes;
  const _AttributesBadge({required this.attributes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, size: 16, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _cap(attributes),
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.amber,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notes card ───────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  final String? notes;
  final bool expanded;
  final VoidCallback onToggle;

  const _NotesCard({
    required this.notes,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const previewLength = 300;
    final hasNotes = notes != null && notes!.isNotEmpty;
    final isLong = hasNotes && notes!.length > previewLength;
    final displayText = hasNotes
        ? (expanded || !isLong
            ? notes!
            : '${notes!.substring(0, previewLength)}...')
        : 'No description available.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
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
                  Icons.info_outline_rounded,
                  size: 19,
                  color: AppColors.forestMid,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'About this crop',
                style: AppTextStyles.headingS.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayText,
            style: AppTextStyles.bodyM.copyWith(
              fontSize: 13,
              color: hasNotes ? AppColors.ink : AppColors.inkMuted,
              height: 1.65,
            ),
          ),
          if (isLong) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onToggle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expanded ? 'Show less' : 'Read more',
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.amber,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
