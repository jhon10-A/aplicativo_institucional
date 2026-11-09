import 'dart:async';

import 'package:flutter/material.dart';

import '../../../auth.dart';
import '../student_api.dart';
import '../student_profile.dart';
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
  });
  final Session session;
  final ValueChanged<StudentSection> onSelect;
  final StudentApi Function() apiFactory;
  final VoidCallback onUnauthorized;
  final int? selectedEnrollmentId;
  final ValueChanged<int?>? onEnrollmentChanged;
  final ValueChanged<StudentSection>? onQuickView;
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
  @override
  void initState() {
    super.initState();
    unawaited(_loadProfile());
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

  Widget _identityLine(IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      children: [
        Icon(icon, size: 14, color: studentNavy),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: studentNavy),
          ),
        ),
      ],
    ),
  );
  Session get session => widget.session;
  ValueChanged<StudentSection> get onSelect => widget.onSelect;

  Widget _shortcut(StudentSection section, Color color, String subtitle) =>
      Material(
        color: color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: ValueKey('student-shortcut-${section.name}'),
          onTap: () => (widget.onQuickView ?? onSelect)(section),
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
                    vertical: compact ? 12 : 16,
                    horizontal: 6,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        section.icon,
                        size: compact ? 28 : 36,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
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
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: LayoutBuilder(
          builder: (context, bounds) {
            final desktop = bounds.maxWidth >= 740;
            final showMotto =
                desktop ||
                (bounds.maxWidth >= 340 &&
                    MediaQuery.textScalerOf(context).scale(1) <= 1.2);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: desktop
                          ? 96
                          : bounds.maxWidth >= 440
                          ? 90
                          : 64,
                      height: desktop
                          ? 96
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
                      child: Tooltip(
                        message: 'Avatar ilustrado genérico; no es una fotografía del estudiante',
                        child: ClipOval(
                          child: Image.asset(
                            'assets/student/avatar_ilustrado.png',
                            fit: BoxFit.cover,
                            semanticLabel: 'Avatar ilustrado genérico',
                            errorBuilder: (_, error, stack) => Center(
                              child: Text(
                                session.nombres.isEmpty
                                    ? 'E'
                                    : session.nombres.characters.first
                                          .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hola,', style: TextStyle(fontSize: 14)),
                          Text(
                            '${session.nombres} ${session.apellidos}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                          ),
                          const SizedBox(height: 6),
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
                          _identityLine(
                            Icons.badge_outlined,
                            'DNI: $_document',
                          ),
                          Tooltip(
                            message: 'El sistema actual no registra el turno del estudiante.',
                            child: _identityLine(
                              Icons.calendar_today_outlined,
                              'Turno: No disponible',
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
                        padding: const EdgeInsets.only(left: 10),
                        child: Image.asset(
                          'assets/student/frase_motivacion.png',
                          width: desktop ? 245 : bounds.maxWidth * .34,
                          semanticLabel:
                              'El esfuerzo de hoy es el éxito de mañana',
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, size) {
                    final columns =
                        size.maxWidth >= 720 ||
                            (size.maxWidth >= 340 &&
                                MediaQuery.textScalerOf(context).scale(1) <=
                                    1.2)
                        ? 4
                        : size.maxWidth >= 300
                        ? 2
                        : 1;
                    final width =
                        (size.maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: width,
                          child: _shortcut(
                            StudentSection.cursos,
                            const Color(0xFF009CF5),
                            'Explora tus cursos',
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _shortcut(
                            StudentSection.tareas,
                            const Color(0xFFA24BDE),
                            'Consulta y entrega',
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _shortcut(
                            StudentSection.calificaciones,
                            const Color(0xFF27B541),
                            'Tus notas registradas',
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _shortcut(
                            StudentSection.progreso,
                            const Color(0xFFFFA000),
                            'Tu seguimiento académico',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                StudentOverview(
                  apiFactory: widget.apiFactory,
                  selectedEnrollmentId: widget.selectedEnrollmentId,
                  onSelect: onSelect,
                  onUnauthorized: _unauthorized,
                  onEnrollmentChanged: (enrollment) {
                    setState(() => _enrollment = enrollment);
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
