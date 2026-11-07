import 'package:flutter/material.dart';

import '../../../auth.dart';
import '../student_section.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key, required this.session, required this.onSelect});
  final Session session;
  final ValueChanged<StudentSection> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Panel del estudiante',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      '${session.nombres} ${session.apellidos}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Usuario: ${session.nombreUsuario}'),
                    const SizedBox(height: 8),
                    Text('Roles: ${session.roles.join(', ')}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Secciones', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final section in StudentSection.values.where(
              (s) => s != StudentSection.inicio,
            ))
              Card(
                child: ListTile(
                  key: ValueKey('student-shortcut-${section.name}'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Icon(section.icon),
                  title: Text(section.label),
                  subtitle: const Text('Sección en desarrollo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onSelect(section),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
