import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/ui/styles/colors.dart';
import 'package:flutterquiz/utils/constants/fonts.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppTheme { light, dark }

final appThemeData = {
  AppTheme.light: ThemeData(
    brightness: Brightness.light,
    canvasColor: klCanvasColor,
    fontFamily: GoogleFonts.lateef().fontFamily, // Changed to Lateef
    primaryColor: klPrimaryColor,
    primaryTextTheme: GoogleFonts.lateefTextTheme().copyWith(
      // Adjusted sizes
      displayLarge: const TextStyle(fontSize: 24),
      displayMedium: const TextStyle(fontSize: 22),
      bodyLarge: const TextStyle(fontSize: 20),
      bodyMedium: const TextStyle(fontSize: 18),
      titleMedium: const TextStyle(fontSize: 20),
      labelLarge: const TextStyle(fontSize: 18),
    ),
    scaffoldBackgroundColor: klPageBackgroundColor,
    dialogTheme: _dialogThemeData,
    shadowColor: klPrimaryColor.withOpacity(0.25),
    dividerTheme: _dividerThemeData,
    textTheme: GoogleFonts.lateefTextTheme().copyWith(
      // Adjusted sizes
      bodyLarge: const TextStyle(fontSize: 20),
      bodyMedium: const TextStyle(fontSize: 18),
      titleLarge: const TextStyle(fontSize: 22),
      titleMedium: const TextStyle(fontSize: 20),
      labelLarge: const TextStyle(fontSize: 18),
    ),
    textButtonTheme: _textButtonTheme,
    tabBarTheme: _tabBarTheme,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll<Color>(klPrimaryTextColor),
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: klPrimaryColor).copyWith(
      surface: klBackgroundColor,
      onTertiary: klPrimaryTextColor,
      surfaceTint: Colors.transparent,
    ),
  ),
  AppTheme.dark: ThemeData(
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.lateef().fontFamily, // Changed to Lateef
    primaryTextTheme: GoogleFonts.lateefTextTheme().copyWith(
      // Adjusted sizes
      displayLarge: const TextStyle(fontSize: 24),
      displayMedium: const TextStyle(fontSize: 22),
      bodyLarge: const TextStyle(fontSize: 20),
      bodyMedium: const TextStyle(fontSize: 18),
      titleMedium: const TextStyle(fontSize: 20),
      labelLarge: const TextStyle(fontSize: 18),
    ),
    textTheme: GoogleFonts.lateefTextTheme().copyWith(
      // Adjusted sizes
      bodyLarge: const TextStyle(fontSize: 20),
      bodyMedium: const TextStyle(fontSize: 18),
      titleLarge: const TextStyle(fontSize: 22),
      titleMedium: const TextStyle(fontSize: 20),
      labelLarge: const TextStyle(fontSize: 18),
    ),
    shadowColor: kdPrimaryColor.withOpacity(0.25),
    primaryColor: kdPrimaryColor,
    scaffoldBackgroundColor: kdPageBackgroundColor,
    dialogTheme: _dialogThemeData.copyWith(
      backgroundColor: kdPageBackgroundColor,
      surfaceTintColor: kdPageBackgroundColor,
      titleTextStyle: _dialogThemeData.titleTextStyle?.copyWith(
        color: kdPrimaryTextColor,
      ),
    ),
    canvasColor: kdCanvasColor,
    tabBarTheme: _tabBarTheme.copyWith(
      unselectedLabelColor: Colors.grey[400],
      labelColor: kdCanvasColor,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: klPrimaryColor,
      ),
    ),
    textButtonTheme: _textButtonTheme,
    dividerTheme: _dividerThemeData,
    cupertinoOverrideTheme: _cupertinoOverrideTheme,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll<Color>(kdPrimaryTextColor),
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: kdPrimaryColor).copyWith(
      brightness: Brightness.dark,
      surface: kdBackgroundColor,
      onTertiary: kdPrimaryTextColor,
      surfaceTint: Colors.transparent,
    ),
  ),
};

// Updated Cupertino theme with Lateef
final _cupertinoOverrideTheme = NoDefaultCupertinoThemeData(
  textTheme: CupertinoTextThemeData(
    textStyle: GoogleFonts.lateef(
      textStyle: const TextStyle(
        fontSize: 24, // Increased from 16
        fontWeight: FontWeights.regular,
      ),
    ),
  ),
);

// Updated Dialog theme with Lateef
final _dialogThemeData = DialogTheme(
  alignment: Alignment.center,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  ),
  titleTextStyle: GoogleFonts.lateef(
    textStyle: const TextStyle(
      fontSize: 24, // Increased from 18
      fontWeight: FontWeights.regular,
      color: klPrimaryTextColor,
    ),
  ),
  shadowColor: Colors.transparent,
  surfaceTintColor: klPageBackgroundColor,
  backgroundColor: klPageBackgroundColor,
);

// Updated TabBar theme with Lateef
final _tabBarTheme = TabBarTheme(
  tabAlignment: TabAlignment.center,
  overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  dividerHeight: 0,
  labelColor: klBackgroundColor,
  labelStyle: GoogleFonts.lateef(
    textStyle: const TextStyle(
      fontWeight: FontWeights.regular,
      fontSize: 22, // Increased from 14
    ),
  ),
  unselectedLabelColor: Colors.black45,
  indicatorSize: TabBarIndicatorSize.tab,
  indicator: BoxDecoration(
    borderRadius: BorderRadius.circular(25),
    color: klPrimaryColor,
  ),
);
