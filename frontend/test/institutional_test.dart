import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/main.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/widgets/login_form.dart';

import 'auth_test.dart' show responseFixture;

Future<void> openAccess(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> credentials(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(TextFormField).first);
  await tester.enterText(find.byType(TextFormField).first, 'prueba');
  await tester.ensureVisible(find.byType(TextFormField).last);
  await tester.enterText(find.byType(TextFormField).last, 'solo-test');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Ingresar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ingresar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cada acceso usa roles reales; un rechazo no conserva sesión', (
    tester,
  ) async {
    var responseRole = 'ESTUDIANTE';
    final api = AuthApi(
      baseUrl: 'http://localhost:8080',
      clientFactory: () => MockClient((_) async {
        final fixture = responseFixture();
        (fixture['usuario'] as Map<String, Object>)['roles'] = [responseRole];
        return http.Response(jsonEncode(fixture), 200);
      }),
    );
    await tester.pumpWidget(MyApp(authApi: api));
    for (final access in {
      'Estudiante': 'ESTUDIANTE',
      'Docente': 'DOCENTE',
      'Padre de familia': 'APODERADO',
    }.entries) {
      await openAccess(tester, access.key);
      expect(find.byType(LoginForm), findsOneWidget);
      responseRole = 'ADMINISTRADOR';
      await credentials(tester);
      expect(
        find.textContaining('Esta cuenta no corresponde al acceso'),
        findsOneWidget,
      );
      expect(find.text('Cerrar sesión'), findsNothing);
      expect(find.text('Nombre de prueba Apellido de prueba'), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        isEmpty,
      );
      responseRole = access.value;
      await credentials(tester);
      expect(find.text('Nombre de prueba Apellido de prueba'), findsOneWidget);
      expect(find.text('Roles: ${access.value}'), findsOneWidget);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('¡Bienvenidos!'), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tecnología muestra solo el estado vacío sin iniciar sesión', (
    tester,
  ) async {
    var requests = 0;
    final api = AuthApi(
      baseUrl: 'http://localhost:8080',
      clientFactory: () => MockClient((_) async {
        requests++;
        return http.Response('{}', 500);
      }),
    );
    await tester.pumpWidget(MyApp(authApi: api));
    await openAccess(tester, 'Tecnología');
    expect(find.text('Aún no hay recursos publicados'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(requests, 0);
    await tester.tap(find.text('Volver al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('¡Bienvenidos!'), findsOneWidget);
  });

  testWidgets(
    'volver al inicio durante una petición descarta la respuesta tardía',
    (tester) async {
      final pending = Completer<http.Response>();
      final api = AuthApi(
        baseUrl: 'http://localhost:8080',
        clientFactory: () => MockClient((_) => pending.future),
      );
      await tester.pumpWidget(MyApp(authApi: api));
      await openAccess(tester, 'Estudiante');
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, 'prueba');
      await tester.enterText(find.byType(TextFormField).last, 'solo-test');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ingresar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ingresar'));
      await tester.pump();
      await tester.ensureVisible(find.text('Regresar al menú principal'));
      await tester.tap(find.text('Regresar al menú principal'));
      await tester.pumpAndSettle();
      pending.complete(http.Response(jsonEncode(responseFixture()), 200));
      await tester.pumpAndSettle();
      expect(find.text('¡Bienvenidos!'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsNothing);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
  ]) {
    testWidgets('portada y accesos sin overflow a $size y texto ampliado', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: const MyApp(),
        ),
      );
      expect(tester.takeException(), isNull);
      for (final label in [
        'Estudiante',
        'Docente',
        'Padre de familia',
        'Tecnología',
      ]) {
        await openAccess(tester, label);
        expect(tester.takeException(), isNull);
        if (label != 'Tecnología') {
          await tester.ensureVisible(find.byType(TextFormField).last);
          tester.view.viewInsets = const FakeViewPadding(bottom: 250);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('Volver al inicio'));
        await tester.tap(find.text('Volver al inicio'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
