import 'dart:async';

import 'package:flutter/material.dart';

import '../student_api.dart';
import '../student_notice.dart';
import '../student_profile.dart';

class StudentNoticesScreen extends StatefulWidget {
  const StudentNoticesScreen({
    super.key,
    required this.apiFactory,
    required this.onUnauthorized,
    required this.onHome,
  });
  final StudentApi Function() apiFactory;
  final VoidCallback onUnauthorized;
  final VoidCallback onHome;
  @override
  State<StudentNoticesScreen> createState() => _StudentNoticesScreenState();
}

class _StudentNoticesScreenState extends State<StudentNoticesScreen> {
  late final StudentApi _api;
  List<StudentEnrollment> _enrollments = [];
  List<StudentNotice> _notices = [];
  StudentNotice? _detail;
  int _enrollment = 0;
  int? _notice;
  bool _loading = true;
  StudentFailureKind? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _api = widget.apiFactory();
    unawaited(_load(initial: true));
  }

  @override
  void dispose() {
    ++_generation;
    _api.dispose();
    super.dispose();
  }

  Future<void> _load({
    int enrollment = 0,
    int? notice,
    bool initial = false,
  }) async {
    final generation = ++_generation;
    setState(() {
      _enrollment = enrollment;
      _notice = notice;
      _notices = [];
      _detail = null;
      _loading = true;
      _error = null;
    });
    try {
      if (initial) {
        List<StudentEnrollment> enrollments;
        try {
          enrollments = (await _api.get('matriculas') as List)
              .map((e) => StudentEnrollment.fromJson(e as Map<String, dynamic>))
              .toList();
        } on StudentFailure catch (e) {
          if (e.kind != StudentFailureKind.missingProfile) rethrow;
          enrollments =
              []; // General announcements do not require an academic profile.
        }
        if (!mounted || generation != _generation) return;
        setState(() => _enrollments = enrollments);
      }
      final path = enrollment == 0
          ? 'comunicados'
          : 'matriculas/$enrollment/comunicados';
      final data = await _api.get(notice == null ? path : '$path/$notice');
      if (notice == null) {
        final notices = (data as List)
            .map((e) => StudentNotice.fromJson(e as Map<String, dynamic>))
            .toList();
        if (!mounted || generation != _generation) return;
        setState(() => _notices = notices);
      } else {
        final detail = StudentNotice.fromJson(data as Map<String, dynamic>);
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

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  String get _message => switch (_error) {
    StudentFailureKind.unauthorized =>
      'Tu sesión ha vencido. Vuelve a iniciar sesión.',
    StudentFailureKind.forbidden => 'No tienes acceso al módulo Estudiante.',
    StudentFailureKind.unavailable =>
      'La matrícula o el comunicado no está disponible.',
    StudentFailureKind.missingProfile =>
      'No tienes un perfil de estudiante registrado.',
    StudentFailureKind.network => 'No se pudo conectar. Comprueba tu conexión.',
    _ => 'No se pudieron cargar los comunicados. Inténtalo nuevamente.',
  };
  Widget _summary(StudentNotice notice) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(notice.alcance),
      Text('Destinatarios: ${notice.destinatarios}'),
      Text('Remitente: ${notice.remitente}'),
      Text('Publicación: ${_date(notice.publicadoEn)}'),
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
              _notice == null ? 'Mis comunicados' : 'Detalle del comunicado',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: ValueKey(_enrollment),
              initialValue: _enrollment,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Audiencia y matrícula',
              ),
              items: [
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Generales (sin sección)'),
                ),
                for (final m in _enrollments)
                  DropdownMenuItem(
                    value: m.id,
                    child: Text(
                      '${m.periodo} · ${m.nivel} ${m.grado} ${m.seccion}',
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
            if (_enrollment != 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Se muestran los generales y los de la sección de esta matrícula.',
                ),
              ),
            const SizedBox(height: 16),
            if (_loading) ...[
              const Center(child: CircularProgressIndicator()),
              const Text('Cargando comunicados…'),
            ] else if (_error != null) ...[
              Text(_message),
              if (_error != StudentFailureKind.unauthorized &&
                  _error != StudentFailureKind.forbidden)
                OutlinedButton(
                  onPressed: () => _load(
                    enrollment: _enrollment,
                    notice: _notice,
                    initial:
                        _enrollments.isEmpty &&
                        _enrollment == 0 &&
                        _notice == null,
                  ),
                  child: const Text('Reintentar'),
                ),
            ] else if (_detail case final notice?)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.titulo,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _summary(notice),
                      if (notice.fechaVencimiento case final date?)
                        Text('Vencimiento: ${_date(date)}'),
                      const SizedBox(height: 16),
                      SelectableText(notice.contenido),
                    ],
                  ),
                ),
              )
            else if (_notices.isEmpty)
              const Text('No hay comunicados disponibles para esta selección.')
            else
              for (final notice in _notices)
                Card(
                  child: ListTile(
                    title: Text(notice.titulo),
                    subtitle: _summary(notice),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        _load(enrollment: _enrollment, notice: notice.id),
                  ),
                ),
            if (_notice != null && !_loading)
              OutlinedButton(
                onPressed: () => _load(enrollment: _enrollment),
                child: const Text('Volver a comunicados'),
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
