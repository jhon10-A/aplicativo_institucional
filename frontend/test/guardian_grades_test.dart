import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/features/guardian/guardian_api.dart';
import 'package:aplicativo_institucional/features/guardian/screens/guardian_grades_screen.dart';

GuardianApi _api(MockClient client) => GuardianApi(
  baseUrl: 'http://localhost:8080',
  token: 'isolated-test-token',
  client: client,
);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _child(int id, String nombres) => {
  'id': id,
  'nombres': nombres,
  'apellidos': 'Quispe Mamani',
  'codigoEstudiante': 'E-000$id',
  'parentesco': 'Madre',
  'contactoPrincipal': true,
  'matriculaId': id,
  'estado': 'ACTIVA',
  'periodo': '2026',
  'nivel': 'Primaria',
  'grado': '3°',
  'seccion': 'A',
};

Map<String, Object?> _grade(int id, String curso, double nota) => {
  'id': id,
  'periodo': '2026',
  'curso': curso,
  'docente': 'Carlos Ramírez Soto',
  'etapa': 'BIMESTRE 1',
  'concepto': 'Práctica $id',
  'nota': nota,
  'observacion': null,
  'fecha': '2026-05-10',
};

Widget _screen(GuardianApi api) =>
    MaterialApp(home: Scaffold(body: GuardianGradesScreen(api: api)));

void main() {
  testWidgets('agrupa las notas por curso y calcula el promedio', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/apoderado/hijos') {
        return _json([_child(7, 'Lucía')]);
      }
      expect(request.url.path, '/api/apoderado/hijos/7/calificaciones');
      expect(request.headers['Authorization'], 'Bearer isolated-test-token');
      return _json([
        _grade(1, 'Matemática', 16),
        _grade(2, 'Matemática', 14),
        _grade(3, 'Comunicación', 18.5),
      ]);
    });
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(find.text('Calificaciones'), findsOneWidget);
    expect(find.text('Matemática · Periodo 2026'), findsOneWidget);
    expect(find.text('Promedio: 15.00'), findsOneWidget);
    expect(find.text('Comunicación · Periodo 2026'), findsOneWidget);
    expect(find.text('Promedio: 18.50'), findsOneWidget);
    expect(find.text('16.00'), findsOneWidget);
    expect(find.text('BIMESTRE 1 · Práctica 1'), findsOneWidget);
  });

  testWidgets('con dos hijos permite cambiar de hijo', (tester) async {
    final client = MockClient((request) async {
      switch (request.url.path) {
        case '/api/apoderado/hijos':
          return _json([_child(7, 'Lucía'), _child(8, 'Mateo')]);
        case '/api/apoderado/hijos/7/calificaciones':
          return _json([_grade(1, 'Matemática', 16)]);
        case '/api/apoderado/hijos/8/calificaciones':
          return _json([_grade(2, 'Ciencias', 12)]);
      }
      return _json({}, 404);
    });
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(find.text('Matemática · Periodo 2026'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guardian-pick-8')));
    await tester.pumpAndSettle();
    expect(find.text('Ciencias · Periodo 2026'), findsOneWidget);
    expect(find.text('Matemática · Periodo 2026'), findsNothing);
  });

  testWidgets('avisa cuando aún no hay calificaciones', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/apoderado/hijos') {
        return _json([_child(7, 'Lucía')]);
      }
      return _json([]);
    });
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(
      find.text('Aún no hay calificaciones registradas para Lucía.'),
      findsOneWidget,
    );
  });

  testWidgets('un 404 muestra el mensaje y Reintentar vuelve a consultar', (
    tester,
  ) async {
    var gradeCalls = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/api/apoderado/hijos') {
        return _json([_child(7, 'Lucía')]);
      }
      gradeCalls++;
      return gradeCalls == 1
          ? _json({'codigo': 'NO_DISPONIBLE'}, 404)
          : _json([_grade(1, 'Matemática', 16)]);
    });
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(find.text('La información no está disponible.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Matemática · Periodo 2026'), findsOneWidget);
    expect(gradeCalls, 2);
  });
}
