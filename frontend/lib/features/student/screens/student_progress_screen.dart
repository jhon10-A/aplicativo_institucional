import '../student_enrollment_selection.dart';
import '../widgets/student_presentation.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../student_api.dart';
import '../student_grade.dart';
import '../student_profile.dart';
import '../student_task.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({
    super.key,
    required this.apiFactory,
    required this.onUnauthorized,
    required this.onHome,
    required this.onOpenTask,
    required this.onOpenGrade,
    this.initialEnrollmentId,
    this.onEnrollmentChanged,
  });

  final StudentApi Function() apiFactory;
  final VoidCallback onUnauthorized;
  final VoidCallback onHome;
  final ValueChanged<int> onOpenTask;
  final ValueChanged<int> onOpenGrade;
  final int? initialEnrollmentId;
  final ValueChanged<int?>? onEnrollmentChanged;

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  late final StudentApi _api;
  List<StudentEnrollment> _enrollments = [];
  List<StudentTask> _tasks = [];
  List<StudentGrade> _grades = [];
  int? _enrollment;
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
  void didUpdateWidget(covariant StudentProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.initialEnrollmentId;
    if (id != null &&
        id != oldWidget.initialEnrollmentId &&
        id != _enrollment &&
        _enrollments.any((enrollment) => enrollment.id == id)) {
      unawaited(_load(enrollment: id));
    }
  }

  Future<void> _load({int? enrollment}) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _tasks = [];
      _grades = [];
      _enrollment = enrollment;
    });
    if (enrollment != null) {
      widget.onEnrollmentChanged?.call(enrollment);
    }

    try {
      if (enrollment == null) {
        final response = await _api.get('matriculas') as List;
        final enrollments = response
            .map(
              (item) =>
                  StudentEnrollment.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        if (!mounted || generation != _generation) return;
        setState(() => _enrollments = enrollments);
        final selected = _resolveEnrollment(
          enrollments,
          widget.initialEnrollmentId,
        );
        widget.onEnrollmentChanged?.call(selected);
        if (selected != null) {
          await _load(enrollment: selected);
          return;
        }
      } else {
        final responses = await Future.wait([
          _api.get('matriculas/$enrollment/tareas'),
          _api.get('matriculas/$enrollment/calificaciones'),
        ]);
        if (!mounted || generation != _generation) return;
        setState(() {
          _tasks = (responses[0] as List)
              .map((item) => StudentTask.fromJson(item as Map<String, dynamic>))
              .toList();
          _grades = (responses[1] as List)
              .map(
                (item) => StudentGrade.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        });
      }
      if (!mounted || generation != _generation) return;
      setState(() => _loading = false);
    } catch (exception) {
      if (!mounted || generation != _generation) return;
      final kind = exception is StudentFailure
          ? exception.kind
          : StudentFailureKind.invalid;
      setState(() {
        _error = kind;
        _loading = false;
      });
      if (kind == StudentFailureKind.unauthorized) {
        widget.onUnauthorized();
      }
    }
  }

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
    final value = grade.trim();
    final normalized = value.toLowerCase();
    if (normalized.contains('grado')) return value;
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
    if (ordinals[normalized] case final ordinal?) return '$ordinal grado';
    final numericGrade = RegExp(r'^([1-9][0-9]*)[.º°]*$')
        .firstMatch(normalized);
    if (numericGrade != null) return '${numericGrade.group(1)}.º grado';
    return value.isEmpty ? grade : '$value grado';
  }

  String _displayLevel(String level) => level
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Map<String, List<StudentGrade>> get _gradesByCourse {
    final grouped = <String, List<StudentGrade>>{};
    for (final grade in _grades) {
      grouped.putIfAbsent(grade.curso, () => []).add(grade);
    }
    return grouped;
  }

  Widget _enrollmentHeader(StudentEnrollment enrollment) => Card(
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

  Widget _taskSummary() {
    final counts = <String, int>{
      'Pendientes': 0,
      'Entregadas': 0,
      'Revisadas': 0,
      'Vencidas': 0,
    };
    for (final task in _tasks) {
      switch (task.estado) {
        case 'Pendiente':
          counts['Pendientes'] = counts['Pendientes']! + 1;
        case 'Entregada':
          counts['Entregadas'] = counts['Entregadas']! + 1;
        case 'Revisada':
          counts['Revisadas'] = counts['Revisadas']! + 1;
        case 'Vencida':
          counts['Vencidas'] = counts['Vencidas']! + 1;
      }
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in counts.entries)
          Chip(label: Text('${entry.key}: ${entry.value}')),
      ],
    );
  }

  String get _errorMessage => switch (_error) {
    StudentFailureKind.unauthorized =>
      'Tu sesión ha vencido. Vuelve a iniciar sesión.',
    StudentFailureKind.forbidden => 'No tienes acceso al módulo Estudiante.',
    StudentFailureKind.missingProfile =>
      'No tienes un perfil de estudiante registrado.',
    StudentFailureKind.unavailable =>
      'La información no está disponible para esta matrícula.',
    StudentFailureKind.network =>
      'No se pudo conectar. Comprueba tu conexión e inténtalo nuevamente.',
    _ => 'No se pudo cargar Mi Progreso. Inténtalo nuevamente.',
  };

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
            const StudentSectionHeading(
              title: 'Mi Progreso',
              icon: Icons.bar_chart_rounded,
            ),
            const Text(
              'Seguimiento de tareas y calificaciones registradas. '
              'No se calculan porcentajes ni promedios.',
            ),
            const SizedBox(height: 16),
            if (_selectedEnrollment case final enrollment?)
              _enrollmentHeader(enrollment),
            if (_showEnrollmentSelector)
              DropdownButtonFormField<int>(
                key: ValueKey('progress-enrollment-$_enrollment'),
                initialValue: _enrollment,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Matrícula y año escolar',
                ),
                hint: const Text('Selecciona una matrícula'),
                items: [
                  for (final enrollment in _enrollments)
                    DropdownMenuItem(
                      value: enrollment.id,
                      child: Text(
                        '${enrollment.inicio.year} · '
                        '${_displayLevel(enrollment.nivel)} · '
                        '${_displayGrade(enrollment.grado)} · '
                        'Sección ${enrollment.seccion} · '
                        '${enrollment.estado == 'ACTIVA' ? 'Activa' : enrollment.estado}',
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
            const SizedBox(height: 16),
            if (_loading) ...[
              const Center(child: CircularProgressIndicator()),
              const Text('Cargando tu progreso…'),
            ] else if (_error != null) ...[
              Text(_errorMessage),
              if (_error != StudentFailureKind.unauthorized &&
                  _error != StudentFailureKind.forbidden)
                OutlinedButton.icon(
                  onPressed: () => _load(enrollment: _enrollment),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
            ] else if (_enrollments.isEmpty)
              const Text('No tienes matrículas registradas.')
            else if (_enrollment == null)
              const Text(
                'Selecciona una matrícula para consultar su progreso académico.',
              )
            else ...[
              Text(
                'Estado de las tareas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _taskSummary(),
              const SizedBox(height: 12),
              if (_tasks.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.assignment_outlined),
                    title: Text(
                      'No hay tareas registradas para esta matrícula.',
                    ),
                  ),
                )
              else
                for (final task in _tasks)
                  Card(
                    child: ListTile(
                      title: Text(task.titulo),
                      subtitle: Text(
                        '${task.curso} · ${task.estado}\n'
                        'Fecha límite: ${_date(task.fechaLimite)}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => widget.onOpenTask(task.id),
                    ),
                  ),
              const SizedBox(height: 12),
              Text(
                'Calificaciones por curso',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_grades.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.grade_outlined),
                    title: Text(
                      'No hay calificaciones registradas para esta matrícula.',
                    ),
                  ),
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
                              subtitle: Text(
                                '${grade.etapa} · ${grade.nota.toStringAsFixed(2)} / 20'
                                ' · ${_date(grade.registradoEn)}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => widget.onOpenGrade(grade.id),
                            ),
                        ],
                      ),
                    ),
                  ),
            ],
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
