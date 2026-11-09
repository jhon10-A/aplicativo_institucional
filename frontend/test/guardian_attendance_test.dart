import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/features/guardian/guardian_api.dart';
import 'package:aplicativo_institucional/features/guardian/screens/guardian_attendance_screen.dart';

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

Map<String, Object?> _child() => {
  'id': 7,
  'nombres': 'Lucía',
  'apellidos': 'Quispe Mamani',
  'codigoEstudiante': 'E-0007',
  'parentesco': 'Madre',
  'contactoPrincipal': true,
  'matriculaId': 3,
  'estado': 'ACTIVA',
  'periodo': '2026',
  'nivel': 'Primaria',
  'grado': '3°',
  'seccion': 'A',
};

Map<String, Object?> _record(
  int id,
  String fecha,
  String estado, [
  String? observacion,
]) => {
  'id': id,
  'fecha': fecha,
  'periodo': '2026',
  'curso': 'Matemática',
  'estado': estado,
  'observacion': observacion,
};

Widget _screen(GuardianApi api) =>
    MaterialApp(home: Scaffold(body: GuardianAttendanceScreen(api: api)));

String _count(WidgetTester tester, String state) => tester
    .widget<Text>(find.byKey(ValueKey('attendance-count-$state')))
    .data!;

void main() {
  testWidgets('resume la asistencia y lista los registros', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/apoderado/hijos') return _json([_child()]);
      expect(request.url.path, '/api/apoderado/hijos/7/asistencia');
      expect(request.headers['Authorization'], 'Bearer isolated-test-token');
      return _json([
        _record(1, '2026-05-12', 'PRESENTE'),
        _record(2, '2026-05-11', 'PRESENTE'),
        _record(3, '2026-05-10', 'FALTA'),
        _record(4, '2026-05-09', 'TARDANZA', 'Llegó 10 minutos tarde'),
      ]);
    });
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(_count(tester, 'PRESENTE'), '2');
    expect(_count(tester, 'FALTA'), '1');
    expect(_count(tester, 'TARDANZA'), '1');
    expect(_count(tester, 'JUSTIFICADA'), '0');
    expect(find.text('Total de registros: 4'), findsOneWidget);
    expect(find.text('2026-05-10 · Matemática'), findsOneWidget);
    expect(find.text('Llegó 10 minutos tarde'), findsOneWidget);
  });

  testWidgets('avisa cuando aún no hay asistencias', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/apoderado/hijos') return _json([_child()]);
      return _json([]);
    });
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(
      find.text('Aún no hay asistencias registradas para Lucía.'),
      findsOneWidget,
    );
  });

  testWidgets('un 404 muestra el mensaje y Reintentar vuelve a consultar', (
    tester,
  ) async {
    var calls = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/api/apoderado/hijos') return _json([_child()]);
      calls++;
      return calls == 1
          ? _json({'codigo': 'NO_DISPONIBLE'}, 404)
          : _json([_record(1, '2026-05-12', 'PRESENTE')]);
    });
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(find.text('La información no está disponible.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(_count(tester, 'PRESENTE'), '1');
    expect(calls, 2);
  });
}
