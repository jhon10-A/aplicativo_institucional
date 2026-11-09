import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';
import 'package:aplicativo_institucional/features/student/student_section.dart';
import 'package:aplicativo_institucional/features/student/widgets/development_section.dart';
import 'package:aplicativo_institucional/features/student/screens/student_notices_screen.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/widgets/student_overview.dart';
import 'package:aplicativo_institucional/features/student/widgets/student_home.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'auth_test.dart' show responseFixture;
import 'student_profile_test.dart' show profileFixture;

void main() {
  StudentApi client() => StudentApi(
    baseUrl: 'http://localhost:8080',
    token: 'isolated-test-token',
    client: MockClient(
      (request) async => http.Response(
        jsonEncode(
          request.url.path.endsWith('/perfil') ? profileFixture() : [],
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  );
  for (final size in [const Size(1840, 450), const Size(1840, 900)]) {
    testWidgets('resúmenes acotados e imagen completa en escritorio $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: StudentPanel(
            session: Session.fromJson(responseFixture()),
            onLogout: () {},
            studentApiFactory: client,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('student-shortcut-perfil')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('student-shortcut-comunicados')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('student-bottom-perfil')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('student-bottom-comunicados')),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(StudentOverview)).width,
        lessThanOrEqualTo(720),
      );
      final imageFinder = find.byKey(
        const ValueKey('student-motivation-image'),
      );
      expect(tester.widget<Image>(imageFinder).fit, BoxFit.contain);
      expect(tester.getSize(imageFinder).height, lessThanOrEqualTo(220));
      await tester.ensureVisible(imageFinder);
      await tester.pumpAndSettle();
      final imageRect = tester.getRect(imageFinder);
      final footerTop = tester
          .getTopLeft(find.byKey(const ValueKey('student-bottom-inicio')))
          .dy;
      expect(imageRect.bottom, lessThanOrEqualTo(footerTop + 1));
      expect(
        tester.getRect(find.byType(StudentHome)).bottom,
        closeTo(footerTop, 1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('navega por el menú móvil y vuelve a los datos de sesión', (
    tester,
  ) async {
    var loggedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StudentPanel(
          session: Session.fromJson(responseFixture()),
          onLogout: () => loggedOut = true,
          studentApiFactory: client,
        ),
      ),
    );
    expect(find.text('Hola,'), findsOneWidget);
    expect(find.text('Nombre de prueba Apellido de prueba'), findsOneWidget);
    expect(find.text('Usuario: prueba'), findsNothing);
    expect(find.textContaining('DNI:'), findsOneWidget);
    expect(find.text('Roles: ESTUDIANTE'), findsNothing);
    expect(find.text('Turno: No disponible'), findsOneWidget);
    expect(find.text('isolated-test-token'), findsNothing);
    for (final section in StudentSection.values.where(
      (s) => s != StudentSection.inicio && s != StudentSection.progreso,
    )) {
      await tester.tap(find.byTooltip('Abrir navegación'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(ValueKey('student-nav-${section.name}')),
      );
      await tester.tap(find.byKey(ValueKey('student-nav-${section.name}')));
      await tester.pumpAndSettle();
      expect(find.byType(DevelopmentSection), findsNothing);
      expect(loggedOut, isFalse);
      await tester.ensureVisible(find.text('Volver al inicio del panel'));
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
          studentApiFactory: client,
        ),
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('student-bottom-comunicados')),
    );
    await tester.tap(find.byKey(const ValueKey('student-bottom-comunicados')));
    await tester.pumpAndSettle();
    expect(find.byType(StudentNoticesScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Hola,'), findsOneWidget);
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
            studentApiFactory: client,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final section = StudentSection.comunicados;
      expect(find.byType(Drawer), findsNothing);
      expect(
        find.byKey(const ValueKey('student-bottom-inicio')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Abrir navegación'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(ValueKey('student-nav-${section.name}')),
      );
      await tester.tap(find.byKey(ValueKey('student-nav-${section.name}')));
      await tester.pumpAndSettle();
      expect(find.byType(StudentNoticesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Volver al inicio del panel'));
      await tester.tap(find.text('Volver al inicio del panel'));
      await tester.pumpAndSettle();
      expect(find.text('Nombre de prueba Apellido de prueba'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
