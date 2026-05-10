import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum SortMetric { suitability, yield_, regionalGrowth }

extension SortMetricLabel on SortMetric {
  String get label => switch (this) {
    SortMetric.suitability => 'Suitability',
    SortMetric.yield_ => 'Yield',
    SortMetric.regionalGrowth => 'Regional Typical Growth',
  };
}

class CropData {
  final String name;
  final String emoji;
  final int suitability; // %
  final double yield_; // t/ha
  final int profit; // $/ha
  final String regionGrowth;

  const CropData({
    required this.name,
    required this.emoji,
    required this.suitability,
    required this.yield_,
    required this.profit,
    required this.regionGrowth,
  });
}

/// Clean horizontal crop card — no per-card dropdown.
/// Metrics shown as a 2×2 grid: [Suitability | Yield] / [Profit | Region]
class CropCard extends StatelessWidget {
  final CropData crop;
  final int rank;
  final VoidCallback onView;
  final VoidCallback onCardTap;

  const CropCard({
    super.key,
    required this.crop,
    required this.rank,
    required this.onView,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onCardTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.card,
          ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Crop image with rank badge ──────────────────────────────────
            _CropImage(emoji: crop.emoji, rank: rank, cropName: crop.name),
            const SizedBox(width: 14),
            // ── Text content ────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop name — never truncated
                  Text(
                    crop.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 2×2 metric grid
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Chip(
                              emoji: '🌿',
                              label: 'Suitability',
                              value: '${crop.suitability}%',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _Chip(
                              emoji: '🌾',
                              label: 'Yield',
                              value: '${crop.yield_.toStringAsFixed(1)} t/ha',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _Chip(
                              emoji: '💰',
                              label: 'Profit',
                              value: '\$${crop.profit}/ha',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _Chip(
                              emoji: '📍',
                              label: 'Region',
                              value: crop.regionGrowth,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // View Details link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: onView,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.amber,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: AppColors.amber,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

/// 90×90 crop image tile with amber rank badge top-left.
class _CropImage extends StatelessWidget {
  final String emoji;
  final int rank;
  final String cropName;
  const _CropImage({
    required this.emoji,
    required this.rank,
    required this.cropName,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: AppGradients.cropPlaceholder,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Hero(
                tag: 'crop-$cropName',
                flightShuttleBuilder: (_, __, ___, ____, _____) => Material(
                  type: MaterialType.transparency,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 42),
                  ),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 42)),
              ),
            ),
          ),
          Positioned(
            top: -6,
            left: -6,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact metric chip that fills its parent width.
class _Chip extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _Chip({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EE), // very light green
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
