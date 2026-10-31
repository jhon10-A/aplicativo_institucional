import 'package:flutter/material.dart';

import '../access_profile.dart';
import '../auth.dart';
import '../widgets/institutional_brand.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
    required this.api,
    required this.access,
    required this.onLogin,
    required this.onBack,
  });
  final AuthApi api;
  final AccessProfile access;
  final ValueChanged<Session> onLogin;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFECF5FD),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            InstitutionalHeader(
              onBack: onBack,
              wine: access == AccessProfile.estudiante,
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final form = _form(context);
                      if (constraints.maxWidth < 640) return form;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    access.icon,
                                    size: 100,
                                    color: access.color,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    access.motto,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: institutionalWine,
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(flex: 2, child: form),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const InstitutionalFooter(),
          ],
        ),
      ),
    ),
  );

  Widget _form(BuildContext context) => Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: institutionalWine,
              borderRadius: BorderRadius.circular(18),
              border: const Border(
                bottom: BorderSide(color: institutionalGold, width: 3),
              ),
            ),
            child: Column(
              children: [
                Icon(access.icon, color: Colors.white, size: 34),
                const SizedBox(height: 8),
                Text(
                  access.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 23,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ingresa a tu cuenta institucional',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LoginForm(api: api, access: access, onLogin: onLogin),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.home_outlined),
            label: const Text('Regresar al menú principal'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCEFFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Tu usuario y contraseña son proporcionados por la institución educativa. '
              'Si tienes problemas, comunícate con la dirección.',
              style: TextStyle(color: institutionalNavy),
            ),
          ),
        ],
      ),
    ),
  );
}
