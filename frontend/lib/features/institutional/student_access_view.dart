import 'package:flutter/material.dart';

import '../../access_profile.dart';
import '../../auth.dart';
import '../../widgets/login_form.dart';
import 'institutional_widgets.dart';

/// Student-only presentation; authentication remains in the existing form.
class StudentAccessView extends StatelessWidget {
  const StudentAccessView({
    super.key,
    required this.api,
    required this.onLogin,
    required this.onBack,
  });
  final AuthApi api;
  final ValueChanged<Session> onLogin;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => InstitutionalLayout(
    onBack: onBack,
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: const InstitutionalArtwork(
            'login-header-student.png',
            label: 'Nuestra institución educativa',
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, bounds) {
            final form = PublicCard(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: publicWine,
                      borderRadius: BorderRadius.circular(20),
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFFF2BD36), width: 3),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.school, color: Colors.white, size: 34),
                        Text(
                          'Soy estudiante',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Ingresa a tu cuenta institucional',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  LoginForm(
                    api: api,
                    access: AccessProfile.estudiante,
                    onLogin: onLogin,
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Regresar al menú principal'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Tu usuario y contraseña son proporcionados por la institución educativa. '
                      'Si tienes problemas, comunícate con la dirección.',
                      style: TextStyle(color: publicNavy),
                    ),
                  ),
                ],
              ),
            );
            final character = ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: const InstitutionalArtwork(
                'login-character-student.png',
                label: 'Ilustración decorativa de una estudiante',
              ),
            );
            if (bounds.maxWidth >= 650) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: character),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: form),
                ],
              );
            }
            return Column(
              children: [
                SizedBox(height: 170, child: character),
                form,
              ],
            );
          },
        ),
      ],
    ),
  );
}
