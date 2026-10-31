import 'dart:async';

import 'package:flutter/material.dart';

import 'access_profile.dart';
import 'auth.dart';
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
  Session? _session;
  Timer? _expiration;

  void _home() {
    _expiration?.cancel();
    setState(() {
      _session = null;
      _access = null;
      _technology = false;
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
  Widget build(BuildContext context) => MaterialApp(
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
      canPop: _access == null && !_technology && _session == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _home();
      },
      child: _session != null
          ? SessionPage(session: _session!, onLogout: _home)
          : _access != null
          ? LoginPage(
              key: ValueKey(_access),
              api: _api,
              access: _access!,
              onLogin: _login,
              onBack: _home,
            )
          : _technology
          ? TechnologyPage(onBack: _home)
          : HomePage(
              onAccess: (access) => setState(() => _access = access),
              onTechnology: () => setState(() => _technology = true),
            ),
    ),
  );
}
