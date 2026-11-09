import 'package:flutter/material.dart';

/// Navigation structure only: no academic data or backend requests.
enum StudentSection {
  inicio('Inicio', Icons.home_outlined),
  perfil('Perfil', Icons.person_outline),
  cursos('Cursos', Icons.menu_book_outlined),
  tareas('Tareas', Icons.assignment_turned_in_outlined),
  calificaciones('Calificaciones', Icons.description_outlined),
  progreso('Mi Progreso', Icons.bar_chart_rounded),
  asistencia('Asistencia', Icons.fact_check_outlined),
  comunicados('Comunicados', Icons.campaign_outlined);

  const StudentSection(this.label, this.icon);
  final String label;
  final IconData icon;
}
