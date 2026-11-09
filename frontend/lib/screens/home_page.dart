import 'package:flutter/material.dart';

import '../access_profile.dart';
import '../features/institutional/institutional_section.dart';
import '../features/institutional/institutional_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onAccess,
    required this.onTechnology,
    this.onInstitutional,
  });
  final ValueChanged<AccessProfile> onAccess;
  final VoidCallback onTechnology;
  final ValueChanged<InstitutionalSection>? onInstitutional;

  static const _links = [
    (
      InstitutionalSection.institution,
      'Nuestra Institución',
      'Historia, misión y visión',
      Color(0xFF0087EF),
    ),
    (
      InstitutionalSection.social,
      'Redes Sociales',
      'Noticias de la comunidad',
      Color(0xFFD00057),
    ),
    (
      InstitutionalSection.events,
      'Eventos',
      'Actividades y fechas',
      Color(0xFF169139),
    ),
    (
      InstitutionalSection.achievements,
      'Logros',
      'Nuestros destacados',
      Color(0xFFE89000),
    ),
    (
      InstitutionalSection.gallery,
      'Galerías',
      'Fotos y videos',
      Color(0xFF8839E8),
    ),
    (
      InstitutionalSection.location,
      'Ubicación',
      'Cómo llegar',
      Color(0xFF00A8B5),
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE8F2FB),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ColoredBox(
            color: publicBackground,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      const InstitutionalArtwork(
                        'inicio-cabecera.png',
                        label:
                            'I.E. Micaela Bastidas Puyucahua. Tamburco, Abancay, Apurímac. '
                            'Formando jóvenes con valores, para un mejor futuro. ¡Bienvenidos!',
                      ),
                      // The illustration already contains the menu icon; this is its hit area.
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, bounds) => Align(
                            alignment: const Alignment(.84, -.81),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: PopupMenuButton<InstitutionalSection>(
                                tooltip: 'Menú institucional',
                                onSelected: onInstitutional,
                                icon: const SizedBox.shrink(),
                                itemBuilder: (_) => [
                                  for (final section
                                      in InstitutionalSection.values)
                                    PopupMenuItem(
                                      value: section,
                                      child: Text(section.title),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 2),
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final width = (bounds.maxWidth - 8) / 2;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final entry in [
                              (
                                AccessProfile.estudiante,
                                'acceso-estudiante.png',
                              ),
                              (AccessProfile.docente, 'acceso-docente.png'),
                              (AccessProfile.apoderado, 'acceso-familia.png'),
                            ])
                              SizedBox(
                                width: width,
                                child: _access(
                                  entry.$1.label,
                                  entry.$2,
                                  () => onAccess(entry.$1),
                                ),
                              ),
                            SizedBox(
                              width: width,
                              child: _access(
                                'Tecnología',
                                'acceso-tecnologia.png',
                                onTechnology,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(color: publicNavy)),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.groups_outlined,
                          color: publicNavy,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          flex: 4,
                          child: Text(
                            'Conoce nuestra institución',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: publicNavy,
                              fontSize: MediaQuery.sizeOf(context).width < 360
                                  ? 12
                                  : 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(child: Divider(color: publicNavy)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final largeText =
                            MediaQuery.textScalerOf(context).scale(1) > 1.3;
                        final columns = bounds.maxWidth >= 340 && !largeText
                            ? 3
                            : 2;
                        final width =
                            (bounds.maxWidth - 8 * (columns - 1)) / columns;
                        final compact = bounds.maxWidth < 500 && !largeText;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final link in _links)
                              SizedBox(
                                width: width,
                                child: Material(
                                  color: Color.lerp(
                                    Colors.white,
                                    link.$4,
                                    .035,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: link.$4.withValues(alpha: .16),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: onInstitutional == null
                                        ? null
                                        : () => onInstitutional!(link.$1),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compact ? 5 : 7,
                                        vertical: compact ? 8 : 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            link.$1.icon,
                                            color: link.$4,
                                            size: compact ? 20 : 25,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  link.$2,
                                                  style: TextStyle(
                                                    color: publicNavy,
                                                    fontSize: compact ? 9 : 11,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  link.$3,
                                                  style: TextStyle(
                                                    color: Color(0xFF50758E),
                                                    fontSize: compact ? 7.5 : 9,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: link.$4,
                                            size: compact ? 11 : 15,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const AspectRatio(
                    aspectRatio: 409.8 / 63.3,
                    child: Image(
                      image: AssetImage('assets/institutional/inicio-pie.png'),
                      fit: BoxFit.contain,
                      semanticLabel: 'Juntos construimos una mejor educación',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _access(String label, String asset, VoidCallback onTap) => Semantics(
    label: label,
    button: true,
    child: Tooltip(
      message: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x180A477D),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: 1.4,
              child: ExcludeSemantics(
                child: Image.asset('$publicAssets$asset', fit: BoxFit.fill),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
