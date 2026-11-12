import 'package:flutter/material.dart';

const studentWine = Color(0xFF650631);
const studentNavy = Color(0xFF092E5A);
const studentBlue = Color(0xFF008FE8);
const studentBackground = Color(0xFFF1F8FD);

ThemeData studentTheme(ThemeData inherited) => inherited.copyWith(
  colorScheme: ColorScheme.fromSeed(
    seedColor: studentWine,
    primary: studentWine,
    secondary: studentBlue,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: studentBackground,
  textTheme: inherited.textTheme.apply(
    bodyColor: studentNavy,
    displayColor: studentNavy,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: studentWine,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFDDEAF4)),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    iconColor: studentBlue,
    titleTextStyle: TextStyle(
      color: studentNavy,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
    subtitleTextStyle: TextStyle(
      color: Color(0xFF506780),
      fontSize: 13,
      height: 1.6,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFC9DDEB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: studentBlue, width: 2),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: studentBlue,
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: studentBlue),
  dividerTheme: const DividerThemeData(color: Color(0xFFE3EDF5), space: 24),
);
