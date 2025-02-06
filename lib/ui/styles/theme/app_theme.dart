import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/ui/styles/colors.dart';
import 'package:flutterquiz/utils/constants/fonts.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppTheme { light, dark }

// Common text style configuration for Arabic
final _arabicTextStyle = GoogleFonts.lateef(
  textStyle: const TextStyle(
    fontSize: 16, // Base size for Arabic readability
    fontWeight: FontWeight.w400,
    height: 1.5, // Line height for better Arabic script
  ),
);

final appThemeData = {
  AppTheme.light: ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Lateef', // Direct font family name
    primaryTextTheme: TextTheme(
      displayLarge: _arabicTextStyle.copyWith(fontSize: 24),
      displayMedium: _arabicTextStyle.copyWith(fontSize: 22),
      bodyLarge: _arabicTextStyle.copyWith(fontSize: 18),
      bodyMedium: _arabicTextStyle.copyWith(fontSize: 16),
      titleMedium: _arabicTextStyle.copyWith(fontSize: 18),
      labelLarge: _arabicTextStyle.copyWith(fontSize: 18),
    ),
    textTheme: TextTheme(
      bodyLarge: _arabicTextStyle.copyWith(fontSize: 18),
      bodyMedium: _arabicTextStyle.copyWith(fontSize: 16),
      titleLarge: _arabicTextStyle.copyWith(fontSize: 20),
      titleMedium: _arabicTextStyle.copyWith(fontSize: 18),
      labelLarge: _arabicTextStyle.copyWith(fontSize: 18),
    ),
    // Keep other light theme properties from original
    canvasColor: klCanvasColor,
    primaryColor: klPrimaryColor,
    scaffoldBackgroundColor: klPageBackgroundColor,
    // ... rest of your light theme configuration
  ),
  AppTheme.dark: ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Lateef',
    primaryTextTheme: TextTheme(
      displayLarge: _arabicTextStyle.copyWith(fontSize: 24),
      displayMedium: _arabicTextStyle.copyWith(fontSize: 22),
      bodyLarge: _arabicTextStyle.copyWith(fontSize: 18),
      bodyMedium: _arabicTextStyle.copyWith(fontSize: 16),
      titleMedium: _arabicTextStyle.copyWith(fontSize: 18),
      labelLarge: _arabicTextStyle.copyWith(fontSize: 18),
    ),
    textTheme: TextTheme(
      bodyLarge: _arabicTextStyle.copyWith(fontSize: 18),
      bodyMedium: _arabicTextStyle.copyWith(fontSize: 16),
      titleLarge: _arabicTextStyle.copyWith(fontSize: 20),
      titleMedium: _arabicTextStyle.copyWith(fontSize: 18),
      labelLarge: _arabicTextStyle.copyWith(fontSize: 18),
    ),
    // Keep other dark theme properties from original
    primaryColor: kdPrimaryColor,
    scaffoldBackgroundColor: kdPageBackgroundColor,
    // ... rest of your dark theme configuration
  ),
};

// Update Cupertino theme
final _cupertinoOverrideTheme = NoDefaultCupertinoThemeData(
  textTheme: CupertinoTextThemeData(
    textStyle: GoogleFonts.lateef(
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),
  ),
);

// Update Dialog theme
final _dialogThemeData = DialogTheme(
  titleTextStyle: GoogleFonts.lateef(
    textStyle: const TextStyle(
      fontSize: 20, // Larger for Arabic titles
      fontWeight: FontWeight.w600,
    ),
  ),
  contentTextStyle: GoogleFonts.lateef(
    textStyle: const TextStyle(
      fontSize: 16,
    ),
  ),
);

// Update TabBar theme
final _tabBarTheme = TabBarTheme(
  labelStyle: GoogleFonts.lateef(
    textStyle: const TextStyle(
      fontSize: 16, // Increased from 14
      fontWeight: FontWeight.w500,
    ),
  ),
  unselectedLabelStyle: GoogleFonts.lateef(
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
  ),
);
