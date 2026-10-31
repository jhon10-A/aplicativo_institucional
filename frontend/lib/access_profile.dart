import 'package:flutter/material.dart';

/// Presentation choices only. Permissions always come from the backend.
enum AccessProfile {
  estudiante(
    'Estudiante',
    'ESTUDIANTE',
    'Soy estudiante',
    'Aprende, crece y construye tu futuro',
    '¡Tú puedes lograrlo!',
    Icons.school_outlined,
    Color(0xFF0875C9),
  ),
  docente(
    'Docente',
    'DOCENTE',
    'Soy docente',
    'Educar es sembrar grandes sueños',
    '¡Tu labor transforma vidas!',
    Icons.co_present_outlined,
    Color(0xFF7430B8),
  ),
  apoderado(
    'Padre de familia',
    'APODERADO',
    'Soy padre de familia',
    'Juntos por la educación de nuestros hijos',
    'Tu apoyo también educa',
    Icons.family_restroom,
    Color(0xFF18853D),
  );

  const AccessProfile(
    this.label,
    this.role,
    this.title,
    this.description,
    this.motto,
    this.icon,
    this.color,
  );
  final String label;
  final String role;
  final String title;
  final String description;
  final String motto;
  final IconData icon;
  final Color color;
}
