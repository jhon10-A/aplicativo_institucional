import 'dart:async';

import 'package:flutter/material.dart';

import 'access_profile.dart';
import 'auth.dart';

import 'features/guardian/screens/guardian_panel.dart';
import 'features/institutional/institutional_page.dart';
import 'features/institutional/institutional_section.dart';
import 'features/student/screens/student_panel.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/session_page.dart';
import 'screens/technology_page.dart';
import 'widgets/institutional_brand.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.authApi});
  final AuthApi? authApi;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthApi _api = widget.authApi ?? AuthApi();
  AccessProfile? _access;
  bool _technology = false;
  InstitutionalSection? _institutional;
  Session? _session;
  Timer? _expiration;

  void _home() {
    _expiration?.cancel();
    setState(() {
      _session = null;
      _access = null;
      _technology = false;
      _institutional = null;
    });
  }

  void _login(Session session) {
    // The selected presentation cannot manufacture or grant a backend role.
    if (_access == null || !session.roles.contains(_access!.role)) return;
    _expiration?.cancel();
    setState(() => _session = session);
    _expiration = Timer(session.expiresAt.difference(DateTime.now()), _home);
  }

  @override
  void dispose() {
    _expiration?.cancel();
    _session = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentSession =
        _session != null &&
        _access == AccessProfile.estudiante &&
        _session!.roles.contains('ESTUDIANTE');
    final guardianSession =
        _session != null &&
        _access == AccessProfile.apoderado &&
        _session!.roles.contains('APODERADO');
    return MaterialApp(
      // Discard private routes and dialogs on login, logout or session expiry.
      // Object identity avoids putting the token into widget diagnostics.
      key: ObjectKey(_session),
      title: 'I.E. Micaela Bastidas Puyucahua',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: institutionalWine,
          primary: institutionalWine,
          secondary: institutionalNavy,
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F7FD),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4F8FF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFBCD4EC)),
          ),
        ),
      ),
      home: PopScope(
        canPop:
            _access == null &&
            !_technology &&
            _session == null &&
            _institutional == null,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !studentSession && !guardianSession) _home();
        },
        child: _session != null
            ? studentSession
                  ? StudentPanel(session: _session!, onLogout: _home,apiBaseUrl: _api.baseUrl,)
                  : guardianSession
                  ? GuardianPanel(session: _session!, onLogout: _home)
                  : SessionPage(session: _session!, onLogout: _home)
            : _access != null
            ? LoginPage(
                key: ValueKey(_access),
                api: _api,
                access: _access!,
                onLogin: _login,
                onBack: _home,
              )
            : _institutional != null
            ? InstitutionalPage(
                section: _institutional!,
                onBack: _home,
                onSection: (section) =>
                    setState(() => _institutional = section),
              )
            : _technology
            ? TechnologyPage(onBack: _home)
            : HomePage(
                onInstitutional: (section) =>
                    setState(() => _institutional = section),
                onAccess: (access) => setState(() => _access = access),
                onTechnology: () => setState(() => _technology = true),
              ),
      ),
    );
  }
}
