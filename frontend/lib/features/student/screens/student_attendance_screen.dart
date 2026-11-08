import 'dart:async';

import 'package:flutter/material.dart';

import '../student_api.dart';
import '../student_course.dart';
import '../student_attendance.dart';
import '../student_profile.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({
    super.key,
    required this.apiFactory,
    required this.onUnauthorized,
    required this.onHome,
  });
  final StudentApi Function() apiFactory;
  final VoidCallback onUnauthorized;
  final VoidCallback onHome;
  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  late final StudentApi _api;
  List<StudentEnrollment> _enrollments = [];
  List<StudentCourse> _courses = [];
  List<StudentAttendance> _records = [];
  StudentAttendance? _detail;
  AttendancePage? _page;
  final _from = TextEditingController();
  final _to = TextEditingController();
  Map<String, String> _query = {};
  String? _filterError;
  int? _enrollment;
  int _course = 0;
  int? _record;
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
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _load({int? enrollment, int course = 0, int? record}) async {
    final generation = ++_generation;
    setState(() {
      if (_enrollment != enrollment) _courses = [];
      _enrollment = enrollment;
      _course = course;
      _record = record;
      _records = [];
      _page = null;
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
      } else if (record == null) {
        final data = await _api.get('matriculas/$enrollment/cursos') as List;
        final courses = data
            .map((e) => StudentCourse.fromJson(e as Map<String, dynamic>))
            .toList();
        final path = course == 0
            ? 'matriculas/$enrollment/asistencias'
            : 'matriculas/$enrollment/cursos/$course/asistencias';
        final page = AttendancePage.fromJson(
          await _api.get(path, query: _query) as Map<String, dynamic>,
        );
        if (!mounted || generation != _generation) return;
        setState(() {
          _courses = courses;
          _records = page.registros;
          _page = page;
        });
      } else {
        final detail = StudentAttendance.fromJson(
          await _api.get('matriculas/$enrollment/asistencias/$record')
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
      'La matrícula, el curso o la asistencia no está disponible.',
    StudentFailureKind.network => 'No se pudo conectar. Comprueba tu conexión.',
    StudentFailureKind.validation =>
      'Comprueba las fechas y vuelve a aplicar los filtros.',
    _ => 'No se pudieron cargar las asistencias. Inténtalo nuevamente.',
  };
  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  Widget _summary(StudentAttendance record) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Curso: ${record.curso}'),
      Text('Periodo: ${record.periodo}'),
      Text('Fecha: ${_date(record.fecha).split(' ').first}'),
      Text('Estado: ${record.estadoLabel}'),
    ],
  );

  void _applyDates({bool clear = false}) {
    if (clear) {
      _from.clear();
      _to.clear();
    }
    final from = _from.text.trim(), to = _to.text.trim();
    if ((from.isNotEmpty && !validAttendanceDate(from)) ||
        (to.isNotEmpty && !validAttendanceDate(to)) ||
        (from.isNotEmpty && to.isNotEmpty && from.compareTo(to) > 0)) {
      setState(() {
        _filterError = 'Usa fechas válidas AAAA-MM-DD y un rango en orden.';
        _page = null;
        _records = [];
        _detail = null;
      });
      return;
    }
    setState(() {
      _filterError = null;
      _query = {
        if (from.isNotEmpty) 'desde': from,
        if (to.isNotEmpty) 'hasta': to,
      };
    });
    unawaited(_load(enrollment: _enrollment, course: _course));
  }

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
              _record == null ? 'Mis asistencias' : 'Detalle de la asistencia',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Solo se cuentan registros de asistencia existentes.'),
            const SizedBox(height: 16),
            if (_enrollments.isNotEmpty)
              DropdownButtonFormField<int>(
                key: ValueKey('record-enrollment-$_enrollment'),
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
                key: ValueKey('record-course-$_course'),
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
            if (_enrollment != null) ...[
              TextField(
                key: const ValueKey('attendance-from'),
                controller: _from,
                enabled: !_loading,
                decoration: const InputDecoration(
                  labelText: 'Desde (AAAA-MM-DD)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('attendance-to'),
                controller: _to,
                enabled: !_loading,
                decoration: const InputDecoration(
                  labelText: 'Hasta (AAAA-MM-DD)',
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _loading ? null : () => _applyDates(),
                    child: const Text('Aplicar fechas'),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () => _applyDates(clear: true),
                    child: const Text('Limpiar fechas'),
                  ),
                ],
              ),
              if (_filterError != null) Text(_filterError!),
              if (_query.isNotEmpty)
                Text(
                  'Rango consultado: ${_query['desde'] ?? 'sin inicio'} — ${_query['hasta'] ?? 'sin fin'}',
                ),
            ],
            if (!_loading &&
                _error == null &&
                _filterError == null &&
                _detail == null &&
                _page != null &&
                _page!.total > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resumen de registros consultados'),
                      Text('Total: ${_page!.total}'),
                      Text('Presentes: ${_page!.presente}'),
                      Text('Faltas: ${_page!.falta}'),
                      Text('Tardanzas: ${_page!.tardanza}'),
                      Text('Justificadas: ${_page!.justificada}'),
                    ],
                  ),
                ),
              ),
            if (_loading) ...[
              const Center(child: CircularProgressIndicator()),
              const Text('Cargando asistencias…'),
            ] else if (_error != null) ...[
              Text(_message),
              if (_error != StudentFailureKind.unauthorized &&
                  _error != StudentFailureKind.forbidden)
                OutlinedButton(
                  onPressed: () => _load(
                    enrollment: _enrollment,
                    course: _course,
                    record: _record,
                  ),
                  child: const Text('Reintentar'),
                ),
            ] else if (_filterError != null)
              const Text('Corrige el rango para consultar los registros.')
            else if (_enrollments.isEmpty)
              const Text('No tienes matrículas registradas.')
            else if (_enrollment == null)
              const Text(
                'Selecciona una matrícula y periodo para consultar sus asistencias.',
              )
            else if (_detail case final record?)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asistencia del ${_date(record.fecha).split(' ').first}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _summary(record),
                      Text('Docente: ${record.docente}'),
                      Text('Nivel: ${record.nivel}'),
                      Text('Grado: ${record.grado}'),
                      Text('Sección: ${record.seccion}'),
                      Text('Registrada: ${_date(record.registradoEn)}'),
                      const SizedBox(height: 12),
                      Text(
                        record.observacion?.trim().isNotEmpty == true
                            ? record.observacion!
                            : 'Sin observaciones registradas.',
                      ),
                    ],
                  ),
                ),
              )
            else if (_records.isEmpty)
              const Text('No hay asistencias registradas para esta selección.')
            else
              for (final record in _records)
                Card(
                  child: ListTile(
                    title: Text(
                      '${_date(record.fecha).split(' ').first} · ${record.curso}',
                    ),
                    subtitle: _summary(record),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _load(
                      enrollment: _enrollment,
                      course: _course,
                      record: record.id,
                    ),
                  ),
                ),
            if (_record != null && !_loading)
              OutlinedButton(
                onPressed: () =>
                    _load(enrollment: _enrollment, course: _course),
                child: const Text('Volver a asistencias'),
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
