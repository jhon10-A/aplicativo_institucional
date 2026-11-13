import 'package:flutter/material.dart';

import '../guardian_api.dart';
import '../guardian_child.dart';
import 'guardian_message.dart';

/// Carga los hijos del apoderado, deja elegir uno y construye el contenido
/// de la sección para el hijo elegido. Lo reutilizan Calificaciones, Asistencia, etc.
class GuardianChildPicker extends StatefulWidget {
  const GuardianChildPicker({
    super.key,
    required this.api,
    required this.title,
    required this.builder,
  });
  final GuardianApi api;
  final String title;
  final Widget Function(BuildContext context, GuardianChild child) builder;

  @override
  State<GuardianChildPicker> createState() => _GuardianChildPickerState();
}

class _GuardianChildPickerState extends State<GuardianChildPicker> {
  late Future<List<GuardianChild>> _future = widget.api.children();
  int? _selectedId;

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
        return GuardianMessage(
          icon: Icons.error_outline,
          text: error is GuardianFailure
              ? error.message
              : 'Ocurrió un error inesperado.',
          onRetry: _retry,
        );
      }
      final children = snapshot.data!;
      if (children.isEmpty) {
        return const GuardianMessage(
          icon: Icons.family_restroom,
          text:
              'Aún no tienes hijos vinculados. Consulta en secretaría para registrar el vínculo.',
        );
      }
      final selected = children.firstWhere(
        (c) => c.id == _selectedId,
        orElse: () => children.first,
      );
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (children.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final c in children)
                        ChoiceChip(
                          key: ValueKey('guardian-pick-${c.id}'),
                          label: Text(c.nombreCompleto),
                          selected: c.id == selected.id,
                          onSelected: (_) =>
                              setState(() => _selectedId = c.id),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey(selected.id),
                  child: widget.builder(context, selected),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
