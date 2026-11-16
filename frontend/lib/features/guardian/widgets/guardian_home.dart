import 'package:flutter/material.dart';

import '../../../auth.dart';
import '../guardian_section.dart';
import '../guardian_theme.dart';

const _tileColors = <GuardianSection, Color>{
  GuardianSection.hijos: Color(0xFF1565C0),
  GuardianSection.calificaciones: Color(0xFF7B3FA0),
  GuardianSection.asistencia: Color(0xFF1E8E3E),
  GuardianSection.comunicados: Color(0xFFC76A00),
};

class GuardianHome extends StatelessWidget {
  const GuardianHome({super.key, required this.session, required this.onSelect});
  final Session session;
  final ValueChanged<GuardianSection> onSelect;

  String get _initials {
    String first(String value) =>
        value.trim().isEmpty ? '' : value.trim().substring(0, 1).toUpperCase();
    final text = '${first(session.nombres)}${first(session.apellidos)}';
    return text.isEmpty ? '?' : text;
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: guardianWine,
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '¡Bienvenido(a)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${session.nombres} ${session.apellidos}',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tu compromiso fortalece la educación de tus hijos.',
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Roles: ${session.roles.join(', ')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 905 / 315,
                    child: Image.asset(
                      'assets/institutional/colegio.jpg',
                      fit: BoxFit.cover,
                      semanticLabel:
                          'Fachada de la I.E. Micaela Bastidas Puyucahua',
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¿Qué deseas consultar?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 4 : 2;
                final tileWidth =
                    (constraints.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entry in _tileColors.entries)
                      SizedBox(
                        width: tileWidth,
                        child: _Tile(
                          section: entry.key,
                          color: entry.value,
                          onTap: () => onSelect(entry.key),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 1024 / 196,
                child: Image.asset(
                  'assets/institutional/institutional-footer.png',
                  fit: BoxFit.cover,
                  semanticLabel: 'La educación también se vive en digital',
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.section,
    required this.color,
    required this.onTap,
  });
  final GuardianSection section;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      key: ValueKey('guardian-shortcut-${section.name}'),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 132),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(section.icon, color: Colors.white, size: 32),
              const SizedBox(height: 12),
              Text(
                section.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                section.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
