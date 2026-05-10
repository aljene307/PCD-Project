import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Forest greens
  static const Color forestDark = Color(0xFF1B4332);
  static const Color forestMid = Color(0xFF2D6A4F);
  static const Color forestLight = Color(0xFF52B788);

  // Earth tones
  static const Color amber = Color(0xFFF4A261);
  static const Color terracotta = Color(0xFFE76F51);

  // Neutrals
  static const Color cream = Color(0xFFFAF7F0);
  static const Color creamSoft = Color(0xFFF1ECE0);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color inkMuted = Color(0xFF6B6B6B);

  // Surfaces
  static const Color cardWhite = Colors.white;
  static const Color loadingBg = Color(0xFF0A1628);

  // States
  static const Color error = Color(0xFFD64545);
  static const Color success = Color(0xFF52B788);
}

class AppGradients {
  static const LinearGradient forest = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.forestDark, AppColors.forestMid],
  );

  static const LinearGradient forestRich = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14352A), AppColors.forestDark, AppColors.forestMid],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient amberWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.amber, AppColors.terracotta],
  );

  static const LinearGradient cropPlaceholder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF74C69D), Color(0xFF2D6A4F)],
  );

  static const LinearGradient loadingDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1628), Color(0xFF152844)],
  );
}

class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get amberGlow => [
    BoxShadow(
      color: AppColors.amber.withValues(alpha: 0.35),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

class AppTextStyles {
  static TextStyle headingXL = GoogleFonts.poppins(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static TextStyle headingL = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.2,
  );

  static TextStyle headingM = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.25,
  );

  static TextStyle headingS = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static TextStyle bodyL = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    height: 1.5,
  );

  static TextStyle bodyM = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    height: 1.5,
  );

  static TextStyle bodyS = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMuted,
    height: 1.4,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    letterSpacing: 0.2,
  );

  static TextStyle button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: const ColorScheme.light(
        primary: AppColors.forestMid,
        secondary: AppColors.amber,
        surface: AppColors.cardWhite,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.creamSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.creamSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.forestMid, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTextStyles.bodyM,
      ),
    );
  }
}
