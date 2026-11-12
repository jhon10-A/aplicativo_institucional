import '../widgets/student_quick_view.dart';

import 'package:flutter/material.dart';

import '../../../auth.dart';
import '../student_section.dart';
import '../student_api.dart';
import '../student_theme.dart';
import '../widgets/student_presentation.dart';
import 'student_profile_screen.dart';
import 'student_courses_screen.dart';
import 'student_tasks_screen.dart';
import 'student_grades_screen.dart';
import 'student_progress_screen.dart';
import 'student_attendance_screen.dart';
import 'student_schedule_screen.dart';
import 'student_notices_screen.dart';
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
  int? _enrollmentId;
  int? _quickDetailId;
  bool _openingQuickView = false;
  Future<void> _openQuickView(StudentSection section) async {
    if (_openingQuickView) return;
    _openingQuickView = true;
    try {
      final result = await showStudentQuickView(
        context: context,
        section: section,
        apiFactory: _api,
        onUnauthorized: widget.onLogout,
        onEnrollmentChanged: _rememberEnrollment,
        enrollmentId: _enrollmentId,
      );
      if (!mounted || result == null) return;
      setState(() {
        _enrollmentId = result.enrollmentId;
        _quickDetailId = result.itemId;
        _section = result.section;
      });
    } finally {
      _openingQuickView = false;
    }
  }

  void _rememberEnrollment(int? id) {
    if (mounted && id != _enrollmentId) setState(() => _enrollmentId = id);
  }

  void _select(StudentSection section) {
    setState(() {
      _section = section;
      _quickDetailId = null;
    });
  }

  void _openProgressTask(int taskId) {
    setState(() {
      _quickDetailId = taskId;
      _section = StudentSection.tareas;
    });
  }

  void _openProgressGrade(int gradeId) {
    setState(() {
      _quickDetailId = gradeId;
      _section = StudentSection.calificaciones;
    });
  }

  StudentApi _api() =>
      widget.studentApiFactory?.call() ??
      StudentApi(baseUrl: widget.apiBaseUrl, token: widget.session.accessToken);
  void _home() => _select(StudentSection.inicio);
  Widget _sectionContent() => switch (_section) {
    StudentSection.inicio => const SizedBox.shrink(),
    StudentSection.progreso => StudentProgressScreen(
      initialEnrollmentId: _enrollmentId,
      onEnrollmentChanged: _rememberEnrollment,
      apiFactory: _api,
      onUnauthorized: widget.onLogout,
      onHome: _home,
      onOpenTask: _openProgressTask,
      onOpenGrade: _openProgressGrade,
    ),
    StudentSection.perfil => StudentProfileScreen(
      apiFactory: _api,
      onUnauthorized: widget.onLogout,
      onHome: _home,
    ),
    StudentSection.cursos => StudentCoursesScreen(
      initialAssignmentId: _quickDetailId,
      initialEnrollmentId: _enrollmentId,
      onEnrollmentChanged: _rememberEnrollment,
      apiFactory: _api,
      onUnauthorized: widget.onLogout,
      onHome: _home,
    ),
    StudentSection.tareas => StudentTasksScreen(
      initialTaskId: _quickDetailId,
      initialEnrollmentId: _enrollmentId,
      onEnrollmentChanged: _rememberEnrollment,
      apiFactory: _api,
      onUnauthorized: widget.onLogout,
      onHome: _home,
    ),
    StudentSection.calificaciones => StudentGradesScreen(
      initialGradeId: _quickDetailId,
      initialEnrollmentId: _enrollmentId,
      onEnrollmentChanged: _rememberEnrollment,
      apiFactory: _api,
      onUnauthorized: widget.onLogout,
      onHome: _home,
    ),
    StudentSection.asistencia => StudentAttendanceScreen(
      initialRecordId: _quickDetailId,
      initialEnrollmentId: _enrollmentId,
      onEnrollmentChanged: _rememberEnrollment,
      apiFactory: _api,
      onUnauthorized: widget.onLogout,
      onHome: _home,
    ),
    StudentSection.horario => StudentScheduleScreen(
      initialEnrollmentId: _enrollmentId,
      onEnrollmentChanged: _rememberEnrollment,
      apiFactory: _api,
      onUnauthorized: widget.onLogout,
      onHome: _home,
    ),
    StudentSection.comunicados => StudentNoticesScreen(
      apiFactory: _api,
      onUnauthorized: widget.onLogout,
      onHome: _home,
    ),
  };
  @override
  Widget build(BuildContext context) => Theme(
    data: studentTheme(Theme.of(context)),
    child: Builder(
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_section != StudentSection.inicio) {
            _home();
          } else {
            widget.onLogout();
          }
        },
        child: Scaffold(
          bottomNavigationBar: StudentBottomNavigation(
            selected: _section,
            onSelect: _select,
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: (MediaQuery.sizeOf(context).height * .30).clamp(
                      80,
                      180,
                    ),
                  ),
                  child: SingleChildScrollView(
                    primary: false,
                    child: StudentHeader(
                      compact:
                          MediaQuery.sizeOf(context).width < 1000 ||
                          MediaQuery.textScalerOf(context).scale(1) > 1.25,
                      onLogout: widget.onLogout,
                    ),
                  ),
                ),
                StudentTopNavigation(selected: _section, onSelect: _select),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: IndexedStack(
                        index: _section == StudentSection.inicio ? 0 : 1,
                        children: [
                          StudentHome(
                            key: ObjectKey(widget.session),
                            session: widget.session,
                            onQuickView: (section) => _openQuickView(section),
                            selectedEnrollmentId: _enrollmentId,
                            onEnrollmentChanged: _rememberEnrollment,
                            onSelect: _select,
                            apiFactory: _api,
                            onUnauthorized: widget.onLogout,
                          ),
                          KeyedSubtree(
                            key: ValueKey('$_section-$_quickDetailId'),
                            child: _sectionContent(),
                          ),
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
    ),
  );
}
