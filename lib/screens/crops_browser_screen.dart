import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import 'crop_info_detail_screen.dart';

// Session-level cache — avoids re-fetching when scrolling back and forth.
final Map<String, String?> _wikiImageCache = {};

// Crops whose common name doesn't map to the right Wikipedia article.
const Map<String, String> _wikiQueryOverrides = {
  'gram': 'chickpea',
  'groundnut': 'peanut',
  'rape': 'rapeseed',
  'white yam': 'Dioscorea rotundata',
};

class CropsBrowserScreen extends StatefulWidget {
  const CropsBrowserScreen({super.key});

  @override
  State<CropsBrowserScreen> createState() => _CropsBrowserScreenState();
}

class _CropsBrowserScreenState extends State<CropsBrowserScreen> {
  List<CropInfoData>? _crops;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    setState(() {
      _error = null;
      _crops = null;
    });
    try {
      final crops = await ApiService.getCropsInfo();
      crops.sort((a, b) => a.displayName.compareTo(b.displayName));
      if (!mounted) return;
      setState(() => _crops = crops);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  List<CropInfoData> get _filtered {
    final crops = _crops ?? [];
    if (_search.isEmpty) return crops;
    final q = _search.toLowerCase();
    return crops.where((c) => c.commonName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _BrowserHeader(
            onSearch: (v) => setState(() => _search = v),
          ),
        ),
        if (_crops == null && _error == null) ...[
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.amber,
                strokeWidth: 3,
              ),
            ),
          ),
        ] else if (_error != null) ...[
          SliverFillRemaining(
            child: _ErrorState(error: _error!, onRetry: _loadCrops),
          ),
        ] else ...[
          // Count row
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'All Crops',
                    style: AppTextStyles.headingM.copyWith(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.creamSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filtered.length}',
                      style: AppTextStyles.bodyS.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'found',
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty) ...[
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: AppColors.inkMuted.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No crops match "$_search"',
                      style: AppTextStyles.bodyM
                          .copyWith(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final crop = filtered[index];
                    return _ApiCropTile(
                      crop: crop,
                      onTap: () => Navigator.of(context).push(
                        FadeSlidePageRoute(
                          page: CropInfoDetailScreen(crop: crop),
                        ),
                      ),
                    )
                        .animate(delay: (index * 40).ms)
                        .fadeIn(duration: 320.ms)
                        .slideY(
                          begin: 0.07,
                          end: 0,
                          duration: 320.ms,
                          curve: Curves.easeOutCubic,
                        );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _BrowserHeader extends StatelessWidget {
  final ValueChanged<String> onSearch;
  const _BrowserHeader({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 18,
        20,
        22,
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
          Text(
            'Explore Crops',
            style: AppTextStyles.headingL.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 4),
          Text(
            'Browse the global crop database',
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.cream.withValues(alpha: 0.78),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.soft,
            ),
            child: TextField(
              onChanged: onSearch,
              style: AppTextStyles.bodyM,
              decoration: InputDecoration(
                hintText: 'Search crops…',
                hintStyle: AppTextStyles.bodyM.copyWith(
                  color: AppColors.inkMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.forestMid,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Crop tile ────────────────────────────────────────────────────────────────

class _ApiCropTile extends StatefulWidget {
  final CropInfoData crop;
  final VoidCallback onTap;

  const _ApiCropTile({required this.crop, required this.onTap});

  @override
  State<_ApiCropTile> createState() => _ApiCropTileState();
}

class _ApiCropTileState extends State<_ApiCropTile> {
  String? _imageUrl;
  bool _imageFetched = false;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  Future<void> _fetchImage() async {
    final name = widget.crop.commonName;

    // Serve from cache immediately if already known.
    if (_wikiImageCache.containsKey(name)) {
      if (mounted) {
        setState(() {
          _imageUrl = _wikiImageCache[name];
          _imageFetched = true;
        });
      }
      return;
    }

    // Use override title when the common name doesn't match the Wikipedia article.
    final wikiTitle = _wikiQueryOverrides[name] ?? name;

    try {
      final uri = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(wikiTitle)}',
      );
      final response = await http.get(
        uri,
        headers: {'accept': 'application/json'},
      );
      String? url;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final thumbnail = data['thumbnail'] as Map<String, dynamic>?;
        url = thumbnail?['source'] as String?;
      }
      _wikiImageCache[name] = url;
      if (mounted) setState(() { _imageUrl = url; _imageFetched = true; });
    } catch (_) {
      _wikiImageCache[name] = null;
      if (mounted) setState(() => _imageFetched = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.crop.primaryCategory;
    final gradient = cropInfoGradient(primary);
    final emoji = cropInfoEmoji(primary);
    final label = primary.isEmpty
        ? 'Other'
        : '${primary[0].toUpperCase()}${primary.substring(1)}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Image area ───────────────────────────────────────────
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photo or gradient+emoji fallback
                      if (_imageUrl != null)
                        Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _EmojiPlaceholder(
                            gradient: gradient,
                            emoji: emoji,
                          ),
                        )
                      else
                        _EmojiPlaceholder(
                          gradient: gradient,
                          emoji: emoji,
                        ),

                      // Subtle bottom gradient so badge stays readable
                      // over photos that have a light bottom edge
                      if (_imageUrl != null)
                        const Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 44,
                          child: _BottomFade(),
                        ),

                      // Category badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: AppTextStyles.bodyS.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Loading shimmer overlay while fetching
                      if (!_imageFetched)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.08),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Name footer ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.crop.displayName,
                          style:
                              AppTextStyles.headingS.copyWith(fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
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

// ─── Small helpers ────────────────────────────────────────────────────────────

class _EmojiPlaceholder extends StatelessWidget {
  final LinearGradient gradient;
  final String emoji;
  const _EmojiPlaceholder({required this.gradient, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 64)),
      ),
    );
  }
}

class _BottomFade extends StatelessWidget {
  const _BottomFade();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.22),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.inkMuted.withValues(alpha: 0.40),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppGradients.amberWarm,
                  borderRadius: BorderRadius.circular(14),
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
}
