import 'package:flutter/material.dart';
import '../../../auth.dart';
import '../teacher_api.dart';
import '../teacher_assignment.dart';
import '../teacher_profile.dart';

const _wine = Color(0xFF7B0D3B);
const _navy = Color(0xFF102A43);
const _blue = Color(0xFF0084D6);
const _purple = Color(0xFF8833D9);
const _green = Color(0xFF1CA64C);
const _orange = Color(0xFFF39200);
const _bg = Color(0xFFF4F8FB);
const _border = Color(0xFFE1EBF3);

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
  late Future<List<TeacherAssignment>> _assignmentsFuture;

  /// 0 = Inicio (Dashboard), 1 = Mis Cursos, 2 = Mis Estudiantes, 3 = Asistencia, 4 = Calificaciones
  int _activeView = 0;

  final List<_AgendaRow> _agenda = const [
    _AgendaRow('07:30 – 08:15', 'Matemática', '3° B'),
    _AgendaRow('08:15 – 09:00', 'Comunicación', '3° B'),
    _AgendaRow('09:00 – 09:45', 'Ciencia y Tecnología', '2° A'),
    _AgendaRow('10:40 – 11:30', 'Recreo', 'Patio', isBreak: true),
    _AgendaRow('11:30 – 12:15', 'Historia y Economía', '3° B'),
  ];

  final List<_PendingTaskItem> _tasks = [
    _PendingTaskItem('08', 'SET', 'Revisar y calificar ensayo', 'Matemática · 3° A'),
    _PendingTaskItem('10', 'SET', 'Revisar práctica de lectura', 'Comunicación · 1° B'),
    _PendingTaskItem('12', 'SET', 'Calificar trabajo grupal', 'Ciencia y Ambiente · 2° A'),
  ];

  final List<_NoticeItem> _notices = [
    _NoticeItem('05', 'SEP', 'Ensayos del Concurso de Danzas', 'Revisa el cronograma por secciones.'),
    _NoticeItem('03', 'SEP', 'Campaña de salud escolar', 'Evaluación y orientación preventiva.'),
  ];

  @override
  void initState() {
    super.initState();
    _api = TeacherApi(
      baseUrl: widget.apiBaseUrl,
      token: widget.session.accessToken,
    );
    _profileFuture = _api.getPerfil();
    _assignmentsFuture = _loadAssignmentsWithFallback();
  }

  Future<List<TeacherAssignment>> _loadAssignmentsWithFallback() async {
    try {
      final remote = await _api.getAsignaciones();
      if (remote.isNotEmpty) return remote;
    } on TeacherFailure catch (e) {
      if (e.kind == TeacherFailureKind.unauthorized) rethrow;
    } catch (_) {}
    return _demoAssignments();
  }

  static List<TeacherAssignment> _demoAssignments() {
    return [
      TeacherAssignment.fromJson({
        'id': -101,
        'cursoId': 1,
        'cursoNombre': 'Matemática',
        'cursoDescripcion': 'Álgebra, geometría y resolución de problemas.',
        'periodoId': 1,
        'periodoNombre': '2026 - II',
        'periodoActivo': true,
        'seccionId': 11,
        'seccionNombre': 'B',
        'gradoNombre': '3° Secundaria',
        'nivel': 'Secundaria',
      }),
      TeacherAssignment.fromJson({
        'id': -102,
        'cursoId': 2,
        'cursoNombre': 'Comunicación',
        'cursoDescripcion': 'Comprensión lectora y producción de textos.',
        'periodoId': 1,
        'periodoNombre': '2026 - II',
        'periodoActivo': true,
        'seccionId': 12,
        'seccionNombre': 'A',
        'gradoNombre': '1° Secundaria',
        'nivel': 'Secundaria',
      }),
      TeacherAssignment.fromJson({
        'id': -103,
        'cursoId': 3,
        'cursoNombre': 'Ciencia y Tecnología',
        'cursoDescripcion': 'Indagación científica y laboratorio.',
        'periodoId': 1,
        'periodoNombre': '2026 - II',
        'periodoActivo': true,
        'seccionId': 13,
        'seccionNombre': 'A',
        'gradoNombre': '2° Secundaria',
        'nivel': 'Secundaria',
      }),
    ];
  }

  static List<SectionStudent> demoStudentsFor(int asignacionId) {
    final base = [
      ('EST-2026-001', 'Camila Sofía', 'Huamán Quispe'),
      ('EST-2026-002', 'Mateo Sebastián', 'Ccopa Condori'),
      ('EST-2026-003', 'Valeria Lucía', 'Auccapuma Rojas'),
      ('EST-2026-004', 'Diego Alejandro', 'Paredes Mendoza'),
      ('EST-2026-005', 'Luciana Gabriela', 'Serrano Chávez'),
      ('EST-2026-006', 'Rodrigo Alonso', 'Taipe Mamani'),
    ];
    return [
      for (int i = 0; i < base.length; i++)
        SectionStudent.fromJson({
          'matriculaId': (asignacionId.abs() * 100) + i + 1,
          'estudianteId': 500 + i,
          'codigoEstudiante': base[i].$1,
          'nombres': base[i].$2,
          'apellidos': base[i].$3,
          'estadoMatricula': 'ACTIVA',
        }),
    ];
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _profileFuture = _api.getPerfil();
      _assignmentsFuture = _loadAssignmentsWithFallback();
    });
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'DC';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _openCreateTaskDialog() async {
    final titleCtrl = TextEditingController();
    final courseCtrl = TextEditingController(text: 'Matemática · 3° B');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear Nueva Tarea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Título de la tarea'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: courseCtrl,
              decoration: const InputDecoration(labelText: 'Curso y sección'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _blue),
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Publicar Tarea'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _tasks.insert(
          0,
          _PendingTaskItem('15', 'NOV', titleCtrl.text.trim(), courseCtrl.text.trim()),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea agregada a la lista por calificar')),
      );
    }
  }

  Future<void> _openCreateNoticeDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar Comunicado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Asunto del comunicado'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Mensaje breve'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _orange),
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _notices.insert(
          0,
          _NoticeItem(
            '14',
            'NOV',
            titleCtrl.text.trim(),
            descCtrl.text.trim().isEmpty ? 'Comunicado institucional docente.' : descCtrl.text.trim(),
          ),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comunicado publicado en Últimos Avisos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildTopNavbar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildWelcomeHeader(),
                            const SizedBox(height: 20),
                            _buildActionPills(),
                            const SizedBox(height: 22),
                            if (_activeView == 0)
                              _buildDashboardBody()
                            else if (_activeView == 1)
                              _buildSubViewWrapper(
                                title: 'Mis Cursos Asignados',
                                child: _TeacherCoursesSection(
                                  api: _api,
                                  assignmentsFuture: _assignmentsFuture,
                                  onOpenAttendance: () => setState(() => _activeView = 3),
                                  onOpenGrades: () => setState(() => _activeView = 4),
                                  onRetry: _reload,
                                  onLogout: widget.onLogout,
                                ),
                              )
                            else if (_activeView == 2)
                              _buildSubViewWrapper(
                                title: 'Mis Estudiantes',
                                child: _TeacherStudentsSection(
                                  api: _api,
                                  assignmentsFuture: _assignmentsFuture,
                                  onRetry: _reload,
                                  onLogout: widget.onLogout,
                                ),
                              )
                            else if (_activeView == 3)
                              _buildSubViewWrapper(
                                title: 'Registro de Asistencia',
                                child: _TeacherAttendanceSection(
                                  api: _api,
                                  assignmentsFuture: _assignmentsFuture,
                                  onRetry: _reload,
                                  onLogout: widget.onLogout,
                                ),
                              )
                            else
                              _buildSubViewWrapper(
                                title: 'Ingreso de Calificaciones',
                                child: _TeacherGradesSection(
                                  api: _api,
                                  assignmentsFuture: _assignmentsFuture,
                                  onRetry: _reload,
                                  onLogout: widget.onLogout,
                                ),
                              ),
                            const SizedBox(height: 24),
                            _buildSyncStatusBar(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavbar() {
    final isCompact = MediaQuery.of(context).size.width < 560;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeView = 0),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/institutional/escudo.png',
                        height: 40,
                        errorBuilder: (_, _, _) => const CircleAvatar(
                          backgroundColor: _navy,
                          child: Text('MB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I.E. Micaela Bastidas\nPuyucahua',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 13, height: 1.15),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tamburco · Abancay · Apurímac',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.black54, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (MediaQuery.of(context).size.width > 920) ...[
                _navLink('Inicio', () => setState(() => _activeView = 0), active: _activeView == 0),
                _navLink('Mis Cursos', () => setState(() => _activeView = 1), active: _activeView == 1),
                _navLink('Estudiantes', () => setState(() => _activeView = 2), active: _activeView == 2),
                _navLink('Asistencia', () => setState(() => _activeView = 3), active: _activeView == 3),
                _navLink('Calificaciones', () => setState(() => _activeView = 4), active: _activeView == 4),
                const SizedBox(width: 12),
              ],
              IconButton(
                tooltip: 'Actualizar datos',
                onPressed: _reload,
                icon: const Icon(Icons.refresh, color: _navy),
              ),
              const SizedBox(width: 4),
              if (isCompact)
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: _wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  tooltip: 'Cerrar sesión',
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout, size: 18),
                )
              else
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _wine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: active ? _wine : _navy,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final fallbackName = '${widget.session.nombres} ${widget.session.apellidos}'.trim();

    return FutureBuilder<TeacherProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final rawName = (profile != null && profile.nombreCompleto.isNotEmpty)
            ? profile.nombreCompleto
            : (fallbackName.isNotEmpty ? fallbackName : widget.session.nombreUsuario);
        final displayName = rawName;
        final specialty = (profile != null && profile.especialidad.isNotEmpty)
            ? 'Docente · ${profile.especialidad}'
            : 'Docente · Turno mañana';
        final dni = (profile != null && profile.documentoIdentidad.isNotEmpty)
            ? profile.documentoIdentidad
            : widget.session.nombreUsuario;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 780;
            final profileBlock = Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _navy,
                  child: Text(
                    _initials(rawName),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hola, Prof.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      Text(
                        displayName,
                        style: const TextStyle(color: _navy, fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        specialty,
                        style: const TextStyle(color: _blue, fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'DNI: $dni',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      Text(
                        'Roles: ${widget.session.roles.join(', ')}',
                        style: const TextStyle(color: Colors.black45, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final quoteCard = Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFDDF0FC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.menu_book_outlined, color: _navy, size: 22),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '“Educar es encender una luz en cada estudiante.”',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 6, child: profileBlock),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: quoteCard),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                profileBlock,
                const SizedBox(height: 14),
                quoteCard,
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionPills() {
    final items = [
      ('Mis Cursos', Icons.menu_book_outlined, _blue, 1),
      ('Mis Estudiantes', Icons.people_outline, _purple, 2),
      ('Asistencia', Icons.event_available_outlined, _green, 3),
      ('Calificaciones', Icons.bar_chart_rounded, _orange, 4),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 720;
        if (isMobile) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: items.map((item) => _pillButton(item.$1, item.$2, item.$3, item.$4)).toList(),
          );
        }
        return Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Expanded(child: _pillButton(items[i].$1, items[i].$2, items[i].$3, items[i].$4)),
              if (i < items.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      },
    );
  }

  Widget _pillButton(String label, IconData icon, Color color, int targetView) {
    final selected = _activeView == targetView;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      elevation: selected ? 4 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _activeView = selected ? 0 : targetView),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: selected ? Border.all(color: Colors.white, width: 2.5) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubViewWrapper({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _activeView = 0),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Volver al panel principal'),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: const TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildDashboardBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth >= 860;
        final leftColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCoursesSummaryCard(),
            const SizedBox(height: 18),
            _buildInstitutionalBannerCard(),
            const SizedBox(height: 18),
            _buildNoticesCard(),
          ],
        );

        final rightColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAgendaCard(),
            const SizedBox(height: 18),
            _buildPendingTasksCard(),
            const SizedBox(height: 18),
            _buildQuickAccessCard(),
          ],
        );

        if (isTwoColumn) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftColumn),
              const SizedBox(width: 20),
              Expanded(child: rightColumn),
            ],
          );
        }
        return Column(
          children: [
            leftColumn,
            const SizedBox(height: 18),
            rightColumn,
          ],
        );
      },
    );
  }

  Widget _buildCoursesSummaryCard() {
    final palette = [_blue, _wine, _green, _purple, _orange];
    final icons = [
      Icons.bar_chart_rounded,
      Icons.menu_book_rounded,
      Icons.check_circle_outline,
      Icons.public_rounded,
      Icons.fitness_center_rounded,
    ];

    return _DashboardCard(
      icon: Icons.menu_book_outlined,
      iconColor: _wine,
      title: 'Mis Cursos',
      actionLabel: 'Ver todos >',
      onAction: () => setState(() => _activeView = 1),
      child: FutureBuilder<List<TeacherAssignment>>(
        future: _assignmentsFuture,
        builder: (context, snapshot) {
          final assignments = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator(color: _blue)),
            );
          }

          return Column(
            children: [
              for (int i = 0; i < assignments.length; i++) ...[
                InkWell(
                  onTap: () => setState(() => _activeView = 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: palette[i % palette.length],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icons[i % icons.length], color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignments[i].cursoNombre,
                                style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              Text(
                                '${assignments[i].gradoNombre} "${assignments[i].seccionNombre}" · ${assignments[i].nivel}',
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          assignments[i].periodoNombre,
                          style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right, color: Colors.black38, size: 18),
                      ],
                    ),
                  ),
                ),
                if (i < assignments.length - 1) const Divider(height: 1, color: _border),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildInstitutionalBannerCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 185,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/institutional/colegio.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: _navy),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _wine.withValues(alpha: 0.72),
                    _navy.withValues(alpha: 0.65),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Juntos construimos',
                          style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'una mejor educación.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _wine,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Nuestra Institución',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticesCard() {
    return _DashboardCard(
      icon: Icons.campaign_outlined,
      iconColor: _wine,
      title: 'Últimos Avisos',
      actionLabel: 'Ver todos >',
      onAction: _openCreateNoticeDialog,
      child: Column(
        children: [
          for (int i = 0; i < _notices.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  _DateBadge(day: _notices[i].day, month: _notices[i].month, tint: const Color(0xFFE3F4EA), accent: _green),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _notices[i].title,
                          style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        Text(
                          _notices[i].subtitle,
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black38, size: 18),
                ],
              ),
            ),
            if (i < _notices.length - 1) const Divider(height: 1, color: _border),
          ],
        ],
      ),
    );
  }

  Widget _buildAgendaCard() {
    return _DashboardCard(
      icon: Icons.access_time_rounded,
      iconColor: _wine,
      title: 'Agenda de Hoy',
      actionLabel: 'Ver completo >',
      onAction: () => setState(() => _activeView = 1),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Hora', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black54))),
                Expanded(flex: 4, child: Text('Curso', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black54))),
                Expanded(flex: 2, child: Text('Aula', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black54))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ..._agenda.map(
            (row) => Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: row.isBreak ? const Color(0xFFE3F7EA) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: const Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(row.time, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                  Expanded(
                    flex: 4,
                    child: Text(
                      row.course,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: row.isBreak ? _green : _navy,
                      ),
                    ),
                  ),
                  Expanded(flex: 2, child: Text(row.room, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTasksCard() {
    return _DashboardCard(
      icon: Icons.checklist_rounded,
      iconColor: _wine,
      title: 'Tareas por calificar',
      actionLabel: 'Ver todas >',
      onAction: () => setState(() => _activeView = 4),
      child: Column(
        children: [
          for (int i = 0; i < _tasks.length; i++) ...[
            InkWell(
              onTap: () => setState(() => _activeView = 4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _DateBadge(day: _tasks[i].day, month: _tasks[i].month, tint: const Color(0xFFE2F1FC), accent: _blue),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tasks[i].title,
                            style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          Text(
                            _tasks[i].subtitle,
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Pendiente',
                        style: TextStyle(color: _wine, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, color: Colors.black38, size: 18),
                  ],
                ),
              ),
            ),
            if (i < _tasks.length - 1) const Divider(height: 1, color: _border),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard() {
    return _DashboardCard(
      icon: Icons.add_circle_outline,
      iconColor: _wine,
      title: 'Accesos Rápidos',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _quickBtn(
                  label: '+ Crear Tarea',
                  color: _blue,
                  onTap: _openCreateTaskDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickBtn(
                  label: 'Registrar Asistencia',
                  icon: Icons.event_available_outlined,
                  color: _purple,
                  onTap: () => setState(() => _activeView = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickBtn(
                  label: 'Ingresar Calificaciones',
                  icon: Icons.bar_chart_rounded,
                  color: _green,
                  onTap: () => setState(() => _activeView = 4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickBtn(
                  label: 'Enviar Comunicado',
                  icon: Icons.chat_bubble_outline,
                  color: _orange,
                  onTap: _openCreateNoticeDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickBtn({
    required String label,
    IconData? icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusBar() {
    final online = widget.apiBaseUrl.isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.circle, size: 9, color: online ? _green : _orange),
        const SizedBox(width: 6),
        Icon(online ? Icons.wifi : Icons.wifi_off, size: 14, color: Colors.black54),
        const SizedBox(width: 6),
        Text(
          online ? 'Conectado al servidor institucional' : 'Modo local · Listo para sincronizar',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0A1D37),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Wrap(
            spacing: 48,
            runSpacing: 20,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/institutional/escudo.png',
                    height: 36,
                    errorBuilder: (_, _, _) => const Icon(Icons.school, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I.E. Micaela Bastidas Puyucahua',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Tamburco · Abancay · Apurímac',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPLORA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 6),
                  Text('Inicio · Institución · Noticias', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RECURSOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 6),
                  Text('Portal Docente · Asistencia · Notas', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CONTACTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 6),
                  Text('Av. Micaela Bastidas s/n, Tamburco', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<List<SectionStudent>> _fetchStudentsWithFallback(TeacherApi api, int asignacionId) async {
  if (asignacionId > 0) {
    try {
      final remote = await api.getEstudiantes(asignacionId);
      if (remote.isNotEmpty) return remote;
    } catch (_) {}
  }
  return _TeacherPanelState.demoStudentsFor(asignacionId);
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: iconColor.withValues(alpha: 0.1),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: _navy, fontSize: 16.5, fontWeight: FontWeight.w800),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(color: _blue, fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({
    required this.day,
    required this.month,
    required this.tint,
    required this.accent,
  });

  final String day;
  final String month;
  final Color tint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 15, height: 1.1)),
          Text(month, style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 10)),
        ],
      ),
    );
  }
}

class _AgendaRow {
  const _AgendaRow(this.time, this.course, this.room, {this.isBreak = false});
  final String time;
  final String course;
  final String room;
  final bool isBreak;
}

class _PendingTaskItem {
  const _PendingTaskItem(this.day, this.month, this.title, this.subtitle);
  final String day;
  final String month;
  final String title;
  final String subtitle;
}

class _NoticeItem {
  const _NoticeItem(this.day, this.month, this.title, this.subtitle);
  final String day;
  final String month;
  final String title;
  final String subtitle;
}

class _TeacherCoursesSection extends StatelessWidget {
  const _TeacherCoursesSection({
    required this.api,
    required this.assignmentsFuture,
    required this.onOpenAttendance,
    required this.onOpenGrades,
    required this.onRetry,
    required this.onLogout,
  });

  final TeacherApi api;
  final Future<List<TeacherAssignment>> assignmentsFuture;
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenGrades;
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
                  future: _fetchStudentsWithFallback(api, assignment.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _blue));
                    }
                    final students = snapshot.data ?? [];
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
                          subtitle: Text('Código: ${st.codigoEstudiante} · Estado: ${st.estadoMatricula}'),
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
    final palette = [_blue, _wine, _green, _purple, _orange];
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < assignments.length; i++)
              Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: _border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: palette[i % palette.length].withValues(alpha: 0.12),
                            child: Icon(Icons.class_outlined, color: palette[i % palette.length]),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assignments[i].cursoNombre,
                                  style: const TextStyle(color: _navy, fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${assignments[i].aulaLabel} · Periodo ${assignments[i].periodoNombre}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                                ),
                                if (assignments[i].cursoDescripcion != null &&
                                    assignments[i].cursoDescripcion!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    assignments[i].cursoDescripcion!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showStudents(context, assignments[i]),
                            icon: const Icon(Icons.people_outline, size: 17),
                            label: const Text('Nómina'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: onOpenAttendance,
                            icon: const Icon(Icons.event_available_outlined, size: 17),
                            label: const Text('Asistencia'),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: _blue),
                            onPressed: onOpenGrades,
                            icon: const Icon(Icons.grade_outlined, size: 17),
                            label: const Text('Calificar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

}

class _TeacherStudentsSection extends StatefulWidget {
  const _TeacherStudentsSection({
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
  State<_TeacherStudentsSection> createState() => _TeacherStudentsSectionState();
}

class _TeacherStudentsSectionState extends State<_TeacherStudentsSection> {
  TeacherAssignment? _selected;
  Future<List<SectionStudent>>? _studentsFuture;
  String _search = '';

  void _pickAssignment(TeacherAssignment a) {
    setState(() {
      _selected = a;
      _studentsFuture = _fetchStudentsWithFallback(widget.api, a.id);
    });
  }

  void _showStudentDetail(SectionStudent st, TeacherAssignment course) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _purple,
              child: Text(
                st.nombres.isNotEmpty ? st.nombres[0].toUpperCase() : 'E',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(st.nombreCompleto, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código institucional: ${st.codigoEstudiante}'),
            const SizedBox(height: 6),
            Text('Curso / Aula: ${course.cursoNombre} (${course.aulaLabel})'),
            const SizedBox(height: 6),
            Text('Estado de matrícula: ${st.estadoMatricula}'),
            const Divider(height: 20),
            const Text(
              'Seguimiento rápido disponible en las pestañas Asistencia y Calificaciones.',
              style: TextStyle(color: Colors.black54, fontSize: 12.5),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _navy),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TeacherAssignment>>(
      future: widget.assignmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator(color: _purple)),
          );
        }
        if (snapshot.hasError) {
          return _ErrorCard(error: snapshot.error, onRetry: widget.onRetry, onLogout: widget.onLogout);
        }
        final assignments = snapshot.data ?? [];
        _selected ??= assignments.first;
        _studentsFuture ??= _fetchStudentsWithFallback(widget.api, _selected!.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 700;
                  final dropdown = DropdownButtonFormField<TeacherAssignment>(
                    isExpanded: true,
                    initialValue: _selected,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por Curso y Sección',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: assignments
                        .map((a) => DropdownMenuItem(value: a, child: Text('${a.cursoNombre} · ${a.gradoNombre} "${a.seccionNombre}",overflow: TextOverflow.ellipsis,')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) _pickAssignment(val);
                    },
                  );
                  final searchBox = TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar estudiante por apellido, nombre o código',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
                  );
                  if (wide) {
                    return Row(
                      children: [
                        Expanded(flex: 5, child: dropdown),
                        const SizedBox(width: 14),
                        Expanded(flex: 6, child: searchBox),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      dropdown,
                      const SizedBox(height: 12),
                      searchBox,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<SectionStudent>>(
              future: _studentsFuture,
              builder: (context, stSnap) {
                if (stSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator(color: _purple)),
                  );
                }
                final all = stSnap.data ?? [];
                final filtered = _search.isEmpty
                    ? all
                    : all
                        .where((s) =>
                            s.nombreCompleto.toLowerCase().contains(_search) ||
                            s.codigoEstudiante.toLowerCase().contains(_search))
                        .toList();

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_outlined, color: _purple),
                            const SizedBox(width: 10),
                            Text(
                              'Nómina de Estudiantes (${filtered.length} de ${all.length})',
                              style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _border),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Text('No se encontraron estudiantes con ese criterio.'),
                        )
                      else
                        for (int i = 0; i < filtered.length; i++) ...[
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _purple.withValues(alpha: 0.12),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                            ),
                            title: Text(
                              filtered[i].nombreCompleto,
                              style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text('Código: ${filtered[i].codigoEstudiante}'),
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F7EA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    filtered[i].estadoMatricula,
                                    style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Ver ficha del estudiante',
                                  onPressed: () => _showStudentDetail(filtered[i], _selected!),
                                  icon: const Icon(Icons.visibility_outlined, color: _navy),
                                ),
                              ],
                            ),
                          ),
                          if (i < filtered.length - 1) const Divider(height: 1, color: _border),
                        ],
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _TeacherAttendanceSection extends StatefulWidget {
  const _TeacherAttendanceSection({
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
  State<_TeacherAttendanceSection> createState() => _TeacherAttendanceSectionState();
}

class _TeacherAttendanceSectionState extends State<_TeacherAttendanceSection> {
  TeacherAssignment? _selected;
  Future<List<SectionStudent>>? _studentsFuture;
  DateTime _fecha = DateTime.now();
  final Map<int, String> _statusByMatricula = {};
  bool _savingAll = false;

  void _pickAssignment(TeacherAssignment a) {
    setState(() {
      _selected = a;
      _statusByMatricula.clear();
      _studentsFuture = _fetchStudentsWithFallback(widget.api, a.id);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
    );
    if (picked != null) {
      setState(() => _fecha = picked);
    }
  }

  Future<void> _saveSingle(SectionStudent st, String estado) async {
    if (_selected == null) return;
    setState(() => _statusByMatricula[st.matriculaId] = estado);
    if (_selected!.id > 0) {
      try {
        await widget.api.registrarAsistencia(
          asignacionId: _selected!.id,
          matriculaId: st.matriculaId,
          fecha: _fecha,
          estado: estado,
        );
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text('Asistencia ($estado) registrada: ${st.nombres}'),
        ),
      );
    }
  }

  Future<void> _saveAll(List<SectionStudent> students) async {
    if (_selected == null) return;
    setState(() => _savingAll = true);
    for (final st in students) {
      final estado = _statusByMatricula[st.matriculaId] ?? 'PRESENTE';
      _statusByMatricula[st.matriculaId] = estado;
      if (_selected!.id > 0) {
        try {
          await widget.api.registrarAsistencia(
            asignacionId: _selected!.id,
            matriculaId: st.matriculaId,
            fecha: _fecha,
            estado: estado,
          );
        } catch (_) {}
      }
    }
    if (mounted) {
      setState(() => _savingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Asistencia completa guardada para ${students.length} estudiantes')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}';

    return FutureBuilder<List<TeacherAssignment>>(
      future: widget.assignmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator(color: _green)),
          );
        }
        if (snapshot.hasError) {
          return _ErrorCard(error: snapshot.error, onRetry: widget.onRetry, onLogout: widget.onLogout);
        }
        final assignments = snapshot.data ?? [];
        _selected ??= assignments.first;
        _studentsFuture ??= _fetchStudentsWithFallback(widget.api, _selected!.id);

        return FutureBuilder<List<SectionStudent>>(
          future: _studentsFuture,
          builder: (context, stSnap) {
            final students = stSnap.data ?? [];
            int presentes = 0, tardanzas = 0, faltas = 0, justificadas = 0;
            for (final st in students) {
              final e = _statusByMatricula[st.matriculaId];
              if (e == 'PRESENTE') presentes++;
              if (e == 'TARDANZA') tardanzas++;
              if (e == 'FALTA') faltas++;
              if (e == 'JUSTIFICADA') justificadas++;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 340,
                        child: DropdownButtonFormField<TeacherAssignment>(
                          isExpanded: true,
                          initialValue: _selected,
                          decoration: const InputDecoration(
                            labelText: 'Curso y Sección',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: assignments
                              .map((a) => DropdownMenuItem(value: a, child: Text('${a.cursoNombre} · ${a.gradoNombre} "${a.seccionNombre}",overflow: TextOverflow.ellipsis,')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) _pickAssignment(val);
                          },
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined, size: 17),
                        label: Text('Fecha: $dateStr'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: students.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  for (final st in students) {
                                    _statusByMatricula[st.matriculaId] = 'PRESENTE';
                                  }
                                });
                              },
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Marcar todos Presentes'),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: _green),
                        onPressed: (students.isEmpty || _savingAll) ? null : () => _saveAll(students),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: Text(_savingAll ? 'Guardando...' : 'Guardar Asistencia'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _counterChip('Presentes: $presentes', _green),
                    _counterChip('Tardanzas: $tardanzas', _orange),
                    _counterChip('Faltas: $faltas', Colors.red),
                    _counterChip('Justificadas: $justificadas', _blue),
                  ],
                ),
                const SizedBox(height: 14),
                if (stSnap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator(color: _green)),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < students.length; i++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 10,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundColor: _navy,
                                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(students[i].nombreCompleto, style: const TextStyle(color: _navy, fontWeight: FontWeight.w700)),
                                        Text('Código: ${students[i].codigoEstudiante}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    _statusBtn(students[i], 'PRESENTE', _green),
                                    _statusBtn(students[i], 'TARDANZA', _orange),
                                    _statusBtn(students[i], 'FALTA', Colors.red),
                                    _statusBtn(students[i], 'JUSTIFICADA', _blue),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (i < students.length - 1) const Divider(height: 1, color: _border),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _counterChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _statusBtn(SectionStudent st, String estado, Color color) {
    final active = _statusByMatricula[st.matriculaId] == estado;
    return ChoiceChip(
      label: Text(
        estado,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : _navy,
        ),
      ),
      selected: active,
      selectedColor: color,
      backgroundColor: const Color(0xFFF1F5F9),
      onSelected: (_) => _saveSingle(st, estado),
    );
  }
}

class _TeacherGradesSection extends StatefulWidget {
  const _TeacherGradesSection({
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
  State<_TeacherGradesSection> createState() => _TeacherGradesSectionState();
}

class _TeacherGradesSectionState extends State<_TeacherGradesSection> {
  TeacherAssignment? _selected;
  Future<List<SectionStudent>>? _studentsFuture;
  String _etapa = 'BIMESTRE I';
  final TextEditingController _conceptoCtrl = TextEditingController(text: 'Evaluación de Unidad');
  final Map<int, TextEditingController> _gradeCtrls = {};
  final Map<int, TextEditingController> _obsCtrls = {};
  bool _savingBatch = false;

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    for (final c in _gradeCtrls.values) {
      c.dispose();
    }
    for (final c in _obsCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _pickAssignment(TeacherAssignment a) {
    setState(() {
      _selected = a;
      _studentsFuture = _fetchStudentsWithFallback(widget.api, a.id);
    });
  }

  String _literalLevel(double? nota) {
    if (nota == null) return '--';
    if (nota >= 18) return 'AD';
    if (nota >= 14) return 'A';
    if (nota >= 11) return 'B';
    return 'C';
  }

  Color _literalColor(double? nota) {
    if (nota == null) return Colors.black45;
    if (nota >= 14) return _green;
    if (nota >= 11) return _orange;
    return Colors.red;
  }

  Future<void> _saveBatch(List<SectionStudent> students) async {
    if (_selected == null) return;
    final concepto = _conceptoCtrl.text.trim();
    if (concepto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el concepto de evaluación (ej. Examen Parcial)')),
      );
      return;
    }

    int count = 0;
    setState(() => _savingBatch = true);
    for (final st in students) {
      final raw = _gradeCtrls[st.matriculaId]?.text.trim().replaceAll(',', '.') ?? '';
      final nota = double.tryParse(raw);
      if (nota == null || nota < 0 || nota > 20) continue;
      count++;
      if (_selected!.id > 0) {
        try {
          await widget.api.registrarCalificacion(
            asignacionId: _selected!.id,
            matriculaId: st.matriculaId,
            etapa: _etapa,
            concepto: concepto,
            nota: nota,
            observacion: _obsCtrls[st.matriculaId]?.text,
          );
        } catch (_) {}
      }
    }
    if (mounted) {
      setState(() => _savingBatch = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'Ingresa al menos una nota válida entre 0 y 20'
                : 'Se guardaron $count calificaciones en $_etapa ($concepto)',
          ),
        ),
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
            child: Center(child: CircularProgressIndicator(color: _orange)),
          );
        }
        if (snapshot.hasError) {
          return _ErrorCard(error: snapshot.error, onRetry: widget.onRetry, onLogout: widget.onLogout);
        }
        final assignments = snapshot.data ?? [];
        _selected ??= assignments.first;
        _studentsFuture ??= _fetchStudentsWithFallback(widget.api, _selected!.id);

        return FutureBuilder<List<SectionStudent>>(
          future: _studentsFuture,
          builder: (context, stSnap) {
            final students = stSnap.data ?? [];
            for (final st in students) {
              _gradeCtrls.putIfAbsent(st.matriculaId, () => TextEditingController());
              _obsCtrls.putIfAbsent(st.matriculaId, () => TextEditingController());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 280,
                        child: DropdownButtonFormField<TeacherAssignment>(
                           isExpanded: true,
                          initialValue: _selected,
                          decoration: const InputDecoration(
                            labelText: 'Curso y Sección',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: assignments
                              .map((a) => DropdownMenuItem(value: a, child: Text('${a.cursoNombre} · ${a.gradoNombre} "${a.seccionNombre}",overflow: TextOverflow.ellipsis,')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) _pickAssignment(val);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: DropdownButtonFormField<String>(
                           isExpanded: true,
                          initialValue: _etapa,
                          decoration: const InputDecoration(
                            labelText: 'Periodo / Etapa',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const ['BIMESTRE I', 'BIMESTRE II', 'BIMESTRE III', 'BIMESTRE IV']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _etapa = val);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: _conceptoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Concepto (ej. Examen Parcial)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: _orange),
                        onPressed: (students.isEmpty || _savingBatch) ? null : () => _saveBatch(students),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: Text(_savingBatch ? 'Guardando...' : 'Guardar Calificaciones'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (stSnap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator(color: _orange)),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < students.length; i++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final ctrl = _gradeCtrls[students[i].matriculaId]!;
                                final obs = _obsCtrls[students[i].matriculaId]!;
                                final parsed = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
                                final level = _literalLevel(parsed);
                                final levelColor = _literalColor(parsed);

                                return Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  runSpacing: 10,
                                  children: [
                                    SizedBox(
                                      width: constraints.maxWidth > 680 ? 310 : constraints.maxWidth,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 17,
                                            backgroundColor: _navy,
                                            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(students[i].nombreCompleto, style: const TextStyle(color: _navy, fontWeight: FontWeight.w700)),
                                                Text('Código: ${students[i].codigoEstudiante}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 10,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 105,
                                          child: TextField(
                                            controller: ctrl,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(
                                              labelText: 'Nota (0-20)',
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        Container(
                                          width: 40,
                                          height: 36,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: levelColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            level,
                                            style: TextStyle(color: levelColor, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 210,
                                          child: TextField(
                                            controller: obs,
                                            decoration: const InputDecoration(
                                              labelText: 'Observación (opcional)',
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          if (i < students.length - 1) const Divider(height: 1, color: _border),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.error,
    required this.onRetry,
    required this.onLogout,
  });

  final Object? error;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isUnauthorized = error is TeacherFailure && (error as TeacherFailure).kind == TeacherFailureKind.unauthorized;
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text(
              isUnauthorized
                  ? 'Tu sesión expiró. Inicia sesión nuevamente.'
                  : 'No se pudo cargar la información del docente.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: isUnauthorized ? onLogout : onRetry,
              child: Text(isUnauthorized ? 'Ir a inicio de sesión' : 'Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
