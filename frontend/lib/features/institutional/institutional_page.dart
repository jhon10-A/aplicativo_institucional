import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'location_map.dart';
import 'institutional_publication.dart';
import 'institutional_section.dart';
import 'institutional_widgets.dart';

class InstitutionalPage extends StatefulWidget {
  const InstitutionalPage({
    super.key,
    required this.section,
    required this.onBack,
    required this.onSection,
    this.publications = const [],
    this.verifiedLocation,
    this.verifiedWhatsAppNumber,
  });
  final InstitutionalSection section;
  final VoidCallback onBack;
  final ValueChanged<InstitutionalSection> onSection;
  final List<InstitutionalPublication> publications;
  final LatLng? verifiedLocation;
  final String? verifiedWhatsAppNumber;
  @override
  State<InstitutionalPage> createState() => _InstitutionalPageState();
}

class _InstitutionalPageState extends State<InstitutionalPage> {
  String? _selection;
  final _search = TextEditingController();

  LatLng? get _verifiedLocation {
    final location = widget.verifiedLocation ?? verifiedInstitutionLocation;
    if (!location.latitude.isFinite ||
        !location.longitude.isFinite ||
        location.latitude < -90 ||
        location.latitude > 90 ||
        location.longitude < -180 ||
        location.longitude > 180) {
      return null;
    }
    return location;
  }

  String? get _verifiedWhatsAppNumber {
    final number = widget.verifiedWhatsAppNumber;
    if (number == null ||
        !RegExp(r'^\+?[0-9\s()-]+$').hasMatch(number.trim())) {
      return null;
    }
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8 && digits.length <= 15 && !digits.startsWith('0')
        ? digits
        : null;
  }

  Uri? get _googleMapsUri {
    return Uri.parse(verifiedInstitutionGoogleMapsUrl);
  }

  Uri? get _directionsUri {
    final location = _verifiedLocation;
    if (location == null) return null;
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${location.latitude},${location.longitude}',
      'travelmode': 'walking',
    });
  }

  Uri? get _drivingRouteUri {
    final location = _verifiedLocation;
    if (location == null) return null;
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${location.latitude},${location.longitude}',
      'travelmode': 'driving',
    });
  }

  Uri? get _whatsAppUri {
    final number = _verifiedWhatsAppNumber;
    return number == null ? null : Uri.https('wa.me', '/$number');
  }

  Future<void> _openExternalLink(Uri? uri) async {
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }

  @override
  void didUpdateWidget(covariant InstitutionalPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      _selection = null;
      _search.clear();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> get _tabs => switch (widget.section) {
    InstitutionalSection.institution => [
      'Nuestra institución',
      'Historia',
      'Misión',
      'Visión',
    ],
    InstitutionalSection.social => [
      'Noticias',
      'Galería',
      'Eventos',
      'Redes sociales',
    ],
    InstitutionalSection.achievements => [
      'Todos',
      'Académicos',
      'Deportivos',
      'Culturales',
      'Artísticos',
      'Otros',
    ],
    InstitutionalSection.gallery => [
      'Todos',
      'Eventos',
      'Actividades',
      'Proyectos',
      'Logros',
    ],
    InstitutionalSection.events => [
      'Todos',
      'Académicos',
      'Culturales',
      'Deportivos',
      'Otros',
    ],
    InstitutionalSection.location => [
      'Nuestra Ubicación',
      'Cómo Llegar',
      'Referencias',
      'Contacto',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final selected = _selection ?? _tabs.first;
    return InstitutionalLayout(
      title: section.title,
      section: section,
      onBack: widget.onBack,
      onSection: widget.onSection,
      header: section == InstitutionalSection.location
          ? _locationHeader(context)
          : null,
      maxWidth: section == InstitutionalSection.location ? 940 : 1120,
      child: section == InstitutionalSection.location
          ? _locationPage(selected)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (section == InstitutionalSection.social ||
                    section == InstitutionalSection.achievements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: InstitutionalArtwork(
                        section == InstitutionalSection.social
                            ? 'social-banner.png'
                            : 'achievements-banner.png',
                        label: '${section.title} · imagen decorativa',
                      ),
                    ),
                  )
                else
                  _sectionBanner(section),
                const SizedBox(height: 14),
                if (section == InstitutionalSection.events)
                  _eventFilter(selected),
                LayoutBuilder(
                  builder: (context, bounds) {
                    final columns = bounds.maxWidth >= 820
                        ? _tabs.length
                        : bounds.maxWidth >= 500
                        ? 3
                        : 2;
                    final width =
                        (bounds.maxWidth - 8 * (columns - 1)) / columns;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tab in _tabs)
                          SizedBox(
                            width: width,
                            child: ChoiceChip(
                              label: Text(
                                tab,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: selected == tab,
                              selectedColor: publicWine,
                              labelStyle: TextStyle(
                                color: selected == tab
                                    ? Colors.white
                                    : publicNavy,
                              ),
                              onSelected: (_) =>
                                  setState(() => _selection = tab),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                if (section == InstitutionalSection.institution)
                  ..._institution(selected)
                else if (section == InstitutionalSection.achievements ||
                    section == InstitutionalSection.events ||
                    section == InstitutionalSection.gallery)
                  ..._publicationFeed(section, selected)
                else ...[
                  PublicationEmpty(
                    icon: section.icon,
                    title: _emptyTitle(section),
                    message:
                        'Aún no hay publicaciones oficiales disponibles${selected == _tabs.first ? '' : ' en «$selected»'}.',
                  ),
                  if (section == InstitutionalSection.social)
                    const PublicCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.verified_outlined,
                          color: publicWine,
                        ),
                        title: Text('Canales oficiales'),
                        subtitle: Text(
                          'No hay enlaces institucionales confirmados para mostrar.',
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _locationHeader(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF65002D), Color(0xFF89003D), Color(0xFF65002D)],
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      border: Border(bottom: BorderSide(color: Color(0xFFF2BD36), width: 3)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    child: LayoutBuilder(
      builder: (context, bounds) => Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            tooltip: 'Volver al inicio',
            color: Colors.white,
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          const SizedBox(
            width: 54,
            height: 58,
            child: Image(
              image: AssetImage('${publicAssets}escudo.png'),
              fit: BoxFit.contain,
              semanticLabel: 'Escudo de la institución educativa',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I.E. Micaela Bastidas Puyucahua',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: bounds.maxWidth < 420 ? 14 : 19,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Tamburco · Abancay · Apurímac',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (bounds.maxWidth >= 620) ...[
            const SizedBox(width: 12),
            Container(width: 1, height: 48, color: Colors.white38),
            const SizedBox(width: 14),
            const Flexible(
              child: Text(
                'Formando jóvenes con valores,\npara un mejor futuro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _locationPage(String selected) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: publicWine,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubicación',
                  style: TextStyle(
                    color: publicNavy,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Encuentra nuestra institución en el mapa y conoce cómo llegar.',
                  style: TextStyle(color: publicNavy, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const LocationHeaderIllustration(),
        ],
      ),
      const SizedBox(height: 18),
      _locationTabs(selected),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE8F6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10072E65),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const InstitutionalArtwork(
                'colegio.jpg',
                label: 'Fotografía de la institución educativa',
              ),
            ),
            const SizedBox(height: 4),
            _locationContent(selected),
          ],
        ),
      ),
    ],
  );

  Widget _locationContent(String selected) {
    final (
      description,
      includeAddress,
      includePhone,
      includeEmail,
      actions,
    ) = switch (selected) {
      'Cómo Llegar' => (
        'Consulta la dirección y elige una ruta a pie o en auto.',
        true,
        false,
        false,
        {'Cómo Llegar', 'Ruta en Auto'},
      ),
      'Referencias' => (
        'Dirección y datos institucionales disponibles.',
        true,
        true,
        true,
        <String>{},
      ),
      'Contacto' => (
        'Comunícate por teléfono o correo institucional.',
        false,
        true,
        true,
        {'Contactar'},
      ),
      _ => (null, true, true, true, null),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (description != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: Text(
              description,
              key: ValueKey('location-tab-description-$selected'),
              style: const TextStyle(
                color: publicNavy,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
        _locationInformation(
          includeAddress: includeAddress,
          includePhone: includePhone,
          includeEmail: includeEmail,
        ),
        const SizedBox(height: 8),
        _locationMap(),
        if (actions == null || actions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _locationActions(visibleActions: actions),
        ],
      ],
    );
  }

  Widget _locationTabs(String selected) => LayoutBuilder(
    builder: (context, bounds) {
      final tabs = _tabs;
      final columns = bounds.maxWidth < 620 ? 2 : 4;
      final width = (bounds.maxWidth - 8 * (columns - 1)) / columns;
      final buttons = [
        for (final tab in tabs) _locationTab(tab, selected, width),
      ];
      return columns == 2
          ? Wrap(spacing: 8, runSpacing: 8, children: buttons)
          : Row(
              children: [
                for (final (index, button) in buttons.indexed)
                  Padding(
                    padding: EdgeInsets.only(
                      right: index == buttons.length - 1 ? 0 : 8,
                    ),
                    child: button,
                  ),
              ],
            );
    },
  );

  Widget _locationTab(String tab, String selected, double width) {
    final icon = switch (tab) {
      'Nuestra Ubicación' => Icons.location_on,
      'Cómo Llegar' => Icons.alt_route,
      'Referencias' => Icons.account_balance,
      _ => Icons.phone,
    };
    final isSelected = selected == tab;
    return SizedBox(
      key: ValueKey('location-tab-$tab'),
      width: width,
      height: 42,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: tab,
        child: Material(
          color: isSelected ? publicWine : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isSelected ? publicWine : const Color(0xFFDCE8F6),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _selection = tab),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : publicNavy,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tab,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white : publicNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationInformation({
    required bool includeAddress,
    required bool includePhone,
    required bool includeEmail,
  }) {
    final details = <Widget>[
      if (includeAddress)
        _referenceDetail(
          Icons.location_on_outlined,
          'Dirección',
          'Av. Micaela Bastidas S/N\nTamburco – Abancay – Apurímac',
        ),
      if (includePhone)
        _referenceDetail(Icons.call_outlined, 'Teléfono', '083-482123'),
      if (includeEmail)
        _referenceDetail(
          Icons.mail_outline,
          'Correo institucional',
          'iemicaelabastidas@edu.pe',
        ),
    ];
    return Column(
      children: [
        for (var index = 0; index < details.length; index++) ...[
          details[index],
          if (index < details.length - 1)
            const Divider(height: 1, indent: 50, color: Color(0xFFE7EDF4)),
        ],
      ],
    );
  }

  Widget _referenceDetail(IconData icon, String title, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFF8A063F),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: publicNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: publicNavy, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _locationMap() => LayoutBuilder(
    builder: (context, bounds) {
      final mapHeight = (bounds.maxWidth * .33).clamp(120.0, 210.0);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            OpenStreetMapView(
              height: mapHeight,
              verifiedLocation: _verifiedLocation,
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Tooltip(
                message: _verifiedLocation == null
                    ? 'Google Maps estará disponible al confirmar las coordenadas del colegio.'
                    : 'Abrir la ubicación confirmada en Google Maps.',
                child: FilledButton.icon(
                  key: const Key('view-in-google-maps'),
                  onPressed: _googleMapsUri == null
                      ? null
                      : () => _openExternalLink(_googleMapsUri),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text(
                    'Ver en Google Maps',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: publicWine,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: publicWine,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _locationActions({Set<String>? visibleActions}) => LayoutBuilder(
    builder: (context, bounds) {
      final columns = bounds.maxWidth >= 680
          ? 3
          : bounds.maxWidth >= 420
          ? 2
          : 1;
      final width = (bounds.maxWidth - 8 * (columns - 1)) / columns;
      final actions =
          [
            (
              'Cómo Llegar',
              'Abre en Google Maps',
              'Disponible cuando se confirmen las coordenadas exactas del colegio.',
              Icons.navigation,
              const Color(0xFF800638),
              _directionsUri,
            ),
            (
              'Ruta en Auto',
              'Desde tu ubicación',
              'Disponible cuando se confirmen las coordenadas exactas del colegio.',
              Icons.directions_car,
              const Color(0xFF0875C9),
              _drivingRouteUri,
            ),
            (
              'Contactar',
              'Por WhatsApp',
              'Disponible cuando se confirme el número oficial de WhatsApp.',
              Icons.chat,
              const Color(0xFF138A49),
              _whatsAppUri,
            ),
          ].where(
            (action) =>
                visibleActions == null || visibleActions.contains(action.$1),
          );
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final action in actions)
            SizedBox(
              width: width,
              height: 68,
              child: Tooltip(
                message: action.$6 == null ? action.$3 : action.$2,
                child: FilledButton(
                  key: ValueKey('location-action-${action.$1}'),
                  onPressed: action.$6 == null
                      ? null
                      : () => _openExternalLink(action.$6),
                  style: FilledButton.styleFrom(
                    backgroundColor: action.$5,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: action.$5,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Semantics(
                    button: true,
                    enabled: action.$6 != null,
                    label: '${action.$1}, ${action.$2}',
                    hint: action.$6 == null ? action.$3 : null,
                    child: Row(
                      children: [
                        Icon(action.$4, size: 24),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                action.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
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
  );

  Widget _sectionBanner(InstitutionalSection section) {
    final (description, color) = switch (section) {
      InstitutionalSection.institution => (
        'Conoce más sobre nuestra historia, misión, visión y todo lo que nos identifica.',
        publicWine,
      ),
      InstitutionalSection.gallery => (
        'Momentos que nos unen, logros que nos inspiran.',
        publicNavy,
      ),
      InstitutionalSection.events => (
        'Actividades que fortalecen nuestra comunidad educativa.',
        publicNavy,
      ),
      InstitutionalSection.location => (
        'Encuentra nuestra institución y conoce cómo llegar.',
        publicWine,
      ),
      _ => (_subtitle(section), publicNavy),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.black, .2)!],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(section.icon, color: Colors.white, size: 38),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventFilter(String selected) => Align(
    alignment: Alignment.centerRight,
    child: PopupMenuButton<String>(
      tooltip: 'Filtrar eventos',
      initialValue: selected,
      onSelected: (value) => setState(() => _selection = value),
      itemBuilder: (_) => [
        for (final category in _tabs)
          PopupMenuItem(value: category, child: Text(category)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCE8F6)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, color: publicNavy),
            SizedBox(width: 8),
            Text('Filtrar', style: TextStyle(color: publicNavy)),
            SizedBox(width: 4),
            Icon(Icons.expand_more, color: publicNavy),
          ],
        ),
      ),
    ),
  );

  List<Widget> _publicationFeed(InstitutionalSection section, String selected) {
    final type = switch (section) {
      InstitutionalSection.achievements =>
        InstitutionalPublicationType.achievement,
      InstitutionalSection.events => InstitutionalPublicationType.event,
      InstitutionalSection.gallery => InstitutionalPublicationType.album,
      _ => throw ArgumentError.value(section, 'section'),
    };
    final query = _search.text.trim().toLowerCase();
    final items = widget.publications.where((item) {
      if (item.type != type) return false;
      if (selected != _tabs.first && item.category != selected) return false;
      if (section == InstitutionalSection.gallery &&
          query.isNotEmpty &&
          !'${item.title} ${item.description ?? ''} ${item.category}'
              .toLowerCase()
              .contains(query)) {
        return false;
      }
      return true;
    }).toList();
    final heading = switch (section) {
      InstitutionalSection.achievements => 'Logros destacados',
      InstitutionalSection.events => 'Actividades institucionales',
      InstitutionalSection.gallery => 'Álbumes publicados',
      _ => '',
    };
    return [
      Row(
        children: [
          Icon(section.icon, color: publicNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              heading,
              style: const TextStyle(
                color: publicNavy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (selected != _tabs.first)
            TextButton(
              onPressed: () => setState(() => _selection = _tabs.first),
              child: const Text('Ver todos'),
            ),
        ],
      ),
      if (section == InstitutionalSection.gallery) ...[
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Buscar álbumes',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (items.isEmpty)
        PublicationEmpty(
          icon: section.icon,
          title: _emptyTitle(section),
          message: section == InstitutionalSection.gallery && query.isNotEmpty
              ? 'No hay álbumes publicados que coincidan con tu búsqueda.'
              : selected == _tabs.first
              ? _emptyMessage(section)
              : 'No hay publicaciones en la categoría «$selected» por ahora.',
        )
      else
        for (final item in items) _publicationCard(item),
    ];
  }

  Widget _publicationCard(InstitutionalPublication item) => PublicCard(
    key: ValueKey(item.id),
    child: LayoutBuilder(
      builder: (context, bounds) {
        final image = item.imageUrl;
        final cover = image == null
            ? const SizedBox.shrink()
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  image,
                  width: bounds.maxWidth >= 620 ? 280 : double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 190,
                    child: Center(
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              );
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(item.category),
              backgroundColor: const Color(0xFFE5F1FC),
              labelStyle: const TextStyle(color: publicNavy),
            ),
            Text(
              item.title,
              style: const TextStyle(
                color: publicNavy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (item.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                item.description!,
                style: const TextStyle(color: publicNavy, height: 1.5),
              ),
            ],
          ],
        );
        if (image != null && bounds.maxWidth >= 620) {
          return Row(
            children: [
              cover,
              const SizedBox(width: 18),
              Expanded(child: details),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [if (image != null) cover, details],
        );
      },
    ),
  );

  List<Widget> _institution(String selected) => selected != _tabs.first
      ? [
          PublicationEmpty(
            icon: Icons.menu_book_outlined,
            title: selected,
            message:
                'El contenido oficial de ${selected.toLowerCase()} aún no está disponible.',
          ),
        ]
      : [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: const InstitutionalArtwork(
              'colegio.jpg',
              label: 'Fachada de la institución educativa',
            ),
          ),
          const SizedBox(height: 16),
          const PublicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I.E. Micaela Bastidas Puyucahua',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: publicNavy,
                  ),
                ),
                SizedBox(height: 8),
                Text('Tamburco · Abancay · Apurímac'),
                SizedBox(height: 14),
                Text(
                  'Educación de calidad, con identidad cultural y formación integral.',
                  style: TextStyle(color: publicWine, fontSize: 17),
                ),
                SizedBox(height: 12),
                Text(
                  'Somos una institución educativa que forma estudiantes con valores, identidad cultural y competencias para afrontar los retos del futuro, contribuyendo al desarrollo de nuestra comunidad.',
                  style: TextStyle(color: publicNavy, height: 1.6),
                ),
              ],
            ),
          ),
        ];

  String _subtitle(InstitutionalSection section) => switch (section) {
    InstitutionalSection.institution => 'Conoce nuestra institución, su historia y los valores que nos identifican.',
    InstitutionalSection.social =>
      'Noticias y canales de nuestra comunidad educativa.',
    InstitutionalSection.achievements =>
      'Talento, esfuerzo y compromiso que nos inspiran.',
    InstitutionalSection.gallery =>
      'Momentos que nos unen, logros que nos inspiran.',
    InstitutionalSection.events =>
      'Actividades que fortalecen nuestra comunidad educativa.',
    InstitutionalSection.location =>
      'Encuentra nuestra institución y conoce cómo llegar.',
  };
  String _emptyTitle(InstitutionalSection section) => switch (section) {
    InstitutionalSection.social => 'Sin publicaciones confirmadas',
    InstitutionalSection.achievements => 'Sin logros publicados',
    InstitutionalSection.gallery => 'Sin álbumes publicados',
    _ => 'Sin eventos publicados',
  };

  String _emptyMessage(InstitutionalSection section) => switch (section) {
    InstitutionalSection.achievements => 'Los logros de la comunidad educativa aparecerán aquí cuando sean publicados.',
    InstitutionalSection.gallery =>
      'Los álbumes de fotos y videos aparecerán aquí cuando sean publicados.',
    InstitutionalSection.events =>
      'Los próximos eventos aparecerán aquí cuando sean publicados.',
    _ => 'Aún no hay contenido publicado.',
  };
}
