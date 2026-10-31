import 'package:flutter/material.dart';

import '../student_section.dart';

class DevelopmentSection extends StatelessWidget {
  const DevelopmentSection({
    super.key,
    required this.section,
    required this.onHome,
  });
  final StudentSection section;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(
              section.icon,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              section.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sección en desarrollo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onHome,
              icon: const Icon(Icons.home_outlined),
              label: const Text('Volver al inicio del panel'),
            ),
          ],
        ),
      ),
    ),
  );
}
