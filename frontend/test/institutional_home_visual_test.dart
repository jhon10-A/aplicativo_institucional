import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplicativo_institucional/screens/home_page.dart';
import 'package:aplicativo_institucional/access_profile.dart';
import 'package:aplicativo_institucional/features/institutional/institutional_section.dart';

void main() {
  setUpAll(() async {
    for (final entry in {
      'Roboto': const String.fromEnvironment('VISUAL_FONT_PATH'),
      'MaterialIcons': const String.fromEnvironment('VISUAL_ICON_FONT_PATH'),
    }.entries) {
      if (entry.value.isNotEmpty) {
        final loader = FontLoader(entry.key);
        loader.addFont(
          File(entry.value).readAsBytes().then(ByteData.sublistView),
        );
        await loader.load();
      }
    }
  });
  for (final size in [const Size(390, 844), const Size(1440, 1200)]) {
    testWidgets('Inicio ilustrado, accesos y proporciones en $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      AccessProfile? role;
      InstitutionalSection? section;
      var technology = false;
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: boundaryKey,
            child: HomePage(
              onAccess: (value) => role = value,
              onTechnology: () => technology = true,
              onInstitutional: (value) => section = value,
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(HomePage));
      await tester.runAsync(() async {
        for (final name in [
          'inicio-cabecera.png',
          'acceso-estudiante.png',
          'acceso-docente.png',
          'acceso-familia.png',
          'acceso-tecnologia.png',
          'inicio-pie.png',
        ]) {
          await precacheImage(
            AssetImage('assets/institutional/$name'),
            context,
          );
        }
      });
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNWidgets(6));
      expect(find.text('¡Bienvenidos!'), findsNothing);
      for (final profile in AccessProfile.values) {
        final finder = find.byTooltip(profile.label);
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        expect(role, profile);
      }
      await tester.ensureVisible(find.byTooltip('Tecnología'));
      await tester.tap(find.byTooltip('Tecnología'));
      expect(technology, isTrue);
      for (final value in InstitutionalSection.values) {
        await tester.ensureVisible(find.text(value.title));
        await tester.tap(find.text(value.title));
        expect(section, value);
      }
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(Column).first).width,
        lessThanOrEqualTo(680),
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 3000),
      );
      await tester.pumpAndSettle();
      if (const bool.fromEnvironment('CAPTURE_HOME')) {
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '../tmp/pdfs/inicio-flutter-${size.width.toInt()}.png',
          );
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
