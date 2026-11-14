import '../student_enrollment_selection.dart';
import '../widgets/student_presentation.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../student_api.dart';
import '../student_course.dart';
import '../student_profile.dart';
import '../student_task.dart';
import 'student_submission_screen.dart';

class StudentTasksScreen extends StatefulWidget {
  const StudentTasksScreen({
    super.key,
    required this.apiFactory,
    required this.onUnauthorized,
    required this.onHome,
    this.initialEnrollmentId,
    this.initialTaskId,
    this.onEnrollmentChanged,
  });
  final StudentApi Function() apiFactory;
  final VoidCallback onUnauthorized;
  final VoidCallback onHome;
  final int? initialEnrollmentId;
  final int? initialTaskId;
  final ValueChanged<int?>? onEnrollmentChanged;
  @override
  State<StudentTasksScreen> createState() => _StudentTasksScreenState();
}

class _StudentTasksScreenState extends State<StudentTasksScreen> {
  late final StudentApi _api;
  List<StudentEnrollment> _enrollments = [];
  List<StudentCourse> _courses = [];
  List<StudentTask> _tasks = [];
  StudentTask? _detail;
  int? _enrollment;
  int _course = 0;
  int? _task;
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
  void didUpdateWidget(covariant StudentTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.initialEnrollmentId;
    if (id != null &&
        id != oldWidget.initialEnrollmentId &&
        id != _enrollment &&
        _enrollments.any((m) => m.id == id)) {
      unawaited(_load(enrollment: id));
    }
  }

  Future<void> _load({int? enrollment, int course = 0, int? task}) async {
    if (enrollment != null) widget.onEnrollmentChanged?.call(enrollment);
    final generation = ++_generation;
    setState(() {
      if (_enrollment != enrollment) _courses = [];
      _enrollment = enrollment;
      _course = course;
      _task = task;
      _tasks = [];
      _detail = null;
      _loading = true;
      _error = null;
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
          await _load(enrollment: selected, task: widget.initialTaskId);
          return;
        }
      } else if (task == null) {
        final data = await _api.get('matriculas/$enrollment/cursos') as List;
        final courses = data
            .map((e) => StudentCourse.fromJson(e as Map<String, dynamic>))
            .toList();
        final path = course == 0
            ? 'matriculas/$enrollment/tareas'
            : 'matriculas/$enrollment/cursos/$course/tareas';
        final items = await _api.get(path) as List;
        final tasks = items
            .map((e) => StudentTask.fromJson(e as Map<String, dynamic>))
            .toList();
        if (!mounted || generation != _generation) return;
        setState(() {
          _courses = courses;
          _tasks = tasks;
        });
      } else {
        final detail = StudentTask.fromJson(
          await _api.get('matriculas/$enrollment/tareas/$task')
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
        _error = kind;
        _loading = false;
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

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  String get _message => switch (_error) {
    StudentFailureKind.unauthorized =>
      'Tu sesión ha vencido. Vuelve a iniciar sesión.',
    StudentFailureKind.forbidden => 'No tienes acceso al módulo Estudiante.',
    StudentFailureKind.missingProfile =>
      'No tienes un perfil de estudiante registrado.',
    StudentFailureKind.unavailable =>
      'La matrícula, el curso o la tarea no está disponible.',
    StudentFailureKind.network => 'No se pudo conectar. Comprueba tu conexión.',
    _ => 'No se pudieron cargar las tareas. Inténtalo nuevamente.',
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
    if (RegExp(r'^[1-9][0-9]*$').hasMatch(normalized)) {
      return '$normalized.º grado';
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

  Widget _summary(StudentTask task) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Curso: ${task.curso}'),
      Text('Docente: ${task.docente}'),
      Text('Fecha límite: ${_date(task.fechaLimite)}'),
      Text('Estado de entrega: ${task.estado}'),
    ],
  );
  Widget _field(String label, String? value) => Text(
    '$label: ${value?.trim().isNotEmpty == true ? value : 'No registrado'}',
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
              title: _task == null ? 'Mis tareas' : 'Detalle de la tarea',
              icon: Icons.assignment_outlined,
            ),
            const SizedBox(height: 16),
            if (_selectedEnrollment case final enrollment?)
              _enrollmentHeading(enrollment),
            if (_showEnrollmentSelector)
              DropdownButtonFormField<int>(
                key: ValueKey('task-enrollment-$_enrollment'),
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
                key: ValueKey('task-course-$_course'),
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
              const Text('Cargando tareas…'),
            ] else if (_error != null) ...[
              Text(_message),
              if (_error != StudentFailureKind.unauthorized &&
                  _error != StudentFailureKind.forbidden)
                OutlinedButton(
                  onPressed: () => _load(
                    enrollment: _enrollment,
                    course: _course,
                    task: _task,
                  ),
                  child: const Text('Reintentar'),
                ),
            ] else if (_enrollments.isEmpty)
              const Text('No tienes matrículas registradas.')
            else if (_enrollment == null)
              const Text('Selecciona una matrícula para consultar sus tareas.')
            else if (_detail case final task?)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.titulo,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _summary(task),
                      Text('Publicación: ${_date(task.fechaPublicacion)}'),
                      Text('Puntaje máximo: ${task.puntajeMaximo}'),
                      FilledButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => StudentSubmissionScreen(
                                api: _api,
                                enrollment: _enrollment!,
                                task: task,
                                onUnauthorized: () {
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst);
                                  widget.onUnauthorized();
                                },
                              ),
                            ),
                          );
                          if (mounted) {
                            unawaited(
                              _load(
                                enrollment: _enrollment,
                                course: _course,
                                task: task.id,
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          task.entrega == null
                              ? Icons.upload
                              : Icons.assignment_turned_in,
                        ),
                        label: Text(
                          task.entrega == null
                              ? 'Entregar tarea'
                              : 'Consultar mi entrega',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        task.descripcion?.trim().isNotEmpty == true
                            ? task.descripcion!
                            : 'Sin descripción registrada.',
                      ),
                      if (task.archivoUrl?.trim().isNotEmpty == true)
                        SelectableText(
                          'Archivo de la tarea: ${task.archivoUrl}',
                        ),
                      if (task.entrega case final submission?) ...[
                        const Divider(),
                        Text(
                          'Mi entrega',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Fecha de entrega: ${_date(submission.fechaEntrega)}',
                        ),
                        _field('Comentario', submission.comentario),
                        if (submission.archivoUrl?.trim().isNotEmpty == true)
                          SelectableText(
                            'Archivo de mi entrega: ${submission.archivoUrl}',
                          ),
                        Text(
                          'Puntaje: ${submission.puntaje?.toString() ?? 'Sin calificar'}',
                        ),
                        _field(
                          'Retroalimentación',
                          submission.retroalimentacion,
                        ),
                        if (submission.fechaRevision case final date?)
                          Text('Fecha de revisión: ${_date(date)}'),
                      ],
                    ],
                  ),
                ),
              )
            else if (_tasks.isEmpty)
              const Text('No hay tareas disponibles para esta selección.')
            else
              for (final task in _tasks)
                Card(
                  child: ListTile(
                    title: Text(task.titulo),
                    subtitle: _summary(task),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _load(
                      enrollment: _enrollment,
                      course: _course,
                      task: task.id,
                    ),
                  ),
                ),
            if (_task != null && !_loading)
              OutlinedButton(
                onPressed: () =>
                    _load(enrollment: _enrollment, course: _course),
                child: const Text('Volver a tareas'),
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
