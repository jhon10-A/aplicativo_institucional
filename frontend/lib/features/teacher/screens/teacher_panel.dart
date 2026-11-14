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
    _assignmentsFuture = _api.getAsignaciones();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _profileFuture = _api.getPerfil();
      _assignmentsFuture = _api.getAsignaciones();
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
    final courseCtrl = TextEditingController(text: 'Matemática · 3° A');
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
                                  onRetry: _reload,
                                  onLogout: widget.onLogout,
                                ),
                              )
                            else
                              _buildSubViewWrapper(
                                title: _activeView == 2
                                    ? 'Mis Estudiantes'
                                    : _activeView == 3
                                        ? 'Registro de Asistencia'
                                        : 'Ingreso de Calificaciones',
                                child: _TeacherManagementSection(
                                  api: _api,
                                  assignmentsFuture: _assignmentsFuture,
                                  initialMode: _activeView == 4 ? 1 : 0,
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => _activeView = 0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/institutional/escudo.png',
                      height: 42,
                      errorBuilder: (_, _, _) => const CircleAvatar(
                        backgroundColor: _navy,
                        child: Text('MB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'I.E. Micaela Bastidas\nPuyucahua',
                          style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 13, height: 1.15),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tamburco · Abancay · Apurímac',
                          style: TextStyle(color: Colors.black54, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
              const SizedBox(width: 6),
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
            Text(title, style: const TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w800)),
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

          if (assignments.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Text(
                    'Aún no tienes cursos asignados en el periodo actual.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _activeView = 1),
                    child: const Text('Ir a gestión de cursos'),
                  ),
                ],
              ),
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
          children: assignments
              .map(
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
                      child: const Text('Ver Alumnos'),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _TeacherManagementSection extends StatefulWidget {
  const _TeacherManagementSection({
    required this.api,
    required this.assignmentsFuture,
    required this.initialMode,
    required this.onRetry,
    required this.onLogout,
  });

  final TeacherApi api;
  final Future<List<TeacherAssignment>> assignmentsFuture;
  final int initialMode;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  State<_TeacherManagementSection> createState() => _TeacherManagementSectionState();
}

class _TeacherManagementSectionState extends State<_TeacherManagementSection> {
  TeacherAssignment? _selectedAssignment;
  Future<List<SectionStudent>>? _studentsFuture;
  late bool _isAttendanceMode;
  final DateTime _fecha = DateTime.now();

  @override
  void initState() {
    super.initState();
    _isAttendanceMode = widget.initialMode == 0;
  }

  @override
  void didUpdateWidget(covariant _TeacherManagementSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      _isAttendanceMode = widget.initialMode == 0;
    }
  }

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
                                        label: Text(estado, style: const TextStyle(fontSize: 11)),
                                        onPressed: () => _saveAttendance(st, estado),
                                      ),
                                    )
                                    .toList(),
                              )
                            else
                              FilledButton.icon(
                                onPressed: () => _openGradeDialog(st),
                                icon: const Icon(Icons.edit_note, size: 18),
                                label: const Text('Registrar Nota'),
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



