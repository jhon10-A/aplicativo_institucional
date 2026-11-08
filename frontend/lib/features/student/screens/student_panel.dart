import 'package:flutter/material.dart';

import '../../../auth.dart';
import '../student_section.dart';
import '../student_api.dart';
import 'student_profile_screen.dart';
import 'student_courses_screen.dart';
import 'student_tasks_screen.dart';
import 'student_grades_screen.dart';
import 'student_attendance_screen.dart';
import 'student_notices_screen.dart';
import '../widgets/development_section.dart';
import '../widgets/student_home.dart';
import '../widgets/student_navigation.dart';

class StudentPanel extends StatefulWidget {
  const StudentPanel({
    super.key,
    required this.session,
    required this.onLogout,
    this.apiBaseUrl = const String.fromEnvironment('API_BASE_URL'),
    this.studentApiFactory,
  });
  final Session session;
  final VoidCallback onLogout;
  final String apiBaseUrl;
  final StudentApi Function()? studentApiFactory;

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
                      : _section == StudentSection.perfil
                      ? StudentProfileScreen(
                          key: ObjectKey(widget.session),
                          apiFactory:
                              widget.studentApiFactory ??
                              () => StudentApi(
                                baseUrl: widget.apiBaseUrl,
                                token: widget.session.accessToken,
                              ),
                          onUnauthorized: widget.onLogout,
                          onHome: () => _select(StudentSection.inicio),
                        )
                      : _section == StudentSection.cursos
                      ? StudentCoursesScreen(
                          key: ObjectKey(widget.session),
                          apiFactory:
                              widget.studentApiFactory ??
                              () => StudentApi(
                                baseUrl: widget.apiBaseUrl,
                                token: widget.session.accessToken,
                              ),
                          onUnauthorized: widget.onLogout,
                          onHome: () => _select(StudentSection.inicio),
                        )
                      : _section == StudentSection.tareas
                      ? StudentTasksScreen(
                          key: ObjectKey(widget.session),
                          apiFactory:
                              widget.studentApiFactory ??
                              () => StudentApi(
                                baseUrl: widget.apiBaseUrl,
                                token: widget.session.accessToken,
                              ),
                          onUnauthorized: widget.onLogout,
                          onHome: () => _select(StudentSection.inicio),
                        )
                      : _section == StudentSection.calificaciones
                      ? StudentGradesScreen(
                          key: ObjectKey(widget.session),
                          apiFactory:
                              widget.studentApiFactory ??
                              () => StudentApi(
                                baseUrl: widget.apiBaseUrl,
                                token: widget.session.accessToken,
                              ),
                          onUnauthorized: widget.onLogout,
                          onHome: () => _select(StudentSection.inicio),
                        )
                      : _section == StudentSection.asistencia
                      ? StudentAttendanceScreen(
                          key: ObjectKey(widget.session),
                          apiFactory:
                              widget.studentApiFactory ??
                              () => StudentApi(
                                baseUrl: widget.apiBaseUrl,
                                token: widget.session.accessToken,
                              ),
                          onUnauthorized: widget.onLogout,
                          onHome: () => _select(StudentSection.inicio),
                        )
                      : _section == StudentSection.comunicados
                      ? StudentNoticesScreen(
                          key: ObjectKey(widget.session),
                          apiFactory:
                              widget.studentApiFactory ??
                              () => StudentApi(
                                baseUrl: widget.apiBaseUrl,
                                token: widget.session.accessToken,
                              ),
                          onUnauthorized: widget.onLogout,
                          onHome: () => _select(StudentSection.inicio),
                        )
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
