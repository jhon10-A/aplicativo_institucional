import 'package:flutter/material.dart';

import '../../../auth.dart';
import '../guardian_api.dart';
import '../guardian_section.dart';
import '../widgets/guardian_development_section.dart';
import '../widgets/guardian_home.dart';
import '../widgets/guardian_navigation.dart';
import 'guardian_children_screen.dart';

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

  @override
  Widget build(BuildContext context) => LayoutBuilder(
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
          appBar: AppBar(
            title: Text(
              _section.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: wide
                ? null
                : Builder(
                    builder: (context) => IconButton(
                      tooltip: 'Abrir navegación',
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
            actions: [
              if (constraints.maxWidth < 420)
                IconButton(
                  tooltip: 'Cerrar sesión',
                  icon: const Icon(Icons.logout),
                  onPressed: widget.onLogout,
                )
              else
                TextButton(
                  onPressed: widget.onLogout,
                  child: const Text('Cerrar sesión'),
                ),
            ],
          ),
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
                Expanded(
                  child: _section == GuardianSection.inicio
                      ? GuardianHome(session: widget.session, onSelect: _select)
                      : _section == GuardianSection.hijos
                      ? GuardianChildrenScreen(api: _api)
                      : GuardianDevelopmentSection(
                          section: _section,
                          onHome: () => _select(GuardianSection.inicio),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
