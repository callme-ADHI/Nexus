import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════════════════════════
// COLOUR TOKENS — pitch black background, white text, blue & red accents
// ════════════════════════════════════════════════════════════════════════════
abstract final class AppColors {
  // ── Core backgrounds ──────────────────────────────────────────────────────
  static const background  = Color(0xFF000000); // true pitch black
  static const surface     = Color(0xFF0A0A0A); // cards, sheets
  static const surfaceAlt  = Color(0xFF111111); // inputs, chips
  static const border      = Color(0xFF1E1E1E); // subtle borders

  // ── Text ─────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFFFFFFF); // pure white
  static const textSecondary = Color(0xFF555555); // subdued

  // ── Blue accent ───────────────────────────────────────────────────────────
  static const accentBlue      = Color(0xFF2563EB); // primary CTA blue
  static const accentBlueDim   = Color(0xFF1E3A5F); // dimmed/bg usage
  static const accentBlueGlow  = Color(0x302563EB); // glow / tint

  // ── Red accent (warnings, errors, urgency) ────────────────────────────────
  static const accentRed     = Color(0xFFE74C3C); // primary red
  static const accentRedDim  = Color(0xFF7B2020); // dimmed
  static const accentRedGlow = Color(0x30E74C3C);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const warning = Color(0xFFF39C12);
  static const success = Color(0xFF27AE60);
  static const error   = accentRed;

  // ── Nav bubble glass ─────────────────────────────────────────────────────
  static const glassBg     = Color(0xCC050505);
  static const glassBorder = Color(0x40FFFFFF);
  static const bubbleGlow  = Color(0x202563EB);

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const warningBg = Color(0x20F39C12);

  // ── Node status backgrounds ───────────────────────────────────────────────
  static const nodeBlocked    = Color(0xFF050505);
  static const nodeNotStarted = Color(0xFF0A0A0A);
  static const nodeInProgress = Color(0xFF071020);
  static const nodeCompleted  = Color(0xFF051510);
  static const nodeOverdue    = Color(0xFF150505);

  // ── Node status borders ───────────────────────────────────────────────────
  static const nodeBorderBlocked    = Color(0xFF222222);
  static const nodeBorderNotStarted = Color(0xFF333333);
  static const nodeBorderInProgress = Color(0xFF2563EB);
  static const nodeBorderCompleted  = Color(0xFF27AE60);
  static const nodeBorderOverdue    = Color(0xFFE74C3C);

  // ── Progress ring track ───────────────────────────────────────────────────
  static const progressTrack = Color(0xFF1A1A1A);

  // ── Backwards compat aliases ──────────────────────────────────────────────
  static const accentPrimary   = accentBlue;
  static const accentSecondary = accentBlue;
  static const accentGlow      = accentBlueGlow;

  // ── 8-color node palette ──────────────────────────────────────────────────
  static const List<Color> nodeAccents = [
    Color(0xFF777777), // 0 grey
    Color(0xFF27AE60), // 1 green
    Color(0xFFE74C3C), // 2 red
    Color(0xFFF39C12), // 3 amber
    Color(0xFF2563EB), // 4 blue
    Color(0xFFE67E22), // 5 orange
    Color(0xFF8E44AD), // 6 purple
    Color(0xFF1ABC9C), // 7 teal
  ];

  static Color nodeAccent(int colorIndex) =>
      nodeAccents[colorIndex.clamp(0, 7)];

  static Color nodeAccentDim(int colorIndex) =>
      nodeAccent(colorIndex).withValues(alpha: 0.15);
}

// ════════════════════════════════════════════════════════════════════════════
// SPACING
// ════════════════════════════════════════════════════════════════════════════
abstract final class AppSpacing {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xxl  = 24;
  static const double xxxl = 32;

  static const double pageHorizontal  = 20;
  static const double cardPadding     = 16;
  static const double cardGap         = 12;
  static const double sectionSpacing  = 28;
  static const double titleContentGap = 12;
}

// ════════════════════════════════════════════════════════════════════════════
// SHAPES
// ════════════════════════════════════════════════════════════════════════════
abstract final class AppRadius {
  static const card   = BorderRadius.all(Radius.circular(10));
  static const button = BorderRadius.all(Radius.circular(8));
  static const chip   = BorderRadius.all(Radius.circular(99));
  static const input  = BorderRadius.all(Radius.circular(8));
  static const sheet  = BorderRadius.vertical(top: Radius.circular(20));
  static const bubble = BorderRadius.all(Radius.circular(26));
}

// ════════════════════════════════════════════════════════════════════════════
// TYPOGRAPHY
// ════════════════════════════════════════════════════════════════════════════
abstract final class AppTypography {
  static TextStyle get pageTitle => GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static TextStyle get sectionHeader => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary, letterSpacing: 1.2,
  );
  static TextStyle get cardTitle => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
  static TextStyle get code => GoogleFonts.jetBrainsMono(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static TextStyle get progressPct => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static TextStyle get badge => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static TextStyle get navLabel => GoogleFonts.inter(
    fontSize: 9, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary, letterSpacing: 0.5,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// THEME DATA
// ════════════════════════════════════════════════════════════════════════════
ThemeData buildAppTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface:                 AppColors.surface,
      primary:                 AppColors.accentBlue,
      secondary:               AppColors.accentRed,
      error:                   AppColors.error,
      onSurface:               AppColors.textPrimary,
      onPrimary:               AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceAlt,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor:    AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
      labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentBlue,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.surfaceAlt,
        disabledForegroundColor: AppColors.textSecondary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentBlue,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border, space: 1, thickness: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceAlt,
      selectedColor: AppColors.accentBlue,
      labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),
      side: const BorderSide(color: AppColors.border),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14, color: AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: const BorderSide(color: AppColors.border),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.accentBlue
              : AppColors.textSecondary),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.accentBlueDim
              : AppColors.surfaceAlt),
      trackOutlineColor: WidgetStateProperty.all(AppColors.border),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,
      tileColor: Colors.transparent,
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accentBlue,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentBlue,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
  );
}
