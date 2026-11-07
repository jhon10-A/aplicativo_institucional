import 'dart:async';

import 'package:flutter/material.dart';

import '../student_api.dart';
import '../student_profile.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({
    super.key,
    required this.apiFactory,
    required this.onUnauthorized,
    required this.onHome,
  });
  final StudentApi Function() apiFactory;
  final VoidCallback onUnauthorized;
  final VoidCallback onHome;

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  StudentApi? _api;
  StudentProfile? _profile;
  List<StudentEnrollment> _enrollments = [];
  StudentFailureKind? _error;
  bool _loading = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _api?.dispose();
    final api = widget.apiFactory();
    _api = api;
    setState(() {
      _loading = true;
      _error = null;
      _profile = null;
      _enrollments = [];
    });
    try {
      final profile = StudentProfile.fromJson(
        await api.get('perfil') as Map<String, dynamic>,
      );
      final enrollments = (await api.get('matriculas') as List)
          .map((e) => StudentEnrollment.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted || generation != _generation) return;
      setState(() {
        _profile = profile;
        _enrollments = enrollments;
        _loading = false;
      });
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
    _api?.dispose();
    super.dispose();
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  Widget _field(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Text(
      '$label: ${value == null || value.isEmpty ? 'No registrado' : value}',
    ),
  );

  String get _message => switch (_error) {
    StudentFailureKind.missingProfile =>
      'No tienes un perfil de estudiante registrado.',
    StudentFailureKind.unauthorized =>
      'Tu sesión ha vencido. Vuelve a iniciar sesión.',
    StudentFailureKind.forbidden =>
      'No tienes acceso al módulo Estudiante. Contacta a la institución.',
    StudentFailureKind.network =>
      'No se pudo conectar. Comprueba la conexión e inténtalo nuevamente.',
    _ => 'No se pudo cargar el perfil. Inténtalo nuevamente.',
  };

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
            Text('Mi perfil', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            if (_loading) ...[
              const Center(child: CircularProgressIndicator()),
              const Text(
                'Cargando perfil y matrículas…',
                textAlign: TextAlign.center,
              ),
            ] else if (_error != null) ...[
              Text(_message),
              if (_error != StudentFailureKind.unauthorized &&
                  _error != StudentFailureKind.forbidden)
                OutlinedButton(
                  onPressed: _load,
                  child: const Text('Reintentar'),
                ),
            ] else if (_profile case final profile?) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(
                        'Nombres',
                        '${profile.nombres} ${profile.apellidos}',
                      ),
                      _field('Usuario', profile.nombreUsuario),
                      _field('Código de estudiante', profile.codigoEstudiante),
                      _field(
                        'Documento de identidad',
                        profile.documentoIdentidad,
                      ),
                      _field(
                        'Fecha de nacimiento',
                        profile.fechaNacimiento == null
                            ? null
                            : _date(profile.fechaNacimiento!),
                      ),
                      _field('Correo', profile.correo),
                      _field('Teléfono', profile.telefono),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mis matrículas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_enrollments.isEmpty)
                const Text('No tienes matrículas registradas.'),
              for (final enrollment in _enrollments)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _field('Periodo', enrollment.periodo),
                        _field(
                          'Fechas del periodo',
                          '${_date(enrollment.inicio)} – ${_date(enrollment.fin)}',
                        ),
                        _field(
                          'Periodo activo',
                          enrollment.periodoActivo ? 'Sí' : 'No',
                        ),
                        _field('Nivel', enrollment.nivel),
                        _field('Grado', enrollment.grado),
                        _field('Sección', enrollment.seccion),
                        _field('Estado', enrollment.estado),
                        _field(
                          'Fecha de matrícula',
                          _date(enrollment.fechaMatricula),
                        ),
                      ],
                    ),
                  ),
                ),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Actualizar perfil'),
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
