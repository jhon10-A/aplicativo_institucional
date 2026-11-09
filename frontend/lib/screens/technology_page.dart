import 'package:flutter/material.dart';

import '../features/institutional/institutional_widgets.dart';

class TechnologyPage extends StatefulWidget {
  const TechnologyPage({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  State<TechnologyPage> createState() => _TechnologyPageState();
}

class _TechnologyPageState extends State<TechnologyPage> {
  String? _category;
  static const categories = [
    ('Videos', Icons.play_circle_outline, Color(0xFFEC3157)),
    ('Fichas', Icons.article_outlined, Color(0xFF008FE9)),
    ('Trípticos', Icons.menu_book_outlined, Color(0xFF20B862)),
    ('Enlaces útiles', Icons.link, Color(0xFFF5A000)),
    ('Capacitaciones', Icons.groups_outlined, Color(0xFF9A4ACF)),
    ('Descargas', Icons.download_outlined, Color(0xFF00A7B8)),
  ];
  @override
  Widget build(BuildContext context) => InstitutionalLayout(
    onBack: widget.onBack,
    title: 'Tecnología',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: const InstitutionalArtwork(
            'technology-banner.png',
            label: '¡Aprendamos más con tecnología!',
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, bounds) {
            final columns = bounds.maxWidth >= 700 ? 6 : 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in categories)
                  SizedBox(
                    width: (bounds.maxWidth - (columns - 1) * 8) / columns,
                    child: Material(
                      color: item.$3,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => setState(() => _category = item.$1),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 4,
                          ),
                          child: Column(
                            children: [
                              Icon(item.$2, color: Colors.white),
                              const SizedBox(height: 8),
                              Text(
                                item.$1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
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
        const SizedBox(height: 20),
        if (_category != null)
          Row(
            children: [
              Expanded(child: Text('Categoría: $_category')),
              TextButton(
                onPressed: () => setState(() => _category = null),
                child: const Text('Ver todos'),
              ),
            ],
          ),
        PublicationEmpty(
          icon: Icons.devices_outlined,
          title: 'Aún no hay recursos publicados',
          message: _category == null
              ? 'Los recursos destacados y el material de la semana aparecerán aquí cuando estén confirmados.'
              : 'No hay recursos oficiales confirmados en $_category.',
        ),
      ],
    ),
  );
}
