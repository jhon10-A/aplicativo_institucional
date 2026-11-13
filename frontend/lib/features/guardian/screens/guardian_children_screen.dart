import 'package:flutter/material.dart';

import '../guardian_api.dart';
import '../guardian_child.dart';

class GuardianChildrenScreen extends StatefulWidget {
  const GuardianChildrenScreen({super.key, required this.api});
  final GuardianApi api;

  @override
  State<GuardianChildrenScreen> createState() => _GuardianChildrenScreenState();
}

class _GuardianChildrenScreenState extends State<GuardianChildrenScreen> {
  late Future<List<GuardianChild>> _future = widget.api.children();

    void _retry() {
    setState(() {
      _future = widget.api.children();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<GuardianChild>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        return _Message(
          icon: Icons.error_outline,
          text: error is GuardianFailure
              ? error.message
              : 'Ocurrió un error inesperado.',
          onRetry: _retry,
        );
      }
      final children = snapshot.data!;
      if (children.isEmpty) {
        return const _Message(
          icon: Icons.family_restroom,
          text:
              'Aún no tienes hijos vinculados. Consulta en secretaría para registrar el vínculo.',
        );
      }
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Mis hijos',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  for (final child in children) _ChildCard(child: child),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child});
  final GuardianChild child;

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('guardian-child-${child.id}'),
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  child.nombreCompleto,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Código: ${child.codigoEstudiante}'),
          const SizedBox(height: 4),
          Text(
            'Parentesco: ${child.parentesco}'
            '${child.contactoPrincipal ? ' (contacto principal)' : ''}',
          ),
          const SizedBox(height: 4),
          if (child.matriculaId == null)
            const Text('Sin matrícula registrada')
          else ...[
            Text(child.aula),
            const SizedBox(height: 4),
            Text('Periodo ${child.periodo} · Matrícula ${child.estado}'),
          ],
        ],
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
