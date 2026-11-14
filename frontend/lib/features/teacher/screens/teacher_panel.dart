import 'package:flutter/material.dart';
import '../../../auth.dart';
import '../../../widgets/institutional_brand.dart';
import '../teacher_api.dart';
import '../teacher_assignment.dart';
import '../teacher_profile.dart';

const _wine = Color(0xFF650631);
const _navy = Color(0xFF092E5A);
const _blue = Color(0xFF008FE8);
const _bg = Color(0xFFF1F8FD);
const _border = Color(0xFFDDEAF4);

class TeacherPanel extends StatefulWidget {
  const TeacherPanel({
    super.key,
    required this.session,
    required this.onLogout,
    this.apiBaseUrl = const String.fromEnvironment('API_BASE_URL'),
  });

  final Session session;
  final VoidCallback onLogout;
  final String apiBaseUrl;

  @override
  State<TeacherPanel> createState() => _TeacherPanelState();
}

class _TeacherPanelState extends State<TeacherPanel> {
  late final TeacherApi _api;
  late Future<TeacherProfile> _profileFuture;
  Future<List<TeacherAssignment>>? _assignmentsFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _api = TeacherApi(
      baseUrl: widget.apiBaseUrl,
      token: widget.session.accessToken,
    );
    _profileFuture = _api.getPerfil();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<List<TeacherAssignment>> _ensureAssignments() {
    return _assignmentsFuture ??= _api.getAsignaciones();
  }

  void _reload() {
    setState(() {
      _profileFuture = _api.getPerfil();
      if (_assignmentsFuture != null) {
        _assignmentsFuture = _api.getAsignaciones();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _wine,
        foregroundColor: Colors.white,
        title: const Text('Panel Docente'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
          TextButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const InstitutionalHeader(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _selectedIndex == 0
                      ? _buildProfileTab()
                      : _selectedIndex == 1
                          ? _TeacherCoursesTab(
                              api: _api,
                              assignmentsFuture: _ensureAssignments(),
                              onRetry: _reload,
                              onLogout: widget.onLogout,
                            )
                          : _TeacherManagementTab(
                              api: _api,
                              assignmentsFuture: _ensureAssignments(),
                              onRetry: _reload,
                              onLogout: widget.onLogout,
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Mi Perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Cursos',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Gestión',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final sessionFullName = '${widget.session.nombres} ${widget.session.apellidos}'.trim();



    return FutureBuilder<TeacherProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = profile != null && profile.nombreCompleto.isNotEmpty
            ? profile.nombreCompleto
            : sessionFullName;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: _border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _wine,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'D',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile != null
                                ? 'Especialidad: ${profile.especialidad}'
                                : 'Docente • ${widget.session.nombreUsuario}',
                            style: const TextStyle(color: _blue, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Roles: ${widget.session.roles.join(', ')}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: _blue)),
              )
            else if (profile != null)
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: _border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_outlined, color: _blue),
                      title: const Text('Documento de Identidad', style: TextStyle(color: _navy, fontWeight: FontWeight.w700)),
                      subtitle: Text(profile.documentoIdentidad),
                    ),
                    const Divider(height: 1, color: Color(0xFFE3EDF5)),
                    ListTile(
                      leading: const Icon(Icons.account_circle_outlined, color: _blue),
                      title: const Text('Usuario Institucional', style: TextStyle(color: _navy, fontWeight: FontWeight.w700)),
                      subtitle: Text(profile.nombreUsuario),
                    ),
                    const Divider(height: 1, color: Color(0xFFE3EDF5)),
                    ListTile(
                      leading: Icon(
                        profile.activo ? Icons.verified_user_outlined : Icons.block,
                        color: profile.activo ? Colors.green : Colors.red,
                      ),
                      title: const Text('Estado de Cuenta', style: TextStyle(color: _navy, fontWeight: FontWeight.w700)),
                      subtitle: Text(profile.activo ? 'Activo' : 'Inactivo'),
                    ),
                  ],
                ),
              )
            else if (widget.apiBaseUrl.isNotEmpty && snapshot.hasError)
              _ErrorCard(
                error: snapshot.error,
                onRetry: _reload,
                onLogout: widget.onLogout,
              ),
          ],
        );
      },
    );
  }
}

class _TeacherCoursesTab extends StatelessWidget {
  const _TeacherCoursesTab({
    required this.api,
    required this.assignmentsFuture,
    required this.onRetry,
    required this.onLogout,
  });

  final TeacherApi api;
  final Future<List<TeacherAssignment>> assignmentsFuture;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  void _showStudents(BuildContext context, TeacherAssignment assignment) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment.cursoNombre,
                style: const TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(assignment.aulaLabel, style: const TextStyle(color: _blue)),
              const Divider(height: 24),
              Expanded(
                child: FutureBuilder<List<SectionStudent>>(
                  future: api.getEstudiantes(assignment.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _blue));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error al cargar estudiantes: ${snapshot.error}'));
                    }
                    final students = snapshot.data ?? [];
                    if (students.isEmpty) {
                      return const Center(child: Text('No hay estudiantes matriculados en esta sección.'));
                    }
                    return ListView.separated(
                      controller: controller,
                      itemCount: students.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final st = students[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _navy,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          title: Text(st.nombreCompleto, style: const TextStyle(color: _navy, fontWeight: FontWeight.w600)),
                          subtitle: Text('Código: ${st.codigoEstudiante}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TeacherAssignment>>(
      future: assignmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator(color: _blue)),
          );
        }
        if (snapshot.hasError) {
          return _ErrorCard(error: snapshot.error, onRetry: onRetry, onLogout: onLogout);
        }
        final assignments = snapshot.data ?? [];
        if (assignments.isEmpty) {
          return Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: _border),
            ),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.menu_book_outlined, size: 48, color: _blue),
                  SizedBox(height: 12),
                  Text('Sin cursos asignados', style: TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Aún no tienes carga académica registrada en el periodo actual.', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Mis Cursos Asignados', style: TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...assignments.map(
              (a) => Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: _border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: _wine.withValues(alpha: 0.1),
                    child: const Icon(Icons.class_outlined, color: _wine),
                  ),
                  title: Text(a.cursoNombre, style: const TextStyle(color: _navy, fontWeight: FontWeight.bold)),
                  subtitle: Text('${a.aulaLabel}\nPeriodo: ${a.periodoNombre}'),
                  isThreeLine: true,
                  trailing: FilledButton.tonal(
                    onPressed: () => _showStudents(context, a),
                    child: const Text('Alumnos'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TeacherManagementTab extends StatefulWidget {
  const _TeacherManagementTab({
    required this.api,
    required this.assignmentsFuture,
    required this.onRetry,
    required this.onLogout,
  });

  final TeacherApi api;
  final Future<List<TeacherAssignment>> assignmentsFuture;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  State<_TeacherManagementTab> createState() => _TeacherManagementTabState();
}

class _TeacherManagementTabState extends State<_TeacherManagementTab> {
  TeacherAssignment? _selectedAssignment;
  Future<List<SectionStudent>>? _studentsFuture;
  bool _isAttendanceMode = true;
  final DateTime _fecha = DateTime.now();

  void _selectAssignment(TeacherAssignment assignment) {
    setState(() {
      _selectedAssignment = assignment;
      _studentsFuture = widget.api.getEstudiantes(assignment.id);
    });
  }

  Future<void> _saveAttendance(SectionStudent student, String estado) async {
    if (_selectedAssignment == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.api.registrarAsistencia(
        asignacionId: _selectedAssignment!.id,
        matriculaId: student.matriculaId,
        fecha: _fecha,
        estado: estado,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Asistencia ($estado) guardada para ${student.nombres}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openGradeDialog(SectionStudent student) async {
    if (_selectedAssignment == null) return;
    final etapaCtrl = TextEditingController(text: 'BIMESTRE I');
    final conceptoCtrl = TextEditingController();
    final notaCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Calificar a ${student.nombres}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: etapaCtrl, decoration: const InputDecoration(labelText: 'Etapa (ej. BIMESTRE I)')),
              const SizedBox(height: 10),
              TextField(controller: conceptoCtrl, decoration: const InputDecoration(labelText: 'Concepto (ej. Examen Parcial)')),
              const SizedBox(height: 10),
              TextField(
                controller: notaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Nota (0 - 20)'),
              ),
              const SizedBox(height: 10),
              TextField(controller: obsCtrl, decoration: const InputDecoration(labelText: 'Observación (opcional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final nota = double.tryParse(notaCtrl.text.replaceAll(',', '.'));
              if (etapaCtrl.text.trim().isEmpty ||
                  conceptoCtrl.text.trim().isEmpty ||
                  nota == null ||
                  nota < 0 ||
                  nota > 20) {
                return;
              }
              await widget.api.registrarCalificacion(
                asignacionId: _selectedAssignment!.id,
                matriculaId: student.matriculaId,
                etapa: etapaCtrl.text,
                concepto: conceptoCtrl.text,
                nota: nota,
                observacion: obsCtrl.text,
              );
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calificación registrada para ${student.nombres}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TeacherAssignment>>(
      future: widget.assignmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator(color: _blue)),
          );
        }
        if (snapshot.hasError) {
          return _ErrorCard(error: snapshot.error, onRetry: widget.onRetry, onLogout: widget.onLogout);
        }
        final assignments = snapshot.data ?? [];
        if (assignments.isEmpty) {
          return const Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No tienes cursos asignados para registrar asistencia o calificaciones.'),
            ),
          );
        }

        _selectedAssignment ??= assignments.first;
        _studentsFuture ??= widget.api.getEstudiantes(_selectedAssignment!.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<TeacherAssignment>(
              initialValue: _selectedAssignment,
              decoration: const InputDecoration(
                labelText: 'Curso y Sección',
                fillColor: Colors.white,
                filled: true,
              ),
              items: assignments
                  .map((a) => DropdownMenuItem(value: a, child: Text('${a.cursoNombre} (${a.gradoNombre} "${a.seccionNombre}")')))
                  .toList(),
              onChanged: (val) {
                if (val != null) _selectAssignment(val);
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, icon: Icon(Icons.how_to_reg), label: Text('Asistencia')),
                ButtonSegment(value: false, icon: Icon(Icons.grade_outlined), label: Text('Calificaciones')),
              ],
              selected: {_isAttendanceMode},
              onSelectionChanged: (set) => setState(() => _isAttendanceMode = set.first),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<SectionStudent>>(
              future: _studentsFuture,
              builder: (context, stSnap) {
                if (stSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _blue));
                }
                if (stSnap.hasError) {
                  return Text('Error al cargar alumnos: ${stSnap.error}');
                }
                final students = stSnap.data ?? [];
                if (students.isEmpty) {
                  return const Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No hay estudiantes activos en esta sección.'),
                    ),
                  );
                }

                return Column(
                  children: students.map((st) {
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: _border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(st.nombreCompleto, style: const TextStyle(color: _navy, fontWeight: FontWeight.bold)),
                            Text('Código: ${st.codigoEstudiante}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 10),
                            if (_isAttendanceMode)
                              Wrap(
                                spacing: 6,
                                children: ['PRESENTE', 'TARDANZA', 'FALTA', 'JUSTIFICADA']
                                    .map(
                                      (estado) => ActionChip(
                                        label: Text(estado, style: const TextStyle(fontSize: 12)),
                                        onPressed: () => _saveAttendance(st, estado),
                                      ),
                                    )
                                    .toList(),
                              )
                            else
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  onPressed: () => _openGradeDialog(st),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Registrar Nota'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry, required this.onLogout});
  final Object? error;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isUnauthorized = error is TeacherFailure && (error as TeacherFailure).kind == TeacherFailureKind.unauthorized;
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: _wine),
            const SizedBox(height: 12),
            Text(
              isUnauthorized
                  ? 'Tu sesión expiró. Vuelve a iniciar sesión.'
                  : 'No se pudo cargar la información ($error).',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isUnauthorized ? onLogout : onRetry,
              child: Text(isUnauthorized ? 'Ir al inicio' : 'Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}