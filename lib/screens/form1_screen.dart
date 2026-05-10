import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/app_session.dart';
import '../data/coord_history.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/form_card.dart';
import '../utils/page_transitions.dart';
import 'form2_screen.dart';

class Form1Screen extends StatefulWidget {
  const Form1Screen({super.key});

  @override
  State<Form1Screen> createState() => _Form1ScreenState();
}

class _Form1ScreenState extends State<Form1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  final _latLink = LayerLink();
  final _latFocus = FocusNode();
  final _lonFocus = FocusNode();

  static const _elevationOptions = ['Low', 'Intermediate', 'High'];
  static const _waterOptions = ['Rainfed', 'Irrigated'];
  static const _irrigationTypes = [
    (value: 'drip', label: 'Drip'),
    (value: 'sprinkler', label: 'Sprinkler'),
    (value: 'gravity', label: 'Gravity'),
  ];

  String? _elevation;
  String? _water;
  String? _irrigationType;
  bool _loading = false;

  List<({double lat, double lon})> _recentCoords = [];
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _latFocus.addListener(_onFocusChange);
    _lonFocus.addListener(_onFocusChange);
    CoordHistory.load().then((list) {
      if (mounted) setState(() => _recentCoords = list);
    });
  }

  @override
  void dispose() {
    _latFocus.removeListener(_onFocusChange);
    _lonFocus.removeListener(_onFocusChange);
    _latFocus.dispose();
    _lonFocus.dispose();
    _hideOverlay();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  // ── Overlay management ────────────────────────────────────────────────────

  void _onFocusChange() {
    if (_latFocus.hasFocus || _lonFocus.hasFocus) {
      if (_recentCoords.isNotEmpty) _showOverlay();
    } else {
      // Short delay so a tap on an overlay row registers before it disappears.
      Future.delayed(const Duration(milliseconds: 120), _hideOverlay);
    }
  }

  void _showOverlay() {
    _hideOverlay();
    if (_recentCoords.isEmpty) return;
    final fieldWidth = MediaQuery.of(context).size.width - 40;
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (_) => CompositedTransformFollower(
        link: _latLink,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 6),
        child: Align(
          alignment: Alignment.topLeft,
          child: _RecentDropdown(
            width: fieldWidth,
            items: _recentCoords,
            onSelect: (lat, lon) {
              _latCtrl.text = '$lat';
              _lonCtrl.text = '$lon';
              _hideOverlay();
              _latFocus.unfocus();
              _lonFocus.unfocus();
            },
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ── Form logic ────────────────────────────────────────────────────────────

  void _onWaterChanged(String? v) {
    setState(() {
      _water = v;
      if (v != 'Irrigated') _irrigationType = null;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());

    if (lat == null || lon == null) {
      _showSnack('Please enter valid coordinates.');
      return;
    }
    if (_elevation == null) {
      _showSnack('Please select an elevation level.');
      return;
    }
    if (_water == null) {
      _showSnack('Please select a water supply.');
      return;
    }
    if (_water == 'Irrigated' && _irrigationType == null) {
      _showSnack('Please select an irrigation type.');
      return;
    }

    setState(() => _loading = true);
    try {
      // Await with timeout so the backend registers the data before Form2
      // requests questions — but navigate regardless of success or failure.
      try {
        await ApiService.postSubmitInput(
          userId: AppSession.userId,
          latitude: lat,
          longitude: lon,
          inputLevel: _elevation!.toLowerCase(),
          waterSupply: _water!.toLowerCase(),
          irrigationType: _irrigationType,
          labMeasurements: AppSession.labMeasurements,
        ).timeout(const Duration(seconds: 10));
      } catch (_) {}
      await CoordHistory.save(lat, lon);
      if (mounted) {
        Navigator.of(context)
            .push(FadeSlidePageRoute(page: const Form2Screen()));
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          StepHeader(
            currentStep: 1,
            totalSteps: 2,
            title: 'Your Farm Details',
            subtitle: 'Share your location and farm setup',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Latitude — wrapped in CompositedTransformTarget so the
                    // overlay can position itself relative to this field.
                    CompositedTransformTarget(
                      link: _latLink,
                      child: FormCard(
                        label: 'Latitude',
                        icon: Icons.place_rounded,
                        child: TextFormField(
                          controller: _latCtrl,
                          focusNode: _latFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\-\d\.]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            hintText: '-90.00 to 90.00',
                            prefixIcon: Icon(
                              Icons.my_location_rounded,
                              size: 18,
                              color: AppColors.forestMid,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 14),
                    FormCard(
                      label: 'Longitude',
                      icon: Icons.place_rounded,
                      child: TextFormField(
                        controller: _lonCtrl,
                        focusNode: _lonFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\-\d\.]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          hintText: '-180.00 to 180.00',
                          prefixIcon: Icon(
                            Icons.explore_rounded,
                            size: 18,
                            color: AppColors.forestMid,
                          ),
                        ),
                      ),
                    ).animate(delay: 80.ms).fadeIn(duration: 400.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 14),
                    FormCard(
                      label: 'Farm Elevation Level',
                      icon: Icons.terrain_rounded,
                      child: _AppDropdown(
                        value: _elevation,
                        hint: 'Select elevation',
                        items: _elevationOptions,
                        errorText: null,
                        onChanged: (v) => setState(() => _elevation = v),
                      ),
                    ).animate(delay: 160.ms).fadeIn(duration: 400.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 14),
                    FormCard(
                      label: 'Farm Water Supply',
                      icon: Icons.water_drop_rounded,
                      child: _AppDropdown(
                        value: _water,
                        hint: 'Select water source',
                        items: _waterOptions,
                        errorText: null,
                        onChanged: _onWaterChanged,
                      ),
                    ).animate(delay: 240.ms).fadeIn(duration: 400.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    if (_water == 'Irrigated') ...[
                      const SizedBox(height: 14),
                      FormCard(
                        label: 'Irrigation Type',
                        icon: Icons.water_rounded,
                        child: DropdownButtonFormField<String>(
                          value: _irrigationType,
                          isExpanded: true,
                          hint: Text(
                            'Select irrigation type',
                            style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.forestMid,
                          ),
                          style: AppTextStyles.bodyM,
                          borderRadius: BorderRadius.circular(14),
                          decoration:
                              const InputDecoration(errorText: null),
                          items: _irrigationTypes
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t.value,
                                  child: Text(t.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _irrigationType = v),
                        ),
                      ).animate().fadeIn(duration: 350.ms).slideY(
                            begin: 0.12,
                            end: 0,
                            duration: 350.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: CustomButton(
                label: 'Next',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: _loading ? null : _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent coordinates overlay dropdown ─────────────────────────────────────

class _RecentDropdown extends StatelessWidget {
  final double width;
  final List<({double lat, double lon})> items;
  final void Function(double lat, double lon) onSelect;

  const _RecentDropdown({
    required this.width,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(14),
      shadowColor: Colors.black.withValues(alpha: 0.14),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.creamSoft,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 14,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Recent coordinates',
                    style: AppTextStyles.bodyS.copyWith(
                      fontSize: 11,
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1ECE0)),
            for (int i = 0; i < items.length; i++) ...[
              InkWell(
                onTap: () => onSelect(items[i].lat, items[i].lon),
                borderRadius: i == items.length - 1
                    ? const BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      )
                    : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.forestMid.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.place_rounded,
                          size: 14,
                          color: AppColors.forestMid,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Lat ${items[i].lat}   Lon ${items[i].lon}',
                          style: AppTextStyles.bodyM.copyWith(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.north_west_rounded,
                        size: 13,
                        color: AppColors.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Divider(
                  height: 1,
                  indent: 52,
                  endIndent: 14,
                  color: Color(0xFFF1ECE0),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Shared dropdown widget ───────────────────────────────────────────────────

class _AppDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  const _AppDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      hint: Text(
        hint,
        style: AppTextStyles.bodyM.copyWith(color: AppColors.inkMuted),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.forestMid,
      ),
      style: AppTextStyles.bodyM,
      borderRadius: BorderRadius.circular(14),
      decoration: InputDecoration(errorText: errorText),
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
