import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';
import 'package:aplicativo_institucional/features/student/student_section.dart';
import 'package:aplicativo_institucional/features/student/widgets/development_section.dart';

import 'auth_test.dart' show responseFixture;

void main() {
  testWidgets('navega por el menú móvil y vuelve a los datos de sesión', (
    tester,
  ) async {
    var loggedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StudentPanel(
          session: Session.fromJson(responseFixture()),
          onLogout: () => loggedOut = true,
        ),
      ),
    );
    expect(find.text('Panel del estudiante'), findsOneWidget);
    expect(find.text('Nombre de prueba Apellido de prueba'), findsOneWidget);
    expect(find.text('Usuario: prueba'), findsOneWidget);
    expect(find.text('Roles: ESTUDIANTE'), findsOneWidget);
    expect(find.text('isolated-test-token'), findsNothing);
    for (final section in StudentSection.values.where(
      (s) => s != StudentSection.inicio,
    )) {
      await tester.tap(find.byTooltip('Abrir navegación'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('student-nav-${section.name}')));
      await tester.pumpAndSettle();
      expect(find.byType(DevelopmentSection), findsOneWidget);
      expect(find.text('Sección en desarrollo'), findsOneWidget);
      expect(loggedOut, isFalse);
      await tester.tap(find.text('Volver al inicio del panel'));
      await tester.pumpAndSettle();
      expect(find.text('Nombre de prueba Apellido de prueba'), findsOneWidget);
    }
    await tester.tap(find.text('Cerrar sesión'));
    expect(loggedOut, isTrue);
  });

  testWidgets('accesos de inicio y botón atrás conservan la sesión', (
    tester,
  ) async {
    var logoutCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StudentPanel(
          session: Session.fromJson(responseFixture()),
          onLogout: () => logoutCount++,
        ),
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('student-shortcut-tareas')),
    );
    await tester.tap(find.byKey(const ValueKey('student-shortcut-tareas')));
    await tester.pumpAndSettle();
    expect(find.text('Sección en desarrollo'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Panel del estudiante'), findsOneWidget);
    expect(logoutCount, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(logoutCount, 1);
  });

  for (final size in [
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets('panel adaptable sin desbordamientos $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: StudentPanel(
            session: Session.fromJson(responseFixture()),
            onLogout: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final section = StudentSection.comunicados;
      if (size.width < 900) {
        await tester.tap(find.byTooltip('Abrir navegación'));
        await tester.pumpAndSettle();
      } else {
        expect(find.byTooltip('Abrir navegación'), findsNothing);
      }
      if (size.width < 900) {
        final menuScroll = find
            .descendant(
              of: find.byType(Drawer),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.drag(menuScroll, const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('student-nav-${section.name}')),
          120,
          scrollable: find
              .descendant(
                of: find.byType(Drawer),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      } else {
        await tester.ensureVisible(
          find.byKey(ValueKey('student-nav-${section.name}')),
        );
      }
      await tester.tap(find.byKey(ValueKey('student-nav-${section.name}')));
      await tester.pumpAndSettle();
      expect(find.text('Sección en desarrollo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Volver al inicio del panel'));
      await tester.tap(find.text('Volver al inicio del panel'));
      await tester.pumpAndSettle();
      expect(find.text('Nombre de prueba Apellido de prueba'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
