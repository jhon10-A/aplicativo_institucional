import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/guardian/guardian_section.dart';
import 'package:aplicativo_institucional/features/guardian/screens/guardian_panel.dart';

Session _session() => Session(
  'isolated-test-token',
  DateTime.now().add(const Duration(hours: 1)),
  1,
  'apoderado.prueba',
  'Nombre de prueba',
  'Apellido de prueba',
  const ['APODERADO'],
);

Widget _panel(VoidCallback onLogout) => MaterialApp(
  home: GuardianPanel(session: _session(), onLogout: onLogout),
);

void main() {
  testWidgets('muestra la identidad del colegio y la bienvenida', (
    tester,
  ) async {
    await tester.pumpWidget(_panel(() {}));
    expect(find.text('I.E. Micaela Bastidas Puyucahua'), findsOneWidget);
    expect(find.text('Tamburco · Abancay · Apurímac'), findsOneWidget);
    expect(find.text('¡Bienvenido(a)'), findsOneWidget);
    expect(find.text('Nombre de prueba Apellido de prueba'), findsOneWidget);
    expect(find.text('Roles: APODERADO'), findsOneWidget);
    expect(
      find.text('Tu compromiso fortalece la educación de tus hijos.'),
      findsOneWidget,
    );
    expect(find.text('isolated-test-token'), findsNothing);
  });

  testWidgets('muestra los accesos a las secciones y permite cerrar sesión', (
    tester,
  ) async {
    var loggedOut = false;
    await tester.pumpWidget(_panel(() => loggedOut = true));
    // Cada sección con pantalla propia se prueba en su archivo de test.
    for (final section in GuardianSection.values.where(
      (s) => s != GuardianSection.inicio,
    )) {
      expect(
        find.byKey(ValueKey('guardian-shortcut-${section.name}')),
        findsOneWidget,
      );
      expect(find.text(section.description), findsOneWidget);
    }
    expect(loggedOut, isFalse);
    await tester.tap(find.text('Cerrar sesión'));
    expect(loggedOut, isTrue);
  });
}
