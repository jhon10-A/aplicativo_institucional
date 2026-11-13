import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../student_api.dart';
import '../student_attendance.dart';
import '../student_course.dart';
import '../student_enrollment_selection.dart';
import '../student_grade.dart';
import '../student_profile.dart';
import '../student_section.dart';
import '../student_task.dart';
import '../student_theme.dart';

class StudentQuickViewResult {
  const StudentQuickViewResult(this.section, this.enrollmentId, [this.itemId]);
  final StudentSection section;
  final int enrollmentId;
  final int? itemId;
}

Future<StudentQuickViewResult?> showStudentQuickView({
  required BuildContext context,
  required StudentSection section,
  required StudentApi Function() apiFactory,
  required VoidCallback onUnauthorized,
  required ValueChanged<int?> onEnrollmentChanged,
  int? enrollmentId,
}) {
  final theme = studentTheme(Theme.of(context));
  return showGeneralDialog<StudentQuickViewResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar vista rápida',
    barrierColor: Colors.black.withValues(alpha: .45),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) => Theme(
      data: theme,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: StudentQuickView(
          section: section,
          apiFactory: apiFactory,
          initialEnrollmentId: enrollmentId,
          onUnauthorized: onUnauthorized,
          onEnrollmentChanged: onEnrollmentChanged,
        ),
      ),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class StudentQuickView extends StatefulWidget {
  const StudentQuickView({
    super.key,
    required this.section,
    required this.apiFactory,
    required this.onUnauthorized,
    required this.onEnrollmentChanged,
    this.initialEnrollmentId,
  });
  final StudentSection section;
  final StudentApi Function() apiFactory;
  final VoidCallback onUnauthorized;
  final ValueChanged<int?> onEnrollmentChanged;
  final int? initialEnrollmentId;
  @override
  State<StudentQuickView> createState() => _StudentQuickViewState();
}

class _StudentQuickViewState extends State<StudentQuickView> {
  late final StudentApi _api;
  List<StudentEnrollment> _enrollments = [];
  int? _selected;
  bool _loading = true;
  bool _loadedEnrollments = false;
  int _generation = 0;
  StudentFailureKind? _error;
  List<StudentCourse> _courses = [];
  List<StudentTask> _tasks = [];
  List<StudentGrade> _grades = [];
  AttendancePage? _attendance;
  String get _title => switch (widget.section) {
    StudentSection.cursos => 'Mis Cursos',
    StudentSection.tareas => 'Mis Tareas',
    StudentSection.calificaciones => 'Mis Notas',
    StudentSection.progreso => 'Mi Progreso',
    _ => 'Asistencia',
  };
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

  Future<void> _load({int? enrollment}) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _courses = [];
      _tasks = [];
      _grades = [];
      _attendance = null;
    });
    try {
      if (!_loadedEnrollments) {
        final data = await _api.get('matriculas') as List;
        if (!mounted || generation != _generation) return;
        _enrollments = data
            .map((e) => StudentEnrollment.fromJson(e as Map<String, dynamic>))
            .toList();
        _loadedEnrollments = true;
      }
      _selected = resolveStudentEnrollment(
        _enrollments,
        enrollment ?? _selected ?? widget.initialEnrollmentId,
      );
      widget.onEnrollmentChanged(_selected);
      final id = _selected;
      if (id != null) {
        final root = 'matriculas/$id';
        switch (widget.section) {
          case StudentSection.cursos:
            final data = await _api.get('$root/cursos') as List;
            if (!mounted || generation != _generation) return;
            _courses = data
                .map((e) => StudentCourse.fromJson(e as Map<String, dynamic>))
                .toList();
          case StudentSection.tareas:
            final data = await _api.get('$root/tareas') as List;
            if (!mounted || generation != _generation) return;
            _tasks = data
                .map((e) => StudentTask.fromJson(e as Map<String, dynamic>))
                .toList();
          case StudentSection.calificaciones:
            final data = await _api.get('$root/calificaciones') as List;
            if (!mounted || generation != _generation) return;
            _grades = data
                .map((e) => StudentGrade.fromJson(e as Map<String, dynamic>))
                .toList();
          case StudentSection.progreso:
            final responses = await Future.wait([
              _api.get('$root/calificaciones'),
              _api.get('$root/tareas'),
            ]);
            if (!mounted || generation != _generation) return;
            _grades = (responses[0] as List)
                .map((e) => StudentGrade.fromJson(e as Map<String, dynamic>))
                .toList();
            _tasks = (responses[1] as List)
                .map((e) => StudentTask.fromJson(e as Map<String, dynamic>))
                .toList();
          case StudentSection.asistencia:
            final data =
                await _api.get('$root/asistencias') as Map<String, dynamic>;
            if (!mounted || generation != _generation) return;
            _attendance = AttendancePage.fromJson(data);
          default:
            throw const StudentFailure(StudentFailureKind.invalid);
        }
      }
      if (!mounted || generation != _generation) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted || generation != _generation) return;
      final kind = e is StudentFailure ? e.kind : StudentFailureKind.invalid;
      setState(() {
        _loading = false;
        _error = kind;
      });
      if (kind == StudentFailureKind.unauthorized) {
        Navigator.of(context).pop();
        widget.onUnauthorized();
      }
    }
  }

  void _open([int? item, StudentSection? destination]) {
    final id = _selected;
    if (id != null) {
      Navigator.of(context).pop(
        StudentQuickViewResult(
          destination ??
              (widget.section == StudentSection.progreso
                  ? StudentSection.calificaciones
                  : widget.section),
          id,
          item,
        ),
      );
    }
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  Widget _item({
    required String title,
    required String subtitle,
    required int id,
    String? value,
    StudentSection? destination,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: const Color(0xFFF0F7FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD5E5F7)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: value == null
            ? const Icon(Icons.arrow_forward_rounded, size: 20)
            : Text(
                value,
                style: const TextStyle(
                  color: studentNavy,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
        onTap: () => _open(id, destination),
      ),
    ),
  );
  List<Widget> _content() {
    if (_loading) {
      return [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        const Text('Cargando información…', textAlign: TextAlign.center),
      ];
    }
    if (_error != null) {
      return [
        Text(switch (_error) {
          StudentFailureKind.forbidden =>
            'No tienes acceso a esta información.',
          StudentFailureKind.missingProfile =>
            'No tienes un perfil de estudiante registrado.',
          StudentFailureKind.unavailable =>
            'La información no está disponible para esta matrícula.',
          _ => 'No se pudo cargar la información. Comprueba la conexión e inténtalo nuevamente.',
        }),
        if (_error != StudentFailureKind.forbidden)
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
      ];
    }
    if (_enrollments.isEmpty) {
      return [const Text('No tienes matrículas registradas.')];
    }
    if (_selected == null) {
      return [
        const Text('Elige el periodo académico para consultar tus datos.'),
      ];
    }
    return switch (widget.section) {
      StudentSection.cursos =>
        _courses.isEmpty
            ? [const Text('No hay cursos asignados a esta matrícula.')]
            : [
                for (final c in _courses)
                  _item(
                    title: c.nombre,
                    subtitle:
                        'Docente: ${c.docente}\n${c.grado} · Sección ${c.seccion}',
                    id: c.asignacionId,
                  ),
              ],
      StudentSection.tareas =>
        _tasks.isEmpty
            ? [const Text('No hay tareas registradas para esta matrícula.')]
            : [
                for (final t in _tasks)
                  _item(
                    title: t.titulo,
                    subtitle:
                        '${t.curso}\nFecha límite: ${_date(t.fechaLimite)} · ${t.estado}',
                    id: t.id,
                  ),
              ],
      StudentSection.calificaciones =>
        _grades.isEmpty
            ? [
                const Text(
                  'No hay calificaciones registradas para esta matrícula.',
                ),
              ]
            : [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Notas registradas · escala de 0 a 20. Sin promedios calculados.',
                  ),
                ),
                for (final g in _grades)
                  _item(
                    title: g.curso,
                    subtitle: '${g.etapa} · ${g.concepto}',
                    id: g.id,
                    value: g.nota.toStringAsFixed(2),
                  ),
              ],
      StudentSection.progreso => [
        const Padding(
          padding: EdgeInsets.only(bottom: 18),
          child: Text(
            'El sistema no define un promedio ni un porcentaje de progreso. Este seguimiento muestra únicamente tus calificaciones registradas y el estado de tus tareas.',
          ),
        ),
        if (_grades.isEmpty && _tasks.isEmpty)
          const Text(
            'Aún no hay calificaciones ni tareas registradas para mostrar tu seguimiento académico.',
          ),
        if (_grades.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Calificaciones registradas',
              style: TextStyle(fontWeight: FontWeight.w800, color: studentNavy),
            ),
          ),
          for (final g in _grades)
            _item(
              title: g.curso,
              subtitle: '${g.etapa} · ${g.concepto}',
              id: g.id,
              value: g.nota.toStringAsFixed(2),
              destination: StudentSection.calificaciones,
            ),
        ],
        if (_tasks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Estado de tus tareas',
              style: TextStyle(fontWeight: FontWeight.w800, color: studentNavy),
            ),
          ),
          for (final t in _tasks)
            _item(
              title: t.titulo,
              subtitle:
                  '${t.curso} · ${t.estado}\nFecha límite: ${_date(t.fechaLimite)}',
              id: t.id,
              destination: StudentSection.tareas,
            ),
        ],
      ],
      StudentSection.asistencia =>
        _attendance == null || _attendance!.registros.isEmpty
            ? [
                const Text(
                  'No hay asistencias registradas para esta matrícula.',
                ),
              ]
            : [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Presente: ${_attendance!.presente}')),
                      Chip(label: Text('Falta: ${_attendance!.falta}')),
                      Chip(label: Text('Tardanza: ${_attendance!.tardanza}')),
                      Chip(
                        label: Text('Justificada: ${_attendance!.justificada}'),
                      ),
                    ],
                  ),
                ),
                for (final a in _attendance!.registros)
                  _item(
                    title: a.curso,
                    subtitle: '${_date(a.fecha)} · ${a.estadoLabel}',
                    id: a.id,
                  ),
              ],
      _ => [],
    };
  }

  @override
  Widget build(BuildContext context) => Dialog(
    key: const ValueKey('student-quick-view'),
    insetPadding: const EdgeInsets.all(12),
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: SizedBox(
      width: 560,
      height: (MediaQuery.sizeOf(context).height - 32).clamp(0, 700),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [studentWine, Color(0xFF900840)],
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFF2BD36), width: 3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'I.E. MICAELA BASTIDAS PUYUCAHUA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: 'Cerrar vista rápida',
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .15),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_loadedEnrollments && _enrollments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _selected == null
                                ? 'Periodo académico'
                                : 'Periodo ${_enrollments.firstWhere((m) => m.id == _selected).periodo}',
                            style: const TextStyle(color: Color(0xFF617991)),
                          ),
                          if (_enrollments.length > 1)
                            PopupMenuButton<int>(
                              tooltip: 'Cambiar matrícula en vista rápida',
                              enabled: !_loading,
                              onSelected: (id) =>
                                  unawaited(_load(enrollment: id)),
                              itemBuilder: (_) => [
                                for (final m in _enrollments)
                                  PopupMenuItem(
                                    value: m.id,
                                    child: Text(
                                      '${m.periodo} · ${m.grado} · Sección ${m.seccion}',
                                    ),
                                  ),
                              ],
                              icon: const Icon(Icons.expand_more),
                            ),
                        ],
                      ),
                    ),
                  ..._content(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading || _selected == null || _error != null
                    ? null
                    : () => _open(),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(
                  widget.section == StudentSection.asistencia
                      ? 'Ver historial completo'
                      : widget.section == StudentSection.progreso
                      ? 'Ver calificaciones completas'
                      : 'Abrir pantalla completa',
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
