import 'package:flutter/material.dart';

import 'guardian_section.dart';

/// Colores institucionales de la I.E. Micaela Bastidas Puyucahua.
const guardianWine = Color(0xFF790738);
const guardianWineDark = Color(0xFF470622);
const guardianNavy = Color(0xFF092E5A);
const guardianBlue = Color(0xFF1565C0);
const guardianBackground = Color(0xFFF1F8FD);

/// Color de identidad de cada sección (accesos, encabezados e iconos).
const guardianSectionColors = <GuardianSection, Color>{
  GuardianSection.inicio: guardianWine,
  GuardianSection.hijos: Color(0xFF1565C0),
  GuardianSection.calificaciones: Color(0xFF7B3FA0),
  GuardianSection.asistencia: Color(0xFF1E8E3E),
  GuardianSection.comunicados: Color(0xFFC76A00),
};

ThemeData guardianTheme(ThemeData inherited) => inherited.copyWith(
  colorScheme: ColorScheme.fromSeed(
    seedColor: guardianWine,
    primary: guardianWine,
    secondary: guardianBlue,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: guardianBackground,
  textTheme: inherited.textTheme.apply(
    bodyColor: guardianNavy,
    displayColor: guardianNavy,
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
  drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
  listTileTheme: const ListTileThemeData(
    iconColor: guardianNavy,
    selectedColor: guardianWine,
    selectedTileColor: Color(0xFFF7E6EE),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: guardianWine,
      side: const BorderSide(color: guardianWine),
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: guardianWine,
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFE3EDF5), space: 24),
);
