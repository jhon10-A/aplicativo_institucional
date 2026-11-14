import '../student_enrollment_selection.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../student_api.dart';
import '../student_profile.dart';
import '../student_schedule.dart';
import '../student_home_summary.dart';
import '../student_section.dart';
import '../student_theme.dart';
import 'student_presentation.dart';

class StudentOverview extends StatefulWidget {
  const StudentOverview({
    super.key,
    required this.apiFactory,
    required this.onSelect,
    required this.onUnauthorized,
    this.onEnrollmentChanged,
    this.selectedEnrollmentId,
    this.onScheduleChanged,
    this.clock,
  });
  final StudentApi Function() apiFactory;
  final ValueChanged<StudentSection> onSelect;
  final VoidCallback onUnauthorized;
  final ValueChanged<StudentEnrollment?>? onEnrollmentChanged;
  final int? selectedEnrollmentId;
  final void Function(int? enrollmentId, StudentHomeScheduleSummary summary)?
  onScheduleChanged;
  final DateTime Function()? clock;
  @override
  State<StudentOverview> createState() => _StudentOverviewState();
}

class _StudentOverviewState extends State<StudentOverview> {
  late final StudentApi _api;
  List<StudentEnrollment> _enrollments = [];
  int? _selected;
  bool _loading = true, _failed = false;
  bool _expired = false;
  int _generation = 0;
  final Map<String, List<Map<String, dynamic>>> _data = {};
  List<StudentSchedule> _schedule = [];
  final Set<String> _busy = {}, _errors = {};
  Timer? _scheduleTicker;
  @override
  void initState() {
    super.initState();
    _api = widget.apiFactory();
    unawaited(_load());
    _scheduleTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _schedule.isNotEmpty) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant StudentOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.selectedEnrollmentId;
    if (id == oldWidget.selectedEnrollmentId || id == _selected || id == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.selectedEnrollmentId != id ||
          !_enrollments.any((m) => m.id == id)) {
        return;
      }
      setState(() => _selected = id);
      widget.onEnrollmentChanged?.call(
        _enrollments.firstWhere((m) => m.id == id),
      );
      _reload();
    });
  }

  @override
  void dispose() {
    _scheduleTicker?.cancel();
    ++_generation;
    _api.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload preserves the existing response and the authenticated session.
    _publishSchedule(
      _failed || _errors.contains('horario')
          ? const StudentHomeScheduleSummary.unavailable()
          : _loading || _busy.contains('horario')
          ? const StudentHomeScheduleSummary.loading()
          : _selected == null && _enrollments.isNotEmpty
          ? const StudentHomeScheduleSummary.selectionRequired()
          : StudentHomeScheduleSummary.loaded(_schedule),
      _generation,
    );
  }

  void _unauthorized(Object e) {
    if (!_expired &&
        e is StudentFailure &&
        e.kind == StudentFailureKind.unauthorized) {
      _expired = true;
      widget.onUnauthorized();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final response = await _api.get('matriculas') as List;
      if (!mounted) return;
      final list = response
          .map((e) => StudentEnrollment.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _enrollments = list;
        _selected = resolveStudentEnrollment(
          list,
          widget.selectedEnrollmentId ?? _selected,
        );
        _loading = false;
      });
      widget.onEnrollmentChanged?.call(
        _selected == null ? null : list.firstWhere((m) => m.id == _selected),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
      _unauthorized(e);
      final generation = ++_generation;
      _publishSchedule(
        const StudentHomeScheduleSummary.unavailable(),
        generation,
      );
      if (mounted && !_expired) {
        unawaited(_preview('comunicados', 'comunicados', generation));
      }
    }
  }

  void _reload() {
    final generation = ++_generation;
    setState(() {
      _data.clear();
      _schedule = [];
      _errors.clear();
      _busy.clear();
    });
    final id = _selected;
    _publishSchedule(
      id == null
          ? _enrollments.isEmpty
                ? const StudentHomeScheduleSummary.empty()
                : const StudentHomeScheduleSummary.selectionRequired()
          : const StudentHomeScheduleSummary.loading(),
      generation,
    );
    if (id != null) {
      unawaited(_preview('cursos', 'matriculas/$id/cursos', generation));
      unawaited(_preview('tareas', 'matriculas/$id/tareas', generation));
      unawaited(_preview('horario', 'matriculas/$id/horario', generation));
    }
    unawaited(
      _preview(
        'comunicados',
        id == null ? 'comunicados' : 'matriculas/$id/comunicados',
        generation,
      ),
    );
  }

  void _publishSchedule(StudentHomeScheduleSummary summary, int generation) {
    final enrollmentId = _selected;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      widget.onScheduleChanged?.call(enrollmentId, summary);
    });
  }

  Future<void> _preview(String key, String path, int generation) async {
    if (!mounted) return;
    setState(() {
      _busy.add(key);
      _errors.remove(key);
    });
    try {
      final response = await _api.get(path);
      if (!mounted || generation != _generation) return;
      if (key == 'horario') {
        final schedule = (response as List)
            .map(
              (item) => StudentSchedule.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        setState(() {
          _schedule = schedule;
          _busy.remove(key);
        });
        _publishSchedule(
          StudentHomeScheduleSummary.loaded(schedule),
          generation,
        );
        return;
      }
      var rows = (response as List).cast<Map<String, dynamic>>().toList();
      if (key == 'tareas') {
        rows = rows
            .where(
              (t) =>
                  t['estadoEntrega'] == 'PENDIENTE' &&
                  DateTime.tryParse(t['fechaLimite'] as String)
                          ?.isBefore(DateTime.now()) ==
                      false,
            )
            .toList();
        rows.sort(
          (a, b) => (a['fechaLimite'] as String).compareTo(
            b['fechaLimite'] as String,
          ),
        );
      }
      setState(() {
        _data[key] = rows;
        _busy.remove(key);
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _errors.add(key);
        _busy.remove(key);
      });
      _unauthorized(e);
      if (key == 'horario') {
        _publishSchedule(
          const StudentHomeScheduleSummary.unavailable(),
          generation,
        );
      }
    }
  }

  String _date(Object? value) {
    final d = DateTime.tryParse(value?.toString() ?? '');
    return d == null
        ? ''
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _scheduleSummary() {
    if (_busy.contains('horario')) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errors.contains('horario')) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No se pudo cargar esta información.'),
          ),
          TextButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }
    if (_selected == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Text(
          'Selecciona una matrícula para consultar su horario.',
          style: TextStyle(color: Color(0xFF617991), fontSize: 12, height: 1.5),
        ),
      );
    }
    if (_schedule.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Text(
          'Todavía no hay horarios registrados para esta matrícula.',
          style: TextStyle(color: Color(0xFF617991), fontSize: 12, height: 1.5),
        ),
      );
    }

    final preview = studentSchedulePreview(
      _schedule,
      instant: widget.clock?.call() ?? DateTime.now(),
      enrollment: _enrollments.where((m) => m.id == _selected).firstOrNull,
    );
    final visible = preview.sessions;
    return LayoutBuilder(
      builder: (context, box) {
        final compactPhone =
            box.maxWidth < 400 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                preview.heading,
                style: const TextStyle(fontSize: 11, color: studentNavy),
              ),
            ),
            if (visible.isNotEmpty)
              ColoredBox(
                color: const Color(0xFFF1F6FC),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: compactPhone
                        ? const [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Hora',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text(
                                'Curso · aula',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ]
                        : const [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Hora',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                'Curso',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Aula',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                  ),
                ),
              ),
            for (final item in visible)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: compactPhone
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.diaCorto} ${item.horaInicio}\n${item.horaFin}',
                              style: const TextStyle(fontSize: 11, height: 1.4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.curso,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Aula: ${item.aulaDisponible ?? '—'}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.diaCorto} ${item.horaInicio}\n${item.horaFin}',
                              style: const TextStyle(fontSize: 11, height: 1.4),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              item.curso,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.aulaDisponible ?? '—',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
              ),
            if (preview.remaining > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '${preview.remaining} clases más',
                  style: const TextStyle(
                    color: Color(0xFF617991),
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _body(String key, StudentSection section, String empty) {
    if (_busy.contains(key)) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errors.contains(key)) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No se pudo cargar esta información.'),
          ),
          TextButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }
    if (_selected == null && key != 'comunicados') {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Selecciona una matrícula para ver la información de este periodo.',
          style: TextStyle(color: Color(0xFF5C7186), height: 1.6),
        ),
      );
    }
    final received = _data[key] ?? [];
    final rows = key == 'comunicados'
        ? received.where(showStudentHomeNotice).toList()
        : received;
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          empty,
          style: const TextStyle(color: Color(0xFF5C7186), height: 1.6),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 480;
        final tiny = box.maxWidth < 230;
        const colors = [
          Color(0xFF008DE1),
          Color(0xFFEB557A),
          Color(0xFF279C41),
          Color(0xFF9048D0),
          Color(0xFFE99A00),
        ];
        final limit = key == 'cursos' ? 5 : 3;
        final remaining = rows.length - limit;
        final remainingKind = switch (key) {
          'cursos' => remaining == 1 ? 'curso' : 'cursos',
          'tareas' => remaining == 1 ? 'tarea' : 'tareas',
          _ => remaining == 1 ? 'aviso' : 'avisos',
        };
        return Column(
          children: [
            for (final (index, row) in rows.take(limit).indexed)
              Material(
                color: index == 0 && key == 'cursos'
                    ? const Color(0xFFE0F0FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                child: ListTile(
                  dense: compact,
                  minLeadingWidth: 0,
                  minVerticalPadding: 4,
                  horizontalTitleGap: compact ? 7 : 12,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: compact ? 1 : 4,
                    horizontal: 5,
                  ),
                  leading: Container(
                    width: compact ? 28 : 42,
                    height: compact ? 34 : 46,
                    decoration: BoxDecoration(
                      color: key == 'cursos'
                          ? colors[index % colors.length]
                          : const Color(0xFFE5F2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      section.icon,
                      color: key == 'cursos' ? Colors.white : studentBlue,
                      size: compact ? 19 : 25,
                    ),
                  ),
                  title: Text(
                    (row['nombre'] ?? row['titulo']) as String,
                    style: TextStyle(
                      color: studentNavy,
                      fontWeight: FontWeight.w700,
                      fontSize: tiny
                          ? 11
                          : compact
                          ? 14
                          : 15,
                    ),
                  ),
                  subtitle: Text(
                    key == 'cursos'
                        ? 'Docente: ${row['docente']}'
                        : key == 'tareas'
                        ? '${row['curso']} · ${_date(row['fechaLimite'])}'
                        : '${row['remitente']} · ${_date(row['publicadoEn'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF617991),
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, size: compact ? 14 : 20),
                  onTap: () => widget.onSelect(section),
                ),
              ),
            if (remaining > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 4, 5, 2),
                  child: Text(
                    '$remaining $remainingKind más · Ver todos',
                    style: const TextStyle(fontSize: 12, color: studentNavy),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = StudentPreviewCard(
      title: 'Mis cursos',
      icon: Icons.school_outlined,
      onOpen: () => widget.onSelect(StudentSection.cursos),
      child: _body(
        'cursos',
        StudentSection.cursos,
        'No hay cursos asignados a esta matrícula.',
      ),
    );
    final tasks = StudentPreviewCard(
      title: 'Próximas tareas',
      icon: Icons.event_note_rounded,
      onOpen: () => widget.onSelect(StudentSection.tareas),
      child: _body(
        'tareas',
        StudentSection.tareas,
        'No hay tareas pendientes con fecha próxima en esta matrícula.',
      ),
    );
    final notices = StudentPreviewCard(
      title: 'Últimos avisos',
      icon: Icons.campaign_outlined,
      onOpen: () => widget.onSelect(StudentSection.comunicados),
      child: _body(
        'comunicados',
        StudentSection.comunicados,
        'No hay comunicados disponibles.',
      ),
    );
    final schedule = StudentPreviewCard(
      title: 'Mi Horario de Clases',
      icon: Icons.schedule_outlined,
      onOpen: () => widget.onSelect(StudentSection.horario),
      actionLabel: 'Ver completo',
      child: _scheduleSummary(),
    );
    final motivation = Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: double.infinity,
          height: (MediaQuery.sizeOf(context).height * .36).clamp(140, 220),
          child: Image.asset(
            'assets/student/motivacion.png',
            key: const ValueKey('student-motivation-image'),
            semanticLabel: 'Mensaje institucional: Tú puedes. Cada día es una nueva oportunidad.',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading)
          const LinearProgressIndicator()
        else if (_failed)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('No se pudieron cargar tus matrículas.'),
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          )
        else if (_enrollments.length > 1)
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<int>(
              initialValue: _selected,
              tooltip: 'Seleccionar matrícula y periodo',
              onSelected: (id) {
                setState(() => _selected = id);
                widget.onEnrollmentChanged?.call(
                  _enrollments.firstWhere((m) => m.id == id),
                );
                _reload();
              },
              itemBuilder: (_) => [
                for (final m in _enrollments)
                  PopupMenuItem(
                    value: m.id,
                    child: Text(
                      '${m.periodo} · ${m.grado} · Sección ${m.seccion}',
                    ),
                  ),
              ],
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cambiar periodo',
                      style: TextStyle(fontSize: 12, color: studentNavy),
                    ),
                    Icon(Icons.expand_more, size: 18),
                  ],
                ),
              ),
            ),
          )
        else if (_enrollments.isEmpty)
          const Text(
            'No tienes matrículas registradas. Puedes consultar tu perfil y los comunicados generales.',
          ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, bounds) =>
              bounds.maxWidth >= 640 &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.2
              ? Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Column(children: [courses, notices])),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              tasks,
                              const SizedBox(height: 6),
                              schedule,
                            ],
                          ),
                        ),
                      ],
                    ),
                    motivation,
                  ],
                )
              : Column(
                  children: [courses, tasks, schedule, notices, motivation],
                ),
        ),
      ],
    );
  }
}
