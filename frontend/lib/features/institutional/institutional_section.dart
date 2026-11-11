import 'package:flutter/material.dart';

enum InstitutionalSection {
  institution('Nuestra Institución', Icons.account_balance_outlined),
  social('Redes Sociales', Icons.campaign_outlined),
  achievements('Logros', Icons.emoji_events_outlined),
  gallery('Galerías', Icons.photo_library_outlined),
  events('Eventos', Icons.event_outlined),
  location('Ubicación', Icons.location_on_outlined);

  const InstitutionalSection(this.title, this.icon);
  final String title;
  final IconData icon;
}
