import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const green = Color(0xFF0F3D3A);
  static const greenSoft = Color(0xFFE3EEEC);
  static const cream = Color(0xFFFAF5E8);
  static const coral = Color(0xFFE05A40);
  static const coralSoft = Color(0xFFFDE8E3);
  static const line = Color(0xFFE3DCC9);
  static const ink = Color(0xFF12302D);
  static const muted = Color(0xFF6C7A76);
  static const gold = Color(0xFFE0A43A);
  static const goldSoft = Color(0xFFFBF0D6);
  static const sand = Color(0xFFEFEBDD);
  static const sandDeep = Color(0xFFE9E3D2);

  static const success = Color(0xFF1D6B3A);
  static const successSoft = Color(0xFFDDF1E3);
  static const danger = Color(0xFFB3321E);
  static const dangerSoft = Color(0xFFFBE3DE);
}

class AppRadius {
  static const card = 18.0;
  static const field = 12.0;
}

class AppShadow {
  static const soft = [
    BoxShadow(color: Color(0x0F0F3D3A), blurRadius: 12, offset: Offset(0, 4))
  ];
  static const lift = [
    BoxShadow(color: Color(0x1A0F3D3A), blurRadius: 24, offset: Offset(0, 10))
  ];
}

/// Headings (Fraunces).
TextStyle serif(double size, {Color color = AppColors.green}) =>
    GoogleFonts.fraunces(
        fontSize: size, color: color, fontWeight: FontWeight.w600, height: 1.2);

/// Codes and numbers (booking code, GCash number).
TextStyle mono(double size, {Color color = AppColors.ink}) =>
    GoogleFonts.ibmPlexMono(
        fontSize: size, color: color, fontWeight: FontWeight.w600);

/// Small ALL-CAPS label above a value.
TextStyle overline({Color color = AppColors.muted}) => TextStyle(
    fontSize: 10.5,
    letterSpacing: .9,
    fontWeight: FontWeight.w600,
    color: color);

ThemeData buildTheme() {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: c, width: w));

  final base = GoogleFonts.poppinsTextTheme()
      .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      secondary: AppColors.coral,
      surface: AppColors.cream,
    ),
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: base,
    splashFactory: InkRipple.splashFactory,
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.green),
    textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.green, selectionHandleColor: AppColors.green),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.green,
      titleTextStyle: serif(20),
      shape: const Border(bottom: BorderSide(color: AppColors.line)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.green, 1.6),
      errorBorder: border(AppColors.coral),
      focusedErrorBorder: border(AppColors.coral, 1.6),
      errorStyle: const TextStyle(fontSize: 11.5, color: AppColors.danger),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.line,
        disabledForegroundColor: AppColors.muted,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field)),
        textStyle:
            GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.green,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field)),
        textStyle:
            GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
          foregroundColor: AppColors.coral,
          textStyle:
              GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.green : Colors.white),
        foregroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : AppColors.ink),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.line)),
        textStyle: WidgetStatePropertyAll(
            GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: AppColors.greenSoft,
      indicatorShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final on = s.contains(WidgetState.selected);
        return GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: on ? FontWeight.w600 : FontWeight.w400,
            color: on ? AppColors.green : AppColors.muted);
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          size: 24,
          color: s.contains(WidgetState.selected)
              ? AppColors.green
              : AppColors.muted)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
  );
}
