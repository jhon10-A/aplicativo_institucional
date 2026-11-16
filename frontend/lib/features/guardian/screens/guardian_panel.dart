import 'package:flutter/material.dart';

import '../../../auth.dart';
import '../guardian_api.dart';
import '../guardian_section.dart';
import '../guardian_theme.dart';
import '../widgets/guardian_header.dart';
import '../widgets/guardian_home.dart';
import '../widgets/guardian_navigation.dart';
import 'guardian_announcements_screen.dart';
import 'guardian_attendance_screen.dart';
import 'guardian_children_screen.dart';
import 'guardian_grades_screen.dart';

class GuardianPanel extends StatefulWidget {
  const GuardianPanel({
    super.key,
    required this.session,
    required this.onLogout,
    this.api,
  });
  final Session session;
  final VoidCallback onLogout;

  /// Solo para pruebas: permite inyectar una API simulada.
  final GuardianApi? api;

  @override
  State<GuardianPanel> createState() => _GuardianPanelState();
}

class _GuardianPanelState extends State<GuardianPanel> {
  GuardianSection _section = GuardianSection.inicio;
  late final GuardianApi _api =
      widget.api ??
      GuardianApi(
        baseUrl: const String.fromEnvironment('API_BASE_URL'),
        token: widget.session.accessToken,
      );

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  void _select(GuardianSection section) => setState(() => _section = section);

  Widget _body() => switch (_section) {
    GuardianSection.inicio => GuardianHome(
      session: widget.session,
      onSelect: _select,
    ),
    GuardianSection.hijos => GuardianChildrenScreen(api: _api),
    GuardianSection.calificaciones => GuardianGradesScreen(api: _api),
    GuardianSection.asistencia => GuardianAttendanceScreen(api: _api),
    GuardianSection.comunicados => GuardianAnnouncementsScreen(api: _api),
  };

  @override
  Widget build(BuildContext context) => Theme(
    data: guardianTheme(Theme.of(context)),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_section != GuardianSection.inicio) {
              _select(GuardianSection.inicio);
            } else {
              widget.onLogout();
            }
          },
          child: Scaffold(
            drawer: wide
                ? null
                : Drawer(
                    child: Builder(
                      builder: (context) => GuardianNavigation(
                        selected: _section,
                        onSelect: (section) {
                          Scaffold.of(context).closeDrawer();
                          _select(section);
                        },
                      ),
                    ),
                  ),
            body: SafeArea(
              child: Column(
                children: [
                  GuardianHeader(onLogout: widget.onLogout),
                  _SectionBar(title: _section.label, showMenu: !wide),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (wide) ...[
                          SizedBox(
                            width: 250,
                            child: GuardianNavigation(
                              selected: _section,
                              onSelect: _select,
                            ),
                          ),
                          const VerticalDivider(width: 1),
                        ],
                        Expanded(child: _body()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Barra vino oscuro bajo el encabezado: menú (en pantallas angostas) y sección actual.
class _SectionBar extends StatelessWidget {
  const _SectionBar({required this.title, required this.showMenu});
  final String title;
  final bool showMenu;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: guardianWineDark,
    padding: EdgeInsets.symmetric(horizontal: showMenu ? 4 : 20, vertical: 4),
    child: Row(
      children: [
        if (showMenu)
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Abrir navegación',
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: showMenu ? 0 : 10,
              horizontal: showMenu ? 4 : 0,
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
