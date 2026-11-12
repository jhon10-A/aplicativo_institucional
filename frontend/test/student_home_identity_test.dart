import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';

import 'auth_test.dart' show responseFixture;
import 'student_profile_test.dart' show profileFixture, enrollmentFixture;

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Widget panel(
  Future<http.Response> Function(http.Request) handler, {
  VoidCallback? expired,
}) => MaterialApp(
  home: StudentPanel(
    session: Session.fromJson(responseFixture()),
    onLogout: expired ?? () {},
    studentApiFactory: () => StudentApi(
      baseUrl: 'http://localhost:8080',
      token: 'isolated-test-token',
      client: MockClient(handler),
    ),
  ),
);

void main() {
  testWidgets(
    'cabecera muestra documento propio y grado sin inventar turno ni fila de periodo',
    (tester) async {
      await tester.pumpWidget(
        panel((request) async {
          expect(
            request.headers['Authorization'],
            'Bearer isolated-test-token',
          );
          if (request.url.path.endsWith('/perfil')) {
            return json({
              ...profileFixture(),
              'documentoIdentidad': '87654321',
            });
          }
          if (request.url.path.endsWith('/matriculas')) {
            return json([enrollmentFixture('2026')]);
          }
          return json([]);
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('DNI: 87654321'), findsOneWidget);
      expect(find.text('Turno: No disponible'), findsOneWidget);
      expect(find.text('Estudiante · Primero · Sección A'), findsOneWidget);
      expect(find.text('Usuario: prueba'), findsNothing);
      expect(find.text('Roles: ESTUDIANTE'), findsNothing);
      expect(find.text('Panel del estudiante'), findsNothing);
      expect(find.text('Periodo 2026'), findsNothing);
      expect(find.byTooltip('Actualizar resúmenes'), findsNothing);
      expect(find.textContaining('Mañana'), findsNothing);
    },
  );

  testWidgets(
    'DNI distingue carga, error y documento no registrado al reintentar',
    (tester) async {
      final pending = Completer<http.Response>();
      var calls = 0;
      await tester.pumpWidget(
        panel((request) async {
          if (request.url.path.endsWith('/perfil')) {
            return ++calls == 1 ? pending.future : json(profileFixture());
          }
          return json([]);
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('DNI: Cargando…'), findsOneWidget);
      pending.complete(json({'private': 'not shown'}, 503));
      await tester.pumpAndSettle();
      expect(find.text('DNI: No disponible'), findsOneWidget);
      expect(find.text('DNI: No registrado'), findsNothing);
      expect(find.textContaining('not shown'), findsNothing);
      await tester.tap(find.byTooltip('Reintentar perfil'));
      await tester.pumpAndSettle();
      expect(find.text('DNI: No registrado'), findsOneWidget);
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('perfil y resumen con sesión vencida notifican una sola vez', (
    tester,
  ) async {
    var expired = 0;
    await tester.pumpWidget(
      panel((_) async => json({}, 401), expired: () => expired++),
    );
    await tester.pumpAndSettle();
    expect(expired, 1);
    expect(find.textContaining('87654321'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
