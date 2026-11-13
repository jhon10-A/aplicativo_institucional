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

void main() {
  testWidgets('muestra los datos de sesión y los accesos a las secciones', (
    tester,
  ) async {
    var loggedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: GuardianPanel(
          session: _session(),
          onLogout: () => loggedOut = true,
        ),
      ),
    );
    expect(find.text('Panel del apoderado'), findsOneWidget);
    expect(find.text('Roles: APODERADO'), findsOneWidget);
    expect(find.text('isolated-test-token'), findsNothing);
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
    expect(find.text('Sección en desarrollo'), findsNothing);
    expect(loggedOut, isFalse);
    await tester.tap(find.text('Cerrar sesión'));
    expect(loggedOut, isTrue);
  });
}
