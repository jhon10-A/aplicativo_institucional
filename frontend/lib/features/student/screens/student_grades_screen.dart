import 'dart:async';

import 'package:flutter/material.dart';

import '../student_api.dart';
import '../student_course.dart';
import '../student_grade.dart';
import '../student_profile.dart';

class StudentGradesScreen extends StatefulWidget {
  const StudentGradesScreen({
    super.key,
    required this.apiFactory,
    required this.onUnauthorized,
    required this.onHome,
  });
  final StudentApi Function() apiFactory;
  final VoidCallback onUnauthorized;
  final VoidCallback onHome;
  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  late final StudentApi _api;
  List<StudentEnrollment> _enrollments = [];
  List<StudentCourse> _courses = [];
  List<StudentGrade> _grades = [];
  StudentGrade? _detail;
  int? _enrollment;
  int _course = 0;
  int? _grade;
  int _generation = 0;
  bool _loading = true;
  StudentFailureKind? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.apiFactory();
    unawaited(_load());
  }

  @override
  void dispose() {
    ++_generation;
    _api.dispose();
    super.dispose();
  }

  Future<void> _load({int? enrollment, int course = 0, int? grade}) async {
    final generation = ++_generation;
    setState(() {
      if (_enrollment != enrollment) _courses = [];
      _enrollment = enrollment;
      _course = course;
      _grade = grade;
      _grades = [];
      _detail = null;
      _error = null;
      _loading = true;
    });
    try {
      if (enrollment == null) {
        final data = await _api.get('matriculas') as List;
        final enrollments = data
            .map((e) => StudentEnrollment.fromJson(e as Map<String, dynamic>))
            .toList();
        if (!mounted || generation != _generation) return;
        setState(() => _enrollments = enrollments);
      } else if (grade == null) {
        final data = await _api.get('matriculas/$enrollment/cursos') as List;
        final courses = data
            .map((e) => StudentCourse.fromJson(e as Map<String, dynamic>))
            .toList();
        final path = course == 0
            ? 'matriculas/$enrollment/calificaciones'
            : 'matriculas/$enrollment/cursos/$course/calificaciones';
        final items = await _api.get(path) as List;
        final grades = items
            .map((e) => StudentGrade.fromJson(e as Map<String, dynamic>))
            .toList();
        if (!mounted || generation != _generation) return;
        setState(() {
          _courses = courses;
          _grades = grades;
        });
      } else {
        final detail = StudentGrade.fromJson(
          await _api.get('matriculas/$enrollment/calificaciones/$grade')
              as Map<String, dynamic>,
        );
        if (!mounted || generation != _generation) return;
        setState(() => _detail = detail);
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted || generation != _generation) return;
      final kind = e is StudentFailure ? e.kind : StudentFailureKind.invalid;
      setState(() {
        _error = kind;
        _loading = false;
      });
      if (kind == StudentFailureKind.unauthorized) widget.onUnauthorized();
    }
  }

  String get _message => switch (_error) {
    StudentFailureKind.unauthorized =>
      'Tu sesión ha vencido. Vuelve a iniciar sesión.',
    StudentFailureKind.forbidden => 'No tienes acceso al módulo Estudiante.',
    StudentFailureKind.missingProfile =>
      'No tienes un perfil de estudiante registrado.',
    StudentFailureKind.unavailable =>
      'La matrícula, el curso o la calificación no está disponible.',
    StudentFailureKind.network => 'No se pudo conectar. Comprueba tu conexión.',
    _ => 'No se pudieron cargar las calificaciones. Inténtalo nuevamente.',
  };
  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  Widget _summary(StudentGrade grade) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Curso: ${grade.curso}'),
      Text('Periodo: ${grade.periodo}'),
      Text('Etapa: ${grade.etapa}'),
      Text('Nota registrada: ${grade.nota.toStringAsFixed(2)} / 20'),
    ],
  );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _grade == null
                  ? 'Mis calificaciones'
                  : 'Detalle de la calificación',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Solo se muestran notas registradas.'),
            const SizedBox(height: 16),
            if (_enrollments.isNotEmpty)
              DropdownButtonFormField<int>(
                key: ValueKey('grade-enrollment-$_enrollment'),
                initialValue: _enrollment,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Matrícula y periodo',
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
                    : (id) {
                        if (id != null) unawaited(_load(enrollment: id));
                      },
              ),
            if (_enrollment != null && _courses.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: ValueKey('grade-course-$_course'),
                initialValue: _courses.any((c) => c.asignacionId == _course)
                    ? _course
                    : 0,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Curso'),
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Todos los cursos'),
                  ),
                  for (final c in _courses)
                    DropdownMenuItem(
                      value: c.asignacionId,
                      child: Text(
                        c.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _loading
                    ? null
                    : (id) {
                        if (id != null) {
                          unawaited(_load(enrollment: _enrollment, course: id));
                        }
                      },
              ),
            ],
            const SizedBox(height: 16),
            if (_loading) ...[
              const Center(child: CircularProgressIndicator()),
              const Text('Cargando calificaciones…'),
            ] else if (_error != null) ...[
              Text(_message),
              if (_error != StudentFailureKind.unauthorized &&
                  _error != StudentFailureKind.forbidden)
                OutlinedButton(
                  onPressed: () => _load(
                    enrollment: _enrollment,
                    course: _course,
                    grade: _grade,
                  ),
                  child: const Text('Reintentar'),
                ),
            ] else if (_enrollments.isEmpty)
              const Text('No tienes matrículas registradas.')
            else if (_enrollment == null)
              const Text(
                'Selecciona una matrícula y periodo para consultar sus calificaciones.',
              )
            else if (_detail case final grade?)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grade.concepto,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _summary(grade),
                      Text('Docente: ${grade.docente}'),
                      Text('Nivel: ${grade.nivel}'),
                      Text('Grado: ${grade.grado}'),
                      Text('Sección: ${grade.seccion}'),
                      Text('Registrada: ${_date(grade.registradoEn)}'),
                      const SizedBox(height: 12),
                      Text(
                        grade.observacion?.trim().isNotEmpty == true
                            ? grade.observacion!
                            : 'Sin observaciones registradas.',
                      ),
                    ],
                  ),
                ),
              )
            else if (_grades.isEmpty)
              const Text(
                'No hay calificaciones registradas para esta selección.',
              )
            else
              for (final grade in _grades)
                Card(
                  child: ListTile(
                    title: Text(grade.concepto),
                    subtitle: _summary(grade),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _load(
                      enrollment: _enrollment,
                      course: _course,
                      grade: grade.id,
                    ),
                  ),
                ),
            if (_grade != null && !_loading)
              OutlinedButton(
                onPressed: () =>
                    _load(enrollment: _enrollment, course: _course),
                child: const Text('Volver a calificaciones'),
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
