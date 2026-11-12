import '../student_enrollment_selection.dart';
import '../widgets/student_presentation.dart';

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
    this.initialEnrollmentId,
    this.initialGradeId,
    this.onEnrollmentChanged,
  });
  final StudentApi Function() apiFactory;
  final VoidCallback onUnauthorized;
  final VoidCallback onHome;
  final int? initialEnrollmentId;
  final int? initialGradeId;
  final ValueChanged<int?>? onEnrollmentChanged;
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

  int? _resolveEnrollment(
    List<StudentEnrollment> enrollments,
    int? remembered,
  ) {
    if (enrollments.any((enrollment) => enrollment.id == remembered)) {
      return remembered;
    }
    if (enrollments.length == 1) {
      final enrollment = enrollments.single;
      return enrollment.estado == 'ACTIVA' && enrollment.periodoActivo
          ? enrollment.id
          : null;
    }
    return resolveStudentEnrollment(enrollments, null);
  }

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

  @override
  void didUpdateWidget(covariant StudentGradesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.initialEnrollmentId;
    if (id != null &&
        id != oldWidget.initialEnrollmentId &&
        id != _enrollment &&
        _enrollments.any((m) => m.id == id)) {
      unawaited(_load(enrollment: id));
    }
  }

  Future<void> _load({int? enrollment, int course = 0, int? grade}) async {
    if (enrollment != null) widget.onEnrollmentChanged?.call(enrollment);
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
        final selected = _resolveEnrollment(
          enrollments,
          widget.initialEnrollmentId,
        );
        widget.onEnrollmentChanged?.call(selected);
        if (selected != null) {
          await _load(enrollment: selected, grade: widget.initialGradeId);
          return;
        }
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

  StudentEnrollment? get _selectedEnrollment {
    for (final enrollment in _enrollments) {
      if (enrollment.id == _enrollment) return enrollment;
    }
    return null;
  }

  bool get _showEnrollmentSelector {
    if (_enrollments.length != 1) return _enrollments.isNotEmpty;
    final enrollment = _enrollments.single;
    return enrollment.estado != 'ACTIVA' || !enrollment.periodoActivo;
  }

  String _displayGrade(String grade) {
    final normalized = grade.trim().toLowerCase();
    if (normalized.contains('grado')) return grade.trim();
    const ordinals = {
      'primero': '1.º',
      'primer': '1.º',
      'segundo': '2.º',
      'tercero': '3.º',
      'tercer': '3.º',
      'cuarto': '4.º',
      'quinto': '5.º',
      'sexto': '6.º',
    };
    final ordinal = ordinals[normalized];
    if (ordinal != null) return '$ordinal grado';
    final numericGrade = RegExp(r'^([1-9][0-9]*)[.º°]*$')
        .firstMatch(normalized);
    if (numericGrade != null) {
      return '${numericGrade.group(1)}.º grado';
    }
    return normalized.isEmpty ? grade : '$grade grado';
  }

  String _displayLevel(String level) => level
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  Widget _enrollmentHeading(StudentEnrollment enrollment) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Año escolar: ${enrollment.inicio.year}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${_displayLevel(enrollment.nivel)} · '
            '${_displayGrade(enrollment.grado)} · '
            'Sección ${enrollment.seccion}',
          ),
          const SizedBox(height: 4),
          Text(
            'Matrícula: ${enrollment.estado == 'ACTIVA' ? 'Activa' : enrollment.estado}',
          ),
        ],
      ),
    ),
  );

  Map<String, List<StudentGrade>> get _gradesByCourse {
    final grouped = <String, List<StudentGrade>>{};
    for (final grade in _grades) {
      grouped.putIfAbsent(grade.curso, () => []).add(grade);
    }
    return grouped;
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  Widget _summary(StudentGrade grade) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Etapa: ${grade.etapa}'),
      Text('Nota registrada: ${grade.nota.toStringAsFixed(2)} / 20'),
      Text('Registrada: ${_date(grade.registradoEn)}'),
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
              title: _grade == null
                  ? 'Mis calificaciones'
                  : 'Detalle de la calificación',
              icon: Icons.grade_outlined,
            ),
            const SizedBox(height: 8),
            const Text('Solo se muestran notas registradas.'),
            const SizedBox(height: 16),
            if (_selectedEnrollment case final enrollment?)
              _enrollmentHeading(enrollment),
            if (_showEnrollmentSelector)
              DropdownButtonFormField<int>(
                key: ValueKey('grade-enrollment-$_enrollment'),
                initialValue: _enrollment,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Matrícula y año escolar',
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
                        '${m.inicio.year} · ${_displayLevel(m.nivel)} · '
                        '${_displayGrade(m.grado)} · Sección ${m.seccion} · '
                        '${m.estado == 'ACTIVA' ? 'Activa' : m.estado}',
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
                      Text('Curso: ${grade.curso}'),
                      _summary(grade),
                      Text('Docente: ${grade.docente}'),
                      Text('Nivel: ${grade.nivel}'),
                      Text('Grado: ${grade.grado}'),
                      Text('Sección: ${grade.seccion}'),
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
              for (final course in _gradesByCourse.entries)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            course.key,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        for (final grade in course.value)
                          ListTile(
                            title: Text(grade.concepto),
                            subtitle: _summary(grade),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _load(
                              enrollment: _enrollment,
                              course: _course,
                              grade: grade.id,
                            ),
                          ),
                      ],
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
