import 'package:flutter/material.dart';

import '../student_section.dart';

class StudentNavigation extends StatelessWidget {
  const StudentNavigation({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final StudentSection selected;
  final ValueChanged<StudentSection> onSelect;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Text(
            'Navegación del estudiante',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        for (final section in StudentSection.values)
          ListTile(
            key: ValueKey('student-nav-${section.name}'),
            selected: selected == section,
            leading: Icon(section.icon),
            title: Text(section.label),
            onTap: () => onSelect(section),
          ),
      ],
    ),
  );
}
