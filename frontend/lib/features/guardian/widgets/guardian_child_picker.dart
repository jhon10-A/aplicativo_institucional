import 'package:flutter/material.dart';

import '../guardian_api.dart';
import '../guardian_child.dart';
import '../guardian_section.dart';
import '../guardian_theme.dart';
import 'guardian_message.dart';
import 'guardian_widgets.dart';

/// Carga los hijos del apoderado, deja elegir uno y construye el contenido
/// de la sección para el hijo elegido. Lo reutilizan Calificaciones, Asistencia, etc.
class GuardianChildPicker extends StatefulWidget {
  const GuardianChildPicker({
    super.key,
    required this.api,
    required this.section,
    required this.builder,
  });
  final GuardianApi api;
  final GuardianSection section;
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: GuardianSectionHeader(section: widget.section),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final c in children)
                      _ChildOption(
                        child: c,
                        selected: c.id == selected.id,
                        onTap: children.length > 1
                            ? () => setState(() => _selectedId = c.id)
                            : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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

class _ChildOption extends StatelessWidget {
  const _ChildOption({
    required this.child,
    required this.selected,
    required this.onTap,
  });
  final GuardianChild child;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Semantics(
      selected: selected,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? guardianWine : const Color(0xFFDDEAF4),
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('guardian-pick-${child.id}'),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GuardianAvatar(
                  initials: guardianInitials(child.nombres, child.apellidos),
                  size: 44,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.nombreCompleto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (child.aula.isNotEmpty)
                        Text(
                          child.aula,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: guardianWine),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
