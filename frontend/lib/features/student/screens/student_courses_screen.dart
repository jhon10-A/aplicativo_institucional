import '../student_enrollment_selection.dart';
import '../widgets/student_presentation.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../student_api.dart';
import '../student_course.dart';
import '../student_profile.dart';

class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({
    super.key,
    required this.apiFactory,
    required this.onUnauthorized,
    required this.onHome,
    this.initialEnrollmentId,
    this.initialAssignmentId,
    this.onEnrollmentChanged,
  });
  final StudentApi Function() apiFactory;
  final VoidCallback onUnauthorized;
  final VoidCallback onHome;
  final int? initialEnrollmentId;
  final int? initialAssignmentId;
  final ValueChanged<int?>? onEnrollmentChanged;

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  late final StudentApi _api;
  List<StudentEnrollment> _enrollments = [];
  List<StudentCourse> _courses = [];
  StudentCourse? _detail;
  int? _selected;
  int? _requested;
  bool _loading = true;
  StudentFailureKind? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _api = widget.apiFactory();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant StudentCoursesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.initialEnrollmentId;
    if (id != null &&
        id != oldWidget.initialEnrollmentId &&
        id != _selected &&
        _enrollments.any((m) => m.id == id)) {
      unawaited(_load(enrollment: id));
    }
  }

  Future<void> _load({int? enrollment, int? assignment}) async {
    if (enrollment != null) widget.onEnrollmentChanged?.call(enrollment);
    final generation = ++_generation;
    setState(() {
      _selected = enrollment;
      _requested = assignment;
      _loading = true;
      _error = null;
      _detail = null;
      _courses = [];
    });
    try {
      if (enrollment == null) {
        final data = await _api.get('matriculas') as List;
        final enrollments = data
            .map((e) => StudentEnrollment.fromJson(e as Map<String, dynamic>))
            .toList();
        if (!mounted || generation != _generation) return;
        setState(() => _enrollments = enrollments);
        final selected = resolveStudentEnrollment(
          enrollments,
          widget.initialEnrollmentId,
        );
        widget.onEnrollmentChanged?.call(selected);
        if (selected != null) {
          await _load(
            enrollment: selected,
            assignment: widget.initialAssignmentId,
          );
          return;
        }
      } else if (assignment == null) {
        final data = await _api.get('matriculas/$enrollment/cursos') as List;
        final courses = data
            .map((e) => StudentCourse.fromJson(e as Map<String, dynamic>))
            .toList();
        if (!mounted || generation != _generation) return;
        setState(() => _courses = courses);
      } else {
        final detail = StudentCourse.fromJson(
          await _api.get('matriculas/$enrollment/cursos/$assignment')
              as Map<String, dynamic>,
        );
        if (!mounted || generation != _generation) return;
        setState(() => _detail = detail);
      }
      setState(() => _loading = false);
    } catch (exception) {
      if (!mounted || generation != _generation) return;
      final kind = exception is StudentFailure
          ? exception.kind
          : StudentFailureKind.invalid;
      setState(() {
        _loading = false;
        _error = kind;
      });
      if (kind == StudentFailureKind.unauthorized) widget.onUnauthorized();
    }
  }

  @override
  void dispose() {
    ++_generation;
    _api.dispose();
    super.dispose();
  }

  String get _message => switch (_error) {
    StudentFailureKind.unauthorized =>
      'Tu sesión ha vencido. Vuelve a iniciar sesión.',
    StudentFailureKind.forbidden => 'No tienes acceso al módulo Estudiante.',
    StudentFailureKind.missingProfile =>
      'No tienes un perfil de estudiante registrado.',
    StudentFailureKind.unavailable =>
      'La matrícula o el curso no está disponible.',
    StudentFailureKind.network => 'No se pudo conectar. Comprueba tu conexión.',
    _ => 'No se pudieron cargar los cursos. Inténtalo nuevamente.',
  };

  Widget _information(StudentCourse course) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Docente: ${course.docente}'),
      Text('Periodo: ${course.periodo}'),
      Text('Nivel: ${course.nivel}'),
      Text('Grado: ${course.grado}'),
      Text('Sección: ${course.seccion}'),
    ],
  );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudentSectionHeading(
              title: _requested == null ? 'Mis cursos' : 'Detalle del curso',
              icon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 16),
            if (_enrollments.isNotEmpty)
              DropdownButtonFormField<int>(
                key: ValueKey(_selected),
                initialValue: _selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Matrícula y periodo',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                hint: const Text('Selecciona una matrícula'),
                items: [
                  for (final m in _enrollments)
                    DropdownMenuItem(
                      value: m.id,
                      child: Text(
                        '${m.periodo} · ${m.nivel} ${m.grado} ${m.seccion} · ${m.estado}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value != null) unawaited(_load(enrollment: value));
                      },
              ),
            const SizedBox(height: 16),
            if (_loading) ...[
              const Center(child: CircularProgressIndicator()),
              const Text('Cargando cursos…'),
            ] else if (_error != null) ...[
              Text(_message),
              if (_error != StudentFailureKind.unauthorized &&
                  _error != StudentFailureKind.forbidden)
                OutlinedButton(
                  onPressed: () =>
                      _load(enrollment: _selected, assignment: _requested),
                  child: const Text('Reintentar'),
                ),
            ] else if (_enrollments.isEmpty)
              const Text('No tienes matrículas registradas.')
            else if (_selected == null)
              const Text('Selecciona una matrícula para consultar sus cursos.')
            else if (_detail case final course?)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.nombre,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _information(course),
                      const SizedBox(height: 12),
                      Text(
                        course.descripcion?.trim().isNotEmpty == true
                            ? course.descripcion!
                            : 'Sin descripción registrada.',
                      ),
                      Text(course.activo ? 'Curso activo' : 'Curso inactivo'),
                    ],
                  ),
                ),
              )
            else if (_courses.isEmpty)
              const Text('No hay cursos asignados a esta matrícula.')
            else
              for (final course in _courses)
                Card(
                  child: ListTile(
                    title: Text(course.nombre),
                    subtitle: _information(course),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _load(
                      enrollment: _selected,
                      assignment: course.asignacionId,
                    ),
                  ),
                ),
            if (_requested != null && !_loading)
              OutlinedButton(
                onPressed: () => _load(enrollment: _selected),
                child: const Text('Volver a cursos'),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: widget.onHome,
              child: const Text('Volver al inicio del panel'),
            ),
          ],
        ),
      ),
    ),
  );
}
