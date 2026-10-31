import 'package:flutter/material.dart';

import '../auth.dart';
import '../widgets/institutional_brand.dart';

class SessionPage extends StatelessWidget {
  const SessionPage({super.key, required this.session, required this.onLogout});
  final Session session;
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mi sesión'),
      actions: [
        TextButton(onPressed: onLogout, child: const Text('Cerrar sesión')),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const InstitutionalHeader(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${session.nombres} ${session.apellidos}',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text('Usuario: ${session.nombreUsuario}'),
                  const SizedBox(height: 12),
                  Text(
                    'Roles: ${session.roles.join(', ')}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
