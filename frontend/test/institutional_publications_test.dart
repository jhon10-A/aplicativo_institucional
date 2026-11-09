import 'package:aplicativo_institucional/features/institutional/institutional_page.dart';
import 'package:aplicativo_institucional/features/institutional/institutional_publication.dart';
import 'package:aplicativo_institucional/features/institutional/institutional_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  for (final section in [
    InstitutionalSection.achievements,
    InstitutionalSection.events,
    InstitutionalSection.gallery,
  ]) {
    for (final size in [
      const Size(320, 640),
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('${section.title} conserva su estado vacío en $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_page(section));
        await tester.pumpAndSettle();

        expect(find.byType(ChoiceChip), findsWidgets);
        expect(find.text('Registro de prueba'), findsNothing);
        expect(tester.takeException(), isNull);
        if (section == InstitutionalSection.events) {
          expect(find.byTooltip('Filtrar eventos'), findsOneWidget);
        }
        if (section == InstitutionalSection.gallery) {
          expect(find.byType(TextField), findsOneWidget);
        }
      });
    }
  }

  testWidgets('filtros de eventos cambian de categoría y limpian selección', (
    tester,
  ) async {
    await tester.pumpWidget(_page(InstitutionalSection.events));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Culturales').last);
    await tester.pumpAndSettle();

    expect(
      find.text('No hay publicaciones en la categoría «Culturales» por ahora.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ver todos'));
    await tester.pumpAndSettle();
    expect(
      find.text('Los próximos eventos aparecerán aquí cuando sean publicados.'),
      findsOneWidget,
    );
  });

  testWidgets('la galería conserva búsqueda y categorías sin crear álbumes', (
    tester,
  ) async {
    await tester.pumpWidget(_page(InstitutionalSection.gallery));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Proyectos'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'sin coincidencias');
    await tester.pumpAndSettle();

    expect(
      find.text('No hay álbumes publicados que coincidan con tu búsqueda.'),
      findsOneWidget,
    );
    expect(find.text('Registro de prueba'), findsNothing);
  });

  testWidgets(
    'los elementos institucionales se filtran desde una lista tipada',
    (tester) async {
      const publication = InstitutionalPublication(
        id: 'test-event',
        type: InstitutionalPublicationType.event,
        category: 'Académicos',
        title: 'Registro de prueba',
        description:
            'Contenido disponible para presentar desde una fuente futura.',
      );
      await tester.pumpWidget(
        _page(InstitutionalSection.events, publications: const [publication]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Registro de prueba'), findsOneWidget);
      await tester.tap(find.text('Culturales').last);
      await tester.pumpAndSettle();
      expect(find.text('Registro de prueba'), findsNothing);
    },
  );

  testWidgets(
    'institución usa el texto disponible y ubicación no inventa datos',
    (tester) async {
      await tester.pumpWidget(_page(InstitutionalSection.institution));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'contribuyendo al desarrollo de nuestra comunidad.',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(_page(InstitutionalSection.location));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('Nuestra Ubicación'), findsOneWidget);
      expect(find.text('Cómo Llegar'), findsWidgets);
      expect(find.text('Referencias'), findsOneWidget);
      expect(find.text('Contacto'), findsOneWidget);
      expect(find.byKey(const Key('location-map-placeholder')), findsNothing);
      expect(
        find.text('Ilustración · no es un mapa interactivo'),
        findsNothing,
      );
      expect(find.byKey(const Key('open-street-map')), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(MarkerLayer), findsNothing);
      expect(find.text('Tamburco · Abancay · Apurímac'), findsWidgets);
      expect(find.textContaining('Av. Micaela Bastidas S/N'), findsOneWidget);
      expect(find.text('083-482123'), findsOneWidget);
      expect(find.text('iemicaelabastidas@edu.pe'), findsOneWidget);
      expect(find.text('Pendiente de confirmación'), findsNothing);
      expect(
        find.textContaining('Datos reproducidos del PDF de referencia'),
        findsNothing,
      );
      expect(find.text('Nuestra Institución'), findsNothing);
      expect(
        find.byTooltip('Referencia pendiente de confirmación'),
        findsNothing,
      );
      expect(find.text('Ubicación general'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Cómo Llegar'),
            )
            .onPressed,
        isNull,
      );

      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Ruta en Auto'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Contactar'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('view-in-google-maps')))
            .onPressed,
        isNull,
      );
      expect(find.text('Abre en Google Maps'), findsOneWidget);
      expect(find.text('Desde tu ubicación'), findsOneWidget);
      expect(find.text('Por WhatsApp'), findsOneWidget);
      expect(find.textContaining('Requiere coordenadas'), findsNothing);
      expect(find.textContaining('Número oficial pendiente'), findsNothing);
      expect(
        find.byTooltip(
          'Disponible cuando se confirmen las coordenadas exactas del colegio.',
        ),
        findsNWidgets(2),
      );
      expect(
        find.byTooltip(
          'Disponible cuando se confirme el número oficial de WhatsApp.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('el mapa usa OSM con el centro general y sin marcador', (
    tester,
  ) async {
    await tester.pumpWidget(_page(InstitutionalSection.location));
    await tester.pump();

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final layer = tester.widget<TileLayer>(find.byType(TileLayer));

    expect(map.options.initialCenter, const LatLng(-13.5874347, -72.8662411));
    expect(map.options.initialZoom, 13);
    expect(layer.urlTemplate, 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(
      find.byKey(const Key('open-street-map-attribution')),
      findsOneWidget,
    );
    expect(find.byTooltip('Ver la licencia de OpenStreetMap'), findsOneWidget);
    expect(find.byType(MarkerLayer), findsNothing);
  });

  testWidgets(
    'los enlaces externos usan coordenadas y WhatsApp proporcionados',
    (tester) async {
      final launchedUrls = <String>[];
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'launch') {
              launchedUrls.add(call.arguments['url'] as String);
              return true;
            }
            return false;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InstitutionalPage(
            section: InstitutionalSection.location,
            onBack: () {},
            onSection: (_) {},
            verifiedLocation: const LatLng(-13.5, -72.8),
            verifiedWhatsAppNumber: '+51 987 654 321',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('view-in-google-maps')));
      await tester.tap(find.byKey(const Key('view-in-google-maps')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('location-action-Cómo Llegar')),
      );
      await tester.tap(
        find.byKey(const ValueKey('location-action-Cómo Llegar')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('location-action-Ruta en Auto')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('location-action-Contactar')));
      await tester.pumpAndSettle();

      expect(launchedUrls, hasLength(4));
      expect(launchedUrls[0], contains('google.com/maps/search/'));
      expect(launchedUrls[0], contains('query=-13.5%2C-72.8'));
      expect(launchedUrls[1], contains('google.com/maps/dir/'));
      expect(launchedUrls[1], contains('destination=-13.5%2C-72.8'));
      expect(launchedUrls[2], contains('travelmode=driving'));
      expect(launchedUrls[3], 'https://wa.me/51987654321');
    },
  );

  testWidgets('las pestañas de ubicación forman una cuadrícula en celular', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_page(InstitutionalSection.location));
    await tester.pumpAndSettle();

    final first = tester.getTopLeft(
      find.byKey(const ValueKey('location-tab-Nuestra Ubicación')),
    );
    final second = tester.getTopLeft(
      find.byKey(const ValueKey('location-tab-Cómo Llegar')),
    );
    final third = tester.getTopLeft(
      find.byKey(const ValueKey('location-tab-Referencias')),
    );
    final fourth = tester.getTopLeft(
      find.byKey(const ValueKey('location-tab-Contacto')),
    );

    expect(second.dx, greaterThan(first.dx));
    expect(second.dy, first.dy);
    expect(third.dy, greaterThan(first.dy));
    expect(fourth.dx, greaterThan(third.dx));
    await tester.tap(find.byKey(const ValueKey('location-tab-Cómo Llegar')));
    await tester.pumpAndSettle();
    expect(find.text('Dirección'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(390, 844), const Size(1440, 900)]) {
    testWidgets('ubicación se adapta a viewport $size sin overflow', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_page(InstitutionalSection.location));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byKey(const Key('view-in-google-maps')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('location-action-Cómo Llegar')),
        findsOneWidget,
      );
    });
  }
}

Widget _page(
  InstitutionalSection section, {
  List<InstitutionalPublication> publications = const [],
}) => MaterialApp(
  home: InstitutionalPage(
    section: section,
    onBack: () {},
    onSection: (_) {},
    publications: publications,
  ),
);
