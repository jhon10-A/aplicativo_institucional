import 'package:flutter/material.dart';

/// Estructura de navegación del apoderado: sin datos académicos ni peticiones al backend.
enum GuardianSection {
  inicio('Inicio', Icons.home_outlined),
  hijos('Mis hijos', Icons.family_restroom),
  calificaciones('Calificaciones', Icons.grade_outlined),
  asistencia('Asistencia', Icons.fact_check_outlined),
  comunicados('Comunicados', Icons.campaign_outlined);

  const GuardianSection(this.label, this.icon);
  final String label;
  final IconData icon;
}
