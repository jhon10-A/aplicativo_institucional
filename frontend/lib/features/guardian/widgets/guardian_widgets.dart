import 'package:flutter/material.dart';

import '../guardian_section.dart';
import '../guardian_theme.dart';

/// Iniciales para el avatar: primera letra de nombres y de apellidos.
String guardianInitials(String nombres, String apellidos) {
  String first(String value) =>
      value.trim().isEmpty ? '' : value.trim().substring(0, 1).toUpperCase();
  final text = '${first(nombres)}${first(apellidos)}';
  return text.isEmpty ? '?' : text;
}

class GuardianAvatar extends StatelessWidget {
  const GuardianAvatar({
    super.key,
    required this.initials,
    this.size = 48,
    this.color = guardianWine,
  });
  final String initials;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: size * 0.36,
      ),
    ),
  );
}

/// Título de cada sección: icono de color y nombre.
class GuardianSectionHeader extends StatelessWidget {
  const GuardianSectionHeader({super.key, required this.section});
  final GuardianSection section;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: guardianSectionColors[section] ?? guardianWine,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(section.icon, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          section.label,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}
