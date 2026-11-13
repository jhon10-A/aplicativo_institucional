import '../student_enrollment_selection.dart';
import '../student_profile.dart';
import '../student_schedule.dart';
import '../widgets/student_presentation.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../student_api.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({
    super.key,
    required this.apiFactory,
    required this.onUnauthorized,
    required this.onHome,
    this.initialEnrollmentId,
    this.onEnrollmentChanged,
  });

  final StudentApi Function() apiFactory;
  final VoidCallback onUnauthorized;
  final VoidCallback onHome;
  final int? initialEnrollmentId;
  final ValueChanged<int?>? onEnrollmentChanged;

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  late final StudentApi _api;
  List<StudentEnrollment> _enrollments = [];
  List<StudentSchedule> _schedule = [];
  int? _enrollment;
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

  @override
  void didUpdateWidget(covariant StudentScheduleScreen oldWidget) {
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
      _schedule = [];
      _enrollment = enrollment;
    });

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
        final selected = resolveStudentEnrollment(
          enrollments,
          widget.initialEnrollmentId,
        );
        widget.onEnrollmentChanged?.call(selected);
        if (selected != null) {
          await _load(enrollment: selected);
          return;
        }
      } else {
        widget.onEnrollmentChanged?.call(enrollment);
        final response =
            await _api.get('matriculas/$enrollment/horario') as List;
        final schedule = response
            .map(
              (item) => StudentSchedule.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        if (!mounted || generation != _generation) return;
        setState(() => _schedule = schedule);
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

  String get _message => switch (_error) {
    StudentFailureKind.unauthorized =>
      'Tu sesión ha vencido. Vuelve a iniciar sesión.',
    StudentFailureKind.forbidden => 'No tienes acceso al módulo Estudiante.',
    StudentFailureKind.missingProfile =>
      'No tienes un perfil de estudiante registrado.',
    StudentFailureKind.unavailable =>
      'La matrícula o el horario no está disponible.',
    StudentFailureKind.network =>
      'No se pudo conectar. Comprueba tu conexión e inténtalo nuevamente.',
    _ => 'No se pudo cargar el horario. Inténtalo nuevamente.',
  };

  List<StudentSchedule> _forDay(int weekday) =>
      _schedule.where((item) => item.diaSemana == weekday).toList();

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

  Widget _dayCard(int weekday, double width) {
    final daySchedule = _forDay(weekday);
    final day = const [
      '',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
    ][weekday];
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                day,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Divider(),
              if (daySchedule.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Sin clases programadas.'),
                )
              else
                for (final item in daySchedule)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.horaInicio}–${item.horaFin}',
                          style: const TextStyle(
                            color: Color(0xFF790738),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.curso,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('Docente: ${item.docente}'),
                        if (item.aulaDisponible case final room?)
                          Text('Aula: $room'),
                        if (item != daySchedule.last) const Divider(height: 16),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _week(double maxWidth) {
    const spacing = 12.0;
    final columns = maxWidth >= 1000
        ? 5
        : maxWidth >= 600
        ? 2
        : 1;
    final width = (maxWidth - spacing * (columns - 1)) / columns;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (var weekday = 1; weekday <= 5; weekday++) _dayCard(weekday, width),
      ],
    );
  }

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
              title: 'Mi Horario de Clases',
              icon: Icons.schedule_outlined,
            ),
            if (_selectedEnrollment case final enrollment?)
              _enrollmentHeader(enrollment),
            if (_showEnrollmentSelector)
              DropdownButtonFormField<int>(
                key: ValueKey('schedule-enrollment-$_enrollment'),
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
            const SizedBox(height: 12),
            if (_loading) ...[
              const Center(child: CircularProgressIndicator()),
              const Text('Cargando horario…'),
            ] else if (_error != null) ...[
              Text(_message),
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
              const Text('Selecciona una matrícula para consultar su horario.')
            else if (_schedule.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Todavía no hay horarios registrados para esta matrícula.',
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) => _week(constraints.maxWidth),
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
