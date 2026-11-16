import 'package:flutter/material.dart';

import '../guardian_api.dart';
import '../guardian_child.dart';
import '../guardian_section.dart';
import '../widgets/guardian_message.dart';
import '../widgets/guardian_widgets.dart';

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
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const GuardianSectionHeader(section: GuardianSection.hijos),
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GuardianAvatar(
                initials: guardianInitials(child.nombres, child.apellidos),
                size: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.nombreCompleto,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (child.aula.isNotEmpty) Text(child.aula),
                  ],
                ),
              ),
              if (child.matriculaId != null) ...[
                const SizedBox(width: 8),
                _StatusChip(estado: child.estado),
              ],
            ],
          ),
          const Divider(),
          _InfoRow(
            icon: Icons.badge_outlined,
            text: 'Código: ${child.codigoEstudiante}',
          ),
          _InfoRow(
            icon: Icons.family_restroom,
            text:
                'Parentesco: ${child.parentesco}'
                '${child.contactoPrincipal ? ' (contacto principal)' : ''}',
          ),
          if (child.matriculaId == null)
            const _InfoRow(
              icon: Icons.info_outline,
              text: 'Sin matrícula registrada',
            )
          else
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text: 'Periodo ${child.periodo} · Matrícula ${child.estado}',
            ),
        ],
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.estado});
  final String? estado;

  @override
  Widget build(BuildContext context) {
    final active = estado == 'ACTIVA';
    final color = active ? const Color(0xFF1E8E3E) : const Color(0xFF5B6B7F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'En curso' : (estado ?? ''),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
