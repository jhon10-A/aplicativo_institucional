import 'package:flutter/material.dart';

import '../student_section.dart';
import '../student_theme.dart';

class StudentNavigationHeader extends SliverPersistentHeaderDelegate {
  StudentNavigationHeader({required this.child, required this.height});
  final Widget child;
  final double height;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(covariant StudentNavigationHeader oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}

class StudentTopNavigation extends StatelessWidget {
  const StudentTopNavigation({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final StudentSection selected;
  final ValueChanged<StudentSection> onSelect;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 752),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Row(
            children: [
              Flexible(
                child: TextButton.icon(
                  onPressed: () => onSelect(StudentSection.inicio),
                  icon: const Icon(Icons.home_outlined, size: 19),
                  label: const Text('Inicio', style: TextStyle(fontSize: 12)),
                ),
              ),
              const Spacer(),
              Flexible(
                child: PopupMenuButton<StudentSection>(
                  tooltip: 'Abrir navegación',
                  onSelected: onSelect,
                  itemBuilder: (context) => [
                    for (final section in StudentSection.values)
                      PopupMenuItem(
                        key: ValueKey('student-nav-${section.name}'),
                        value: section,
                        child: Row(
                          children: [
                            Icon(section.icon, size: 20),
                            const SizedBox(width: 12),
                            Flexible(child: Text(section.label)),
                          ],
                        ),
                      ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Secciones',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: studentNavy,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.expand_more, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class StudentNavigation extends StatelessWidget {
  const StudentNavigation({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final StudentSection selected;
  final ValueChanged<StudentSection> onSelect;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Text(
              'MI ESPACIO\nESTUDIANTE',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: studentNavy,
                height: 1.6,
                letterSpacing: 1,
              ),
            ),
          ),
          for (final section in StudentSection.values)
            ListTile(
              key: ValueKey('student-nav-${section.name}'),
              selected: selected == section,
              selectedColor: studentWine,
              selectedTileColor: const Color(0xFFF8EAF1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Icon(section.icon),
              title: Text(section.label),
              onTap: () => onSelect(section),
            ),
        ],
      ),
    ),
  );
}

class StudentBottomNavigation extends StatelessWidget {
  const StudentBottomNavigation({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final StudentSection selected;
  final ValueChanged<StudentSection> onSelect;
  @override
  Widget build(BuildContext context) => Material(
    color: studentNavy,
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final section in [
                StudentSection.inicio,
                StudentSection.cursos,
                StudentSection.tareas,
                StudentSection.comunicados,
                StudentSection.perfil,
              ])
                Expanded(
                  child: Semantics(
                    selected: selected == section,
                    button: true,
                    child: InkWell(
                      key: ValueKey('student-bottom-${section.name}'),
                      onTap: () => onSelect(section),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 2,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              section == StudentSection.comunicados
                                  ? Icons.notifications_none_rounded
                                  : section.icon,
                              color: selected == section
                                  ? const Color(0xFF66D2FF)
                                  : const Color(0xFFCEDDEC),
                              size: 25,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              section == StudentSection.comunicados
                                  ? 'Notificaciones'
                                  : section.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: selected == section
                                    ? Colors.white
                                    : const Color(0xFFCEDDEC),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
