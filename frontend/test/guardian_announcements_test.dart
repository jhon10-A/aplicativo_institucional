import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/features/guardian/guardian_api.dart';
import 'package:aplicativo_institucional/features/guardian/screens/guardian_announcements_screen.dart';

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

Map<String, Object?> _item(int id, String titulo) => {
  'id': id,
  'titulo': titulo,
  'contenido': 'Contenido del aviso $id',
  'autor': 'Carlos Ramírez Soto',
  'fecha': '2026-05-10',
};

Widget _screen(GuardianApi api) =>
    MaterialApp(home: Scaffold(body: GuardianAnnouncementsScreen(api: api)));

void main() {
  testWidgets('muestra los comunicados con autor, fecha y contenido', (
    tester,
  ) async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/apoderado/comunicados');
      expect(request.headers['Authorization'], 'Bearer isolated-test-token');
      return _json([_item(1, 'Reunión general'), _item(2, 'Pago de pensiones')]);
    });
    await tester.pumpWidget(_screen(_api(client)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Comunicados'), findsOneWidget);
    expect(find.text('Reunión general'), findsOneWidget);
    expect(find.text('Pago de pensiones'), findsOneWidget);
    expect(find.text('Carlos Ramírez Soto · 2026-05-10'), findsNWidgets(2));
    expect(find.text('Contenido del aviso 1'), findsOneWidget);
  });

  testWidgets('avisa cuando no hay comunicados', (tester) async {
    final client = MockClient((_) async => _json([]));
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(find.text('No hay comunicados por ahora.'), findsOneWidget);
  });

  testWidgets('un 403 muestra el mensaje y Reintentar vuelve a consultar', (
    tester,
  ) async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return calls == 1
          ? _json({'codigo': 'SIN_PERFIL'}, 403)
          : _json([_item(1, 'Reunión general')]);
    });
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(
      find.text('Tu cuenta no tiene un perfil de apoderado registrado.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Reunión general'), findsOneWidget);
    expect(calls, 2);
  });
}
