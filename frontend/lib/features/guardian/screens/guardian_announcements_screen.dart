import 'package:flutter/material.dart';

import '../guardian_announcement.dart';
import '../guardian_api.dart';
import '../guardian_section.dart';
import '../guardian_theme.dart';
import '../widgets/guardian_message.dart';
import '../widgets/guardian_widgets.dart';

const _badgeColors = <Color>[
  guardianWine,
  Color(0xFF1E8E3E),
  Color(0xFF1565C0),
  Color(0xFF7B3FA0),
];

const _months = <String>[
  'ENE',
  'FEB',
  'MAR',
  'ABR',
  'MAY',
  'JUN',
  'JUL',
  'AGO',
  'SEP',
  'OCT',
  'NOV',
  'DIC',
];

/// Convierte aaaa-mm-dd en día y mes abreviado para la insignia de fecha.
(String, String) _dayAndMonth(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return ('--', '');
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  return (
    day == null ? '--' : day.toString().padLeft(2, '0'),
    month != null && month >= 1 && month <= 12 ? _months[month - 1] : '',
  );
}

class GuardianAnnouncementsScreen extends StatefulWidget {
  const GuardianAnnouncementsScreen({super.key, required this.api});
  final GuardianApi api;

  @override
  State<GuardianAnnouncementsScreen> createState() =>
      _GuardianAnnouncementsScreenState();
}

class _GuardianAnnouncementsScreenState
    extends State<GuardianAnnouncementsScreen> {
  late Future<List<GuardianAnnouncement>> _future = widget.api
      .announcements();

  void _retry() {
    setState(() {
      _future = widget.api.announcements();
    });
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<GuardianAnnouncement>>(
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
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const GuardianMessage(
              icon: Icons.campaign_outlined,
              text: 'No hay comunicados por ahora.',
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
                      const GuardianSectionHeader(
                        section: GuardianSection.comunicados,
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < items.length; i++)
                        _AnnouncementCard(item: items[i], index: i),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item, required this.index});
  final GuardianAnnouncement item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final (day, month) = _dayAndMonth(item.fecha);
    return Card(
      key: ValueKey('guardian-announcement-${item.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _badgeColors[index % _badgeColors.length],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    month,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.autor} · ${item.fecha}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(item.contenido),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
