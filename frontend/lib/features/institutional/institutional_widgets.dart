import 'package:flutter/material.dart';

import 'institutional_section.dart';

const publicWine = Color(0xFF800638);
const publicNavy = Color(0xFF103966);
const publicBackground = Color(0xFFF0F7FF);
const publicAssets = 'assets/institutional/';

class InstitutionalArtwork extends StatelessWidget {
  const InstitutionalArtwork(this.name, {super.key, required this.label});
  final String name;
  final String label;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: switch (name) {
      'inicio-cabecera.png' => 959 / 563,
      'institutional-header.png' => 1024 / 165,
      'institutional-footer.png' => 1024 / 196,
      'login-header-student.png' => 1024 / 330,
      'login-character-student.png' => 305 / 890,
      'social-banner.png' => 1070 / 115,
      'achievements-banner.png' => 900 / 195,
      'technology-banner.png' => 900 / 255,
      'institucion.jpg' => 380 / 240,
      'colegio.jpg' => 905 / 315,
      _ => 1.4,
    },
    child: Image.asset(
      '$publicAssets$name',
      width: double.infinity,
      fit: BoxFit.contain,
      semanticLabel: label,
      errorBuilder: (context, error, stack) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(label, textAlign: TextAlign.center),
      ),
    ),
  );
}

class InstitutionalLayout extends StatelessWidget {
  const InstitutionalLayout({
    super.key,
    required this.child,
    this.onBack,
    this.title,
    this.section,
    this.onSection,
    this.header,
    this.maxWidth = 1120,
  });
  final Widget child;
  final VoidCallback? onBack;
  final String? title;
  final InstitutionalSection? section;
  final ValueChanged<InstitutionalSection>? onSection;
  final Widget? header;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: publicBackground,
    bottomNavigationBar: onSection == null
        ? null
        : SafeArea(
            top: false,
            child: Container(
              key: const Key('institutional-bottom-navigation'),
              decoration: BoxDecoration(
                color: publicWine,
                borderRadius: section == InstitutionalSection.location
                    ? const BorderRadius.vertical(top: Radius.circular(24))
                    : null,
                border: section == InstitutionalSection.location
                    ? const Border(
                        top: BorderSide(color: Color(0xFFF2BD36), width: 3),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(child: _nav('Inicio', Icons.home_outlined, onBack)),
                  for (final item in [
                    InstitutionalSection.institution,
                    InstitutionalSection.gallery,
                    InstitutionalSection.events,
                    InstitutionalSection.location,
                  ])
                    Expanded(
                      child: _nav(
                        item == InstitutionalSection.institution
                            ? 'Institución'
                            : item.title,
                        item.icon,
                        () => onSection!(item),
                        selected: item == section,
                      ),
                    ),
                ],
              ),
            ),
          ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header ??
                    const InstitutionalArtwork(
                      'institutional-header.png',
                      label: 'I.E. Micaela Bastidas Puyucahua · Tamburco · Abancay · Apurímac',
                    ),
                if (header == null && onBack != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: onBack,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Volver al inicio'),
                            ),
                          ),
                        ),
                        if (onSection != null)
                          PopupMenuButton<InstitutionalSection>(
                            tooltip: 'Secciones institucionales',
                            onSelected: onSection,
                            itemBuilder: (_) => [
                              for (final s in InstitutionalSection.values)
                                PopupMenuItem(value: s, child: Text(s.title)),
                            ],
                          ),
                      ],
                    ),
                  ),
                if (header == null && title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: publicWine,
                      ),
                    ),
                  ),
                Padding(padding: const EdgeInsets.all(16), child: child),
                const InstitutionalArtwork(
                  'institutional-footer.png',
                  label: 'Juntos construimos una mejor educación',
                ),
                if (section == InstitutionalSection.location)
                  const SizedBox(
                    key: Key('location-scroll-end-spacer'),
                    height: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _nav(
    String label,
    IconData icon,
    VoidCallback? onTap, {
    bool selected = false,
  }) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: selected ? Colors.white12 : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    ),
  );
}

class PublicCard extends StatelessWidget {
  const PublicCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDCE8F6)),
    ),
    child: child,
  );
}

class PublicationEmpty extends StatelessWidget {
  const PublicationEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => PublicCard(
    child: Column(
      children: [
        Icon(icon, size: 48, color: publicWine),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: publicNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: publicNavy, height: 1.6),
        ),
      ],
    ),
  );
}
