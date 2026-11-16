import 'package:flutter/material.dart';

import '../guardian_section.dart';

class GuardianNavigation extends StatelessWidget {
  const GuardianNavigation({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final GuardianSection selected;
  final ValueChanged<GuardianSection> onSelect;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Text(
            'Navegación del apoderado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        for (final section in GuardianSection.values)
          ListTile(
            key: ValueKey('guardian-nav-${section.name}'),
            selected: selected == section,
            leading: Icon(section.icon),
            title: Text(section.label),
            onTap: () => onSelect(section),
          ),
      ],
    ),
  );
}
