import 'dart:async';

import 'package:flutter/material.dart';

import '../../../auth.dart';
import '../student_api.dart';
import '../student_profile.dart';
import '../student_home_summary.dart';
import '../student_section.dart';
import '../student_theme.dart';
import 'student_overview.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({
    super.key,
    required this.session,
    required this.onSelect,
    required this.apiFactory,
    required this.onUnauthorized,
    this.selectedEnrollmentId,
    this.onEnrollmentChanged,
    this.onQuickView,
    this.clock,
  });
  final Session session;
  final ValueChanged<StudentSection> onSelect;
  final StudentApi Function() apiFactory;
  final VoidCallback onUnauthorized;
  final int? selectedEnrollmentId;
  final ValueChanged<int?>? onEnrollmentChanged;
  final ValueChanged<StudentSection>? onQuickView;
  final DateTime Function()? clock;
  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  StudentEnrollment? _enrollment;
  StudentProfile? _profile;
  StudentApi? _profileApi;
  bool _profileLoading = true;
  bool _profileFailed = false;
  bool _expired = false;
  StudentHomeScheduleSummary _scheduleSummary =
      const StudentHomeScheduleSummary.loading();
  @override
  void initState() {
    super.initState();
    unawaited(_loadProfile());
  }

  @override
  void didUpdateWidget(covariant StudentHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedEnrollmentId != oldWidget.selectedEnrollmentId &&
        widget.selectedEnrollmentId != null &&
        widget.selectedEnrollmentId != _enrollment?.id) {
      _scheduleSummary = const StudentHomeScheduleSummary.loading();
    }
  }

  @override
  void dispose() {
    _profileApi?.dispose();
    super.dispose();
  }

  void _unauthorized() {
    if (!_expired) {
      _expired = true;
      widget.onUnauthorized();
    }
  }

  Future<void> _loadProfile() async {
    _profileApi?.dispose();
    final api = widget.apiFactory();
    _profileApi = api;
    setState(() {
      _profileLoading = true;
      _profileFailed = false;
      _profile = null;
    });
    try {
      final response = await api.get('perfil') as Map<String, dynamic>;
      if (!mounted || !identical(api, _profileApi)) return;
      final profile = StudentProfile.fromJson(response);
      setState(() {
        _profile = profile;
        _profileLoading = false;
      });
    } catch (e) {
      if (!mounted || !identical(api, _profileApi)) return;
      setState(() {
        _profileLoading = false;
        _profileFailed = true;
      });
      if (e is StudentFailure && e.kind == StudentFailureKind.unauthorized) {
        _unauthorized();
      }
    }
  }

  String get _document {
    if (_profileLoading) return 'Cargando…';
    if (_profileFailed) return 'No disponible';
    final value = _profile?.documentoIdentidad?.trim();
    return value == null || value.isEmpty ? 'No registrado' : value;
  }

  String get _studentName {
    final name = _profile == null
        ? ''
        : '${_profile!.nombres} ${_profile!.apellidos}'.trim();
    return name.isNotEmpty ? name : '${session.nombres} ${session.apellidos}';
  }

  Widget _avatar() {
    Widget fallback() => Semantics(
      label: 'Avatar neutro predeterminado',
      image: true,
      excludeSemantics: true,
      child: const Center(
        child: Icon(
          Icons.person_outline_rounded,
          key: ValueKey('student-home-neutral-avatar'),
          color: Colors.white,
          size: 32,
        ),
      ),
    );
    final photo = _profile?.fotoUriSegura;
    return Tooltip(
      message: photo == null
          ? 'Avatar neutro predeterminado'
          : 'Fotografía del estudiante',
      child: ClipOval(
        child: photo == null
            ? fallback()
            : Image.network(
                photo.toString(),
                key: const ValueKey('student-home-photo'),
                fit: BoxFit.cover,
                semanticLabel: 'Fotografía del estudiante',
                errorBuilder: (_, error, stack) => fallback(),
              ),
      ),
    );
  }

  Widget _identityLine(IconData icon, String label, {bool compact = false}) =>
      Padding(
        padding: EdgeInsets.only(top: compact ? 3 : 5),
        child: Row(
          children: [
            Icon(icon, size: 14, color: studentNavy),
            SizedBox(width: compact ? 5 : 7),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: studentNavy),
              ),
            ),
          ],
        ),
      );
  Session get session => widget.session;
  ValueChanged<StudentSection> get onSelect => widget.onSelect;

  Widget _shortcut(
    StudentSection section,
    Color color,
    String subtitle, {
    bool androidPhone = false,
  }) => Material(
    color: color,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      key: ValueKey('student-shortcut-${section.name}'),
      onTap: () {
        if (section == StudentSection.cursos ||
            section == StudentSection.tareas ||
            section == StudentSection.calificaciones ||
            section == StudentSection.progreso) {
          onSelect(section);
        } else {
          (widget.onQuickView ?? onSelect)(section);
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, .20)!, color],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final compact = box.maxWidth < 150;
            return Padding(
              padding: EdgeInsets.symmetric(
                vertical: androidPhone
                    ? 8
                    : compact
                    ? 12
                    : 16,
                horizontal: 6,
              ),
              child: Column(
                children: [
                  Icon(
                    section.icon,
                    size: androidPhone
                        ? 24
                        : compact
                        ? 28
                        : 36,
                    color: Colors.white,
                  ),
                  SizedBox(height: androidPhone ? 4 : 8),
                  Text(
                    switch (section) {
                      StudentSection.cursos => 'Mis Cursos',
                      StudentSection.tareas => 'Mis Tareas',
                      StudentSection.calificaciones => 'Mis Notas',
                      _ => section.label,
                    },
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 11 : 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final androidPhone =
        Theme.of(context).platform == TargetPlatform.android &&
        MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: androidPhone ? 8 : 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: LayoutBuilder(
            builder: (context, bounds) {
              final desktop = bounds.maxWidth >= 640;
              final showMotto =
                  desktop && MediaQuery.textScalerOf(context).scale(1) <= 1.2;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDDEAF4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: desktop
                              ? 72
                              : androidPhone
                              ? 56
                              : bounds.maxWidth >= 440
                              ? 90
                              : 64,
                          height: desktop
                              ? 72
                              : androidPhone
                              ? 56
                              : bounds.maxWidth >= 440
                              ? 90
                              : 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF59C8FF), studentBlue],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: studentBlue.withValues(alpha: .15),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: _avatar(),
                        ),
                        SizedBox(width: androidPhone ? 8 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola,',
                                style: TextStyle(
                                  fontSize: androidPhone ? 12 : 14,
                                ),
                              ),
                              Text(
                                _studentName,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: androidPhone ? 18 : 20,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              if (_enrollment case final enrollment?)
                                Text(
                                  'Estudiante · ${enrollment.grado} · Sección ${enrollment.seccion}',
                                  style: const TextStyle(
                                    color: studentNavy,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              if (_enrollment == null)
                                const Text(
                                  'Estudiante',
                                  style: TextStyle(fontSize: 12),
                                ),
                              if (_profile?.codigoEstudiante.trim()
                                  case final code? when code.isNotEmpty)
                                _identityLine(
                                  Icons.school_outlined,
                                  'Código: $code',
                                  compact: androidPhone,
                                ),
                              _identityLine(
                                Icons.badge_outlined,
                                'DNI: $_document',
                                compact: androidPhone,
                              ),
                              Tooltip(
                                message:
                                    'Intervalo entre la primera y la última clase '
                                    'del horario semanal registrado; incluye los descansos.',
                                child: _identityLine(
                                  Icons.calendar_today_outlined,
                                  _scheduleSummary.label,
                                  compact: androidPhone,
                                ),
                              ),
                              if (_profileFailed)
                                IconButton(
                                  tooltip: 'Reintentar perfil',
                                  onPressed: _loadProfile,
                                  icon: const Icon(Icons.refresh, size: 16),
                                ),
                            ],
                          ),
                        ),
                        if (showMotto)
                          Padding(
                            padding: EdgeInsets.only(
                              left: androidPhone ? 4 : 10,
                            ),
                            child: Image.asset(
                              'assets/student/frase_motivacion.png',
                              width: 155,
                              semanticLabel:
                                  'El esfuerzo de hoy es el éxito de mañana',
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: androidPhone ? 10 : 16),
                  LayoutBuilder(
                    builder: (context, size) {
                      const columns = 4;
                      final spacing = size.maxWidth < 340 ? 8.0 : 12.0;
                      final width =
                          ((size.maxWidth - (columns - 1) * spacing) / columns)
                              .floorToDouble();
                      return Wrap(
                        spacing: spacing,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: width,
                            child: _shortcut(
                              StudentSection.cursos,
                              const Color(0xFF009CF5),
                              'Explora tus cursos',
                              androidPhone: androidPhone,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _shortcut(
                              StudentSection.tareas,
                              const Color(0xFFA24BDE),
                              'Consulta y entrega',
                              androidPhone: androidPhone,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _shortcut(
                              StudentSection.calificaciones,
                              const Color(0xFF27B541),
                              'Tus notas registradas',
                              androidPhone: androidPhone,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _shortcut(
                              StudentSection.progreso,
                              const Color(0xFFFFA000),
                              'Tu seguimiento académico',
                              androidPhone: androidPhone,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: androidPhone ? 12 : 18),
                  StudentOverview(
                    apiFactory: widget.apiFactory,
                    selectedEnrollmentId: widget.selectedEnrollmentId,
                    onSelect: onSelect,
                    onUnauthorized: _unauthorized,
                    clock: widget.clock,
                    onScheduleChanged: (enrollmentId, summary) {
                      if (!mounted || enrollmentId != _enrollment?.id) return;
                      setState(() => _scheduleSummary = summary);
                    },
                    onEnrollmentChanged: (enrollment) {
                      setState(() {
                        if (_enrollment?.id != enrollment?.id) {
                          _scheduleSummary = enrollment == null
                              ? const StudentHomeScheduleSummary.empty()
                              : const StudentHomeScheduleSummary.loading();
                        }
                        _enrollment = enrollment;
                      });
                      widget.onEnrollmentChanged?.call(enrollment?.id);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
