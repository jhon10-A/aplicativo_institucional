import 'package:flutter/material.dart';

import '../../../auth.dart';
import '../student_section.dart';
import '../widgets/development_section.dart';
import '../widgets/student_home.dart';
import '../widgets/student_navigation.dart';

class StudentPanel extends StatefulWidget {
  const StudentPanel({
    super.key,
    required this.session,
    required this.onLogout,
  });
  final Session session;
  final VoidCallback onLogout;

  @override
  State<StudentPanel> createState() => _StudentPanelState();
}

class _StudentPanelState extends State<StudentPanel> {
  StudentSection _section = StudentSection.inicio;

  void _select(StudentSection section) => setState(() => _section = section);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_section != StudentSection.inicio) {
            _select(StudentSection.inicio);
          } else {
            widget.onLogout();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              _section.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: wide
                ? null
                : Builder(
                    builder: (context) => IconButton(
                      tooltip: 'Abrir navegación',
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
            actions: [
              if (constraints.maxWidth < 420)
                IconButton(
                  tooltip: 'Cerrar sesión',
                  icon: const Icon(Icons.logout),
                  onPressed: widget.onLogout,
                )
              else
                TextButton(
                  onPressed: widget.onLogout,
                  child: const Text('Cerrar sesión'),
                ),
            ],
          ),
          drawer: wide
              ? null
              : Drawer(
                  child: Builder(
                    builder: (context) => StudentNavigation(
                      selected: _section,
                      onSelect: (section) {
                        Scaffold.of(context).closeDrawer();
                        _select(section);
                      },
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide) ...[
                  SizedBox(
                    width: 250,
                    child: StudentNavigation(
                      selected: _section,
                      onSelect: _select,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: _section == StudentSection.inicio
                      ? StudentHome(session: widget.session, onSelect: _select)
                      : DevelopmentSection(
                          section: _section,
                          onHome: () => _select(StudentSection.inicio),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
