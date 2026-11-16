import 'package:flutter/material.dart';

/// Secciones de navegación del panel del apoderado.
enum GuardianSection {
  inicio('Inicio', Icons.home_outlined, 'Resumen del panel'),
  hijos('Mis hijos', Icons.family_restroom, 'Datos y matrícula de tus hijos'),
  calificaciones(
    'Calificaciones',
    Icons.grade_outlined,
    'Notas por curso y promedios',
  ),
  asistencia(
    'Asistencia',
    Icons.fact_check_outlined,
    'Asistencias, faltas y tardanzas',
  ),
  comunicados('Comunicados', Icons.campaign_outlined, 'Avisos del colegio');

  const GuardianSection(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;
}
