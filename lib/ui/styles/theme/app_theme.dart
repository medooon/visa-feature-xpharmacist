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
    primaryTextTheme: GoogleFonts.lateefTextTheme(), // Changed to Lateef
    cupertinoOverrideTheme: _cupertinoOverrideTheme,
    scaffoldBackgroundColor: klPageBackgroundColor,
    dialogTheme: _dialogThemeData,
    shadowColor: klPrimaryColor.withOpacity(0.25), // Fixed .withValues->.withOpacity
    dividerTheme: _dividerThemeData,
    textTheme: GoogleFonts.lateefTextTheme(), // Changed to Lateef
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
    primaryTextTheme: GoogleFonts.lateefTextTheme(), // Changed to Lateef
    textTheme: GoogleFonts.lateefTextTheme(), // Changed to Lateef
    fontFamily: GoogleFonts.lateef().fontFamily, // Changed to Lateef
    shadowColor: kdPrimaryColor.withOpacity(0.25), // Fixed .withValues->.withOpacity
    brightness: Brightness.dark,
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

final _textButtonTheme = TextButtonThemeData(
  style: TextButton.styleFrom(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),
);

const _dividerThemeData = DividerThemeData(
  color: Colors.black12,
  thickness: .5,
);

final _dialogThemeData = DialogTheme(
  alignment: Alignment.center,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  ),
  titleTextStyle: GoogleFonts.lateef( // Changed to Lateef
    textStyle: const TextStyle(
      fontSize: 26, // 18+8=26
      fontWeight: FontWeights.regular,
      color: klPrimaryTextColor,
    ),
  ),
  shadowColor: Colors.transparent,
  surfaceTintColor: klPageBackgroundColor,
  backgroundColor: klPageBackgroundColor,
);

final _cupertinoOverrideTheme = NoDefaultCupertinoThemeData(
  textTheme: CupertinoTextThemeData(
    textStyle: GoogleFonts.lateef( // Changed to Lateef
      textStyle: const TextStyle(
        fontSize: 24, // Original base size (14) +8=22
        fontWeight: FontWeights.regular,
      ),
    ),
  ),
);

final _tabBarTheme = TabBarTheme(
  tabAlignment: TabAlignment.center,
  overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  dividerHeight: 0,
  labelColor: klBackgroundColor,
  labelStyle: GoogleFonts.lateef( // Changed to Lateef
    textStyle: const TextStyle(
      fontWeight: FontWeights.regular,
      fontSize: 24, // 14+8=22
    ),
  ),
  unselectedLabelColor: Colors.black45,
  indicatorSize: TabBarIndicatorSize.tab,
  indicator: BoxDecoration(
    borderRadius: BorderRadius.circular(25),
    color: klPrimaryColor,
  ),
);
