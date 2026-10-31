import 'package:flutter/material.dart';

/// Navigation structure only: no academic data or backend requests.
enum StudentSection {
  inicio('Inicio', Icons.home_outlined),
  cursos('Cursos', Icons.menu_book_outlined),
  tareas('Tareas', Icons.assignment_outlined),
  calificaciones('Calificaciones', Icons.grade_outlined),
  asistencia('Asistencia', Icons.fact_check_outlined),
  comunicados('Comunicados', Icons.campaign_outlined);

  const StudentSection(this.label, this.icon);
  final String label;
  final IconData icon;
}
