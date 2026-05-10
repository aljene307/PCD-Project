import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ButtonVariant { filledAmber, outlinedLight, filledGreen }

class CustomButton extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool fullWidth;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.onPressed,
    this.variant = ButtonVariant.filledAmber,
    this.fullWidth = true,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    final (Color bg, Color fg, BorderSide border, List<BoxShadow> shadows) =
        switch (variant) {
          ButtonVariant.filledAmber => (
            AppColors.amber,
            const Color(0xFF1A1A1A),
            BorderSide.none,
            disabled ? <BoxShadow>[] : AppShadows.amberGlow,
          ),
          ButtonVariant.outlinedLight => (
            Colors.transparent,
            Colors.white,
            const BorderSide(color: Colors.white, width: 1.5),
            <BoxShadow>[],
          ),
          ButtonVariant.filledGreen => (
            AppColors.forestMid,
            Colors.white,
            BorderSide.none,
            disabled ? <BoxShadow>[] : AppShadows.card,
          ),
        };

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: shadows,
        ),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.fromBorderSide(border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, color: fg, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: AppTextStyles.button.copyWith(color: fg),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, color: fg, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
