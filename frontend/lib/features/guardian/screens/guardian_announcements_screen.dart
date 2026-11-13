import 'package:flutter/material.dart';

import '../guardian_announcement.dart';
import '../guardian_api.dart';
import '../widgets/guardian_message.dart';

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
                        'Comunicados',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      for (final item in items) _AnnouncementCard(item: item),
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
  const _AnnouncementCard({required this.item});
  final GuardianAnnouncement item;

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('guardian-announcement-${item.id}'),
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.titulo, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${item.autor} · ${item.fecha}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(item.contenido),
        ],
      ),
    ),
  );
}
