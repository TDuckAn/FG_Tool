import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// "Scholarly Modernism" — warm paper, deep ink, burgundy accent.
/// Inspired by academic journals, university presses, and modernist editorial design.
///
/// Uses Windows system fonts (no asset bundling, no native packages):
///   • Display: Cambria (serif with personality, shipped since Vista)
///   • Body:    Bahnschrift (modern grotesque, Windows 10+)
///   • Mono:    Cascadia Mono (Windows Terminal default, Windows 10+)
class AppTheme {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color paper = Color(0xFFF5EFE4); // warm cream base
  static const Color paperDeep = Color(
    0xFFEAE2D2,
  ); // slightly darker for surface variants
  static const Color card = Color(0xFFFBF7EE); // floats above paper
  static const Color ink = Color(0xFF1A1714); // warm near-black
  static const Color inkSoft = Color(0xFF4A433B); // for secondary text
  static const Color inkMuted = Color(0xFF8A8175); // for tertiary text / hints
  static const Color rule = Color(0xFFD9CFBE); // hairline dividers

  // Accent: deep burgundy (the *ink stamp* of an academic seal)
  static const Color accent = Color(0xFF6E1F22);
  static const Color accentSoft = Color(0xFFF3E0DD);

  // Semantic
  static const Color forest = Color(0xFF3B5F3D); // matched / complete
  static const Color ochre = Color(0xFFB97A2C); // partial / draft
  static const Color rust = Color(0xFF8C3A2A); // no match / error

  // Legacy aliases used elsewhere in the codebase
  static const Color colorNotStarted = inkMuted;
  static const Color colorDraft = ochre;
  static const Color colorComplete = forest;
  static const Color colorAutoFilled = accentSoft;
  static const Color colorEdited = card;
  static const Color colorMatchExact = forest;
  static const Color colorMatchPartial = ochre;
  static const Color colorMatchNone = rust;

  // ── Typography ────────────────────────────────────────────────────────────
  // Font family chains — first match wins, so Cambria → Georgia → serif on
  // non-Windows targets. Bahnschrift falls back to Segoe UI then sans-serif.

  static const List<String> _serifFamily = [
    'Cambria',
    'Times New Roman',
    'Georgia',
    'serif',
  ];
  static const List<String> _sansFamily = [
    'Bahnschrift',
    'Segoe UI',
    'Segoe UI Variable',
    'Arial',
    'Helvetica Neue',
    'sans-serif',
  ];
  static const List<String> _monoFamily = [
    'Cascadia Mono',
    'Consolas',
    'Courier New',
    'monospace',
  ];

  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: _serifFamily.first,
    fontFamilyFallback: _serifFamily.sublist(1),
    fontSize: size,
    fontWeight: weight,
    color: color ?? ink,
    height: height,
    letterSpacing: -size * 0.015,
  );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: _sansFamily.first,
    fontFamilyFallback: _sansFamily.sublist(1),
    fontSize: size,
    fontWeight: weight,
    color: color ?? ink,
    height: height ?? 1.45,
  );

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) => TextStyle(
    fontFamily: _monoFamily.first,
    fontFamilyFallback: _monoFamily.sublist(1),
    fontSize: size,
    fontWeight: weight,
    color: color ?? ink,
    letterSpacing: 0,
  );

  /// Editorial all-caps label — small with wide tracking, like a journal kicker.
  static TextStyle label(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color? color,
  }) => TextStyle(
    fontFamily: _sansFamily.first,
    fontFamilyFallback: _sansFamily.sublist(1),
    fontSize: size,
    fontWeight: weight,
    color: color ?? inkSoft,
    letterSpacing: 1.6,
    height: 1.2,
  );

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: accent,
      onPrimary: paper,
      secondary: ink,
      onSecondary: paper,
      surface: card,
      onSurface: ink,
      surfaceContainerHighest: paperDeep,
      surfaceContainerHigh: paperDeep,
      surfaceContainer: card,
      surfaceContainerLow: paper,
      surfaceContainerLowest: paper,
      error: rust,
      onError: paper,
      outline: rule,
      outlineVariant: rule,
    );

    final textTheme = TextTheme(
      displayLarge: display(72, weight: FontWeight.w600, height: 1.02),
      displayMedium: display(56, weight: FontWeight.w500, height: 1.04),
      displaySmall: display(40, weight: FontWeight.w500, height: 1.06),
      headlineLarge: display(32, weight: FontWeight.w500),
      headlineMedium: display(24, weight: FontWeight.w500),
      headlineSmall: display(20, weight: FontWeight.w500),
      titleLarge: body(18, weight: FontWeight.w600),
      titleMedium: body(15, weight: FontWeight.w600),
      titleSmall: body(13, weight: FontWeight.w600),
      bodyLarge: body(16),
      bodyMedium: body(14),
      bodySmall: body(12, color: inkSoft),
      labelLarge: label(13),
      labelMedium: label(11),
      labelSmall: label(10),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: paper,
      canvasColor: paper,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: ink, size: 18),
      dividerTheme: const DividerThemeData(color: rule, thickness: 1, space: 1),

      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        surfaceTintColor: paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        titleTextStyle: display(20, weight: FontWeight.w500),
        iconTheme: const IconThemeData(color: ink, size: 20),
        actionsIconTheme: const IconThemeData(color: ink, size: 18),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        shape: const Border(bottom: BorderSide(color: rule, width: 1)),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: rule, width: 1),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: paper,
          textStyle: body(13, weight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          minimumSize: const Size(0, 40),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          textStyle: body(13, weight: FontWeight.w500),
          side: const BorderSide(color: ink, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          minimumSize: const Size(0, 40),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          textStyle: body(13, weight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          minimumSize: const Size(0, 40),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: rule, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: rule, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: ink, width: 1.5),
        ),
        labelStyle: body(13, color: inkMuted, weight: FontWeight.w500),
        floatingLabelStyle: label(11, color: inkSoft),
        hintStyle: body(14, color: inkMuted),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: rule, width: 1),
        ),
        titleTextStyle: display(22, weight: FontWeight.w500),
        contentTextStyle: body(14, color: inkSoft, height: 1.55),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: body(13, color: paper, weight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: card,
        labelStyle: label(10, color: ink),
        side: const BorderSide(color: rule),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: paper,
          foregroundColor: inkSoft,
          selectedBackgroundColor: ink,
          selectedForegroundColor: paper,
          textStyle: body(12, weight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          side: const BorderSide(color: rule),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(2),
        ),
        textStyle: body(12, color: paper),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}

/// Subtle paper-grain background — a `BoxDecoration` you can wrap any container in.
/// Renders as a layered radial gradient that mimics ink-on-paper irregularity.
class PaperBackground extends StatelessWidget {
  final Widget child;
  const PaperBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.8, -0.6),
          radius: 1.8,
          colors: [Color(0xFFF8F2E7), AppTheme.paper, Color(0xFFEFE7D7)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Reusable kicker — small all-caps label with a horizontal rule underneath.
/// Used to introduce sections in the editorial style.
class Kicker extends StatelessWidget {
  final String text;
  final String? number;
  final Color? color;
  const Kicker({super.key, required this.text, this.number, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.inkSoft;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (number != null) ...[
          Text(
            number!,
            style: AppTheme.mono(11, color: c, weight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Container(width: 18, height: 1, color: c),
          const SizedBox(width: 10),
        ],
        Text(text.toUpperCase(), style: AppTheme.label(11, color: c)),
      ],
    );
  }
}

/// Compact status pill with a leading dot, replacing emoji-laden chips.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: filled ? AppTheme.paper : color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: AppTheme.label(
              10,
              color: filled ? AppTheme.paper : color,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
