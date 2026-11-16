import 'package:flutter/material.dart';

import '../../access_profile.dart';
import '../../auth.dart';
import '../../widgets/login_form.dart';
import '../institutional/institutional_widgets.dart';

/// Presentación del acceso de padres de familia; la autenticación sigue en LoginForm.
class GuardianAccessView extends StatelessWidget {
  const GuardianAccessView({
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
                        Text(
                          'PORTAL INSTITUCIONAL',
                          style: TextStyle(
                            color: Color(0xFFF4DCE7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 6),
                        Icon(Icons.family_restroom, color: Colors.white, size: 34),
                        Text(
                          'Padre de Familia',
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
                    access: AccessProfile.apoderado,
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
            const family = _FamilyArtwork();
            if (bounds.maxWidth >= 650) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: family,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: form),
                ],
              );
            }
            return Column(
              children: [
                const SizedBox(height: 170, child: family),
                const SizedBox(height: 12),
                form,
              ],
            );
          },
        ),
      ],
    ),
  );
}

/// Ilustración de la familia. Si el archivo no está en assets/institutional/,
/// se muestra un panel con los colores del colegio y el lema.
class _FamilyArtwork extends StatelessWidget {
  const _FamilyArtwork();

  @override
  Widget build(BuildContext context) => Image.asset(
    '${publicAssets}login-character-family.png',
    fit: BoxFit.contain,
    semanticLabel: 'Ilustración decorativa de una familia',
    errorBuilder: (context, error, stack) => const _FamilyFallback(),
  );
}

class _FamilyFallback extends StatelessWidget {
  const _FamilyFallback();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [publicWine, Color(0xFF470622)],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.family_restroom, color: Colors.white, size: 64),
            SizedBox(height: 12),
            Text(
              'Tu apoyo\ntambién educa',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Juntos por la educación\nde nuestros hijos',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFF4DCE7), fontSize: 13),
            ),
          ],
        ),
      ),
    ),
  );
}
