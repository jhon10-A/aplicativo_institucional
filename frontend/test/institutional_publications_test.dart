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
      expect(find.byType(MarkerLayer), findsOneWidget);
      expect(find.byKey(const Key('verified-school-marker')), findsOneWidget);
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
        isNotNull,
      );

      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Ruta en Auto'),
            )
            .onPressed,
        isNotNull,
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
        isNotNull,
      );
      expect(find.text('Abre en Google Maps'), findsOneWidget);
      expect(find.text('Desde tu ubicación'), findsOneWidget);
      expect(find.text('Por WhatsApp'), findsOneWidget);
      expect(find.textContaining('Número oficial pendiente'), findsNothing);
      expect(
        find.byTooltip(
          'Disponible cuando se confirme el número oficial de WhatsApp.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('el mapa OSM usa la ubicación confirmada y muestra marcador', (
    tester,
  ) async {
    await tester.pumpWidget(_page(InstitutionalSection.location));
    await tester.pump();

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final layer = tester.widget<TileLayer>(find.byType(TileLayer));

    expect(map.options.initialCenter, const LatLng(-13.6219539, -72.8744841));
    expect(map.options.initialZoom, 16);
    expect(layer.urlTemplate, 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(
      find.byKey(const Key('open-street-map-attribution')),
      findsOneWidget,
    );
    expect(find.byTooltip('Ver la licencia de OpenStreetMap'), findsOneWidget);
    final markers = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markers.markers, hasLength(1));
    expect(
      markers.markers.single.point,
      const LatLng(-13.6219539, -72.8744841),
    );
    expect(find.byKey(const Key('verified-school-marker')), findsOneWidget);
  });

  testWidgets(
    'Google Maps abre el enlace confirmado y rutas sin fijar origen',
    (tester) async {
      final launchedUrls = <String>[];
      final launchArguments = <Map<Object?, Object?>>[];
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'launch') {
              launchedUrls.add(call.arguments['url'] as String);
              launchArguments.add(
                Map<Object?, Object?>.from(call.arguments as Map),
              );
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
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('view-in-google-maps')));
      await tester.tap(find.byKey(const Key('view-in-google-maps')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('location-tab-Cómo Llegar')),
      );
      await tester.tap(find.byKey(const ValueKey('location-tab-Cómo Llegar')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('location-action-Cómo Llegar')),
      );
      await tester.tap(
        find.byKey(const ValueKey('location-action-Cómo Llegar')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('location-action-Ruta en Auto')),
      );
      await tester.tap(
        find.byKey(const ValueKey('location-action-Ruta en Auto')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('location-tab-Contacto')),
      );
      await tester.tap(find.byKey(const ValueKey('location-tab-Contacto')));
      await tester.pumpAndSettle();

      expect(launchedUrls, hasLength(3));
      expect(launchedUrls[0], 'https://maps.app.goo.gl/mdfbYVYQVeHgnG5w6');
      expect(launchedUrls[1], contains('google.com/maps/dir/'));
      expect(
        launchedUrls[1],
        contains('destination=-13.6219539%2C-72.8744841'),
      );
      expect(launchedUrls[1], contains('travelmode=walking'));
      expect(launchedUrls[1], isNot(contains('origin=')));
      expect(launchedUrls[2], contains('google.com/maps/dir/'));
      expect(
        launchedUrls[2],
        contains('destination=-13.6219539%2C-72.8744841'),
      );
      expect(launchedUrls[2], contains('travelmode=driving'));
      expect(launchedUrls[2], isNot(contains('origin=')));
      expect(launchArguments, hasLength(3));
      expect(
        launchArguments.every((arguments) => arguments['useWebView'] == false),
        isTrue,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('location-action-Contactar')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('las cuatro pestañas de ubicación muestran su contenido', (
    tester,
  ) async {
    await tester.pumpWidget(_page(InstitutionalSection.location));
    await tester.pumpAndSettle();

    expect(find.text('Dirección'), findsOneWidget);
    expect(find.text('Teléfono'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('location-action-Contactar')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('location-tab-Cómo Llegar')),
    );
    await tester.tap(find.byKey(const ValueKey('location-tab-Cómo Llegar')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('location-tab-description-Cómo Llegar')),
      findsOneWidget,
    );
    expect(find.text('Dirección'), findsOneWidget);
    expect(find.text('Teléfono'), findsNothing);
    expect(
      find.byKey(const ValueKey('location-action-Cómo Llegar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('location-action-Ruta en Auto')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('location-action-Contactar')),
      findsNothing,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('location-tab-Referencias')),
    );
    await tester.tap(find.byKey(const ValueKey('location-tab-Referencias')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('location-tab-description-Referencias')),
      findsOneWidget,
    );
    expect(find.text('Dirección'), findsOneWidget);
    expect(find.text('Teléfono'), findsOneWidget);
    expect(find.text('Correo institucional'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('location-action-Cómo Llegar')),
      findsNothing,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('location-tab-Contacto')),
    );
    await tester.tap(find.byKey(const ValueKey('location-tab-Contacto')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('location-tab-description-Contacto')),
      findsOneWidget,
    );
    expect(find.text('Dirección'), findsNothing);
    expect(find.text('Teléfono'), findsOneWidget);
    expect(find.text('Correo institucional'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('location-action-Contactar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('location-action-Cómo Llegar')),
      findsNothing,
    );
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  for (final size in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
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
      final actionSize = tester.getSize(
        find.byKey(const ValueKey('location-action-Cómo Llegar')),
      );
      expect(actionSize.width, greaterThan(size.width == 390 ? 300 : 150));
      await tester.ensureVisible(
        find.byKey(const Key('location-scroll-end-spacer')),
      );
      final spacerBottom = tester
          .getRect(find.byKey(const Key('location-scroll-end-spacer')))
          .bottom;
      final navigationTop = tester
          .getRect(find.byKey(const Key('institutional-bottom-navigation')))
          .top;
      expect(spacerBottom, lessThanOrEqualTo(navigationTop));
      expect(tester.takeException(), isNull);
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
