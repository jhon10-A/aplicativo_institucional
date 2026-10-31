import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/main.dart';

import 'auth_test.dart' show responseFixture;

Future<void> openStudent(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Estudiante'));
  await tester.tap(find.text('Estudiante'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byType(TextFormField).first);
}

Future<void> submitLogin(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Ingresar'));
  await tester.tap(find.text('Ingresar'));
}

void main() {
  testWidgets('valida el formulario y muestra/oculta la contraseña', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await openStudent(tester);
    await submitLogin(tester);
    await tester.pump();
    expect(
      find.text('Introduce un usuario de 1 a 60 caracteres.'),
      findsOneWidget,
    );
    final field = find.byType(TextFormField).last;
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: field, matching: find.byType(TextField)),
          )
          .obscureText,
      isTrue,
    );
    await tester.ensureVisible(find.byTooltip('Mostrar contraseña'));
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: field, matching: find.byType(TextField)),
          )
          .obscureText,
      isFalse,
    );
  });

  testWidgets(
    'bloquea envíos duplicados, muestra datos recibidos y cierra sesión',
    (tester) async {
      var requests = 0;
      final pending = Completer<http.Response>();
      final api = AuthApi(
        baseUrl: 'http://localhost:8080',
        clientFactory: () => MockClient((_) {
          requests++;
          return pending.future;
        }),
      );
      await tester.pumpWidget(MyApp(authApi: api));
      await openStudent(tester);
      await tester.enterText(find.byType(TextFormField).first, 'prueba');
      await tester.enterText(find.byType(TextFormField).last, 'solo-test');
      await submitLogin(tester);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(requests, 1);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        isEmpty,
      );
      pending.complete(http.Response(jsonEncode(responseFixture()), 200));
      await tester.pumpAndSettle();
      expect(find.text('Nombre de prueba Apellido de prueba'), findsOneWidget);
      expect(find.text('Roles: ESTUDIANTE'), findsOneWidget);
      expect(find.text('isolated-test-token'), findsNothing);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('¡Bienvenidos!'), findsOneWidget);
      await openStudent(tester);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'muestra 401 genérico y permite reintentar sin conservar contraseña',
    (tester) async {
      final api = AuthApi(
        baseUrl: 'http://localhost:8080',
        clientFactory: () => MockClient((_) async => http.Response('{}', 401)),
      );
      await tester.pumpWidget(MyApp(authApi: api));
      await openStudent(tester);
      await tester.enterText(find.byType(TextFormField).first, 'prueba');
      await tester.enterText(find.byType(TextFormField).last, 'solo-test');
      await submitLogin(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Credenciales incorrectas o usuario inactivo.'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        isEmpty,
      );
    },
  );
}
