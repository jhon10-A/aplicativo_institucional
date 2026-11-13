import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/guardian/guardian_api.dart';
import 'package:aplicativo_institucional/features/guardian/guardian_section.dart';
import 'package:aplicativo_institucional/features/guardian/screens/guardian_children_screen.dart';
import 'package:aplicativo_institucional/features/guardian/screens/guardian_panel.dart';

const _token = 'isolated-test-token';

GuardianApi _api(MockClient client) => GuardianApi(
  baseUrl: 'http://localhost:8080',
  token: _token,
  client: client,
);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _child({bool enrolled = true}) => {
  'id': 7,
  'nombres': 'Lucía',
  'apellidos': 'Quispe Mamani',
  'codigoEstudiante': 'E-0007',
  'parentesco': 'Madre',
  'contactoPrincipal': true,
  'matriculaId': enrolled ? 3 : null,
  'estado': enrolled ? 'ACTIVA' : null,
  'periodo': enrolled ? '2026' : null,
  'nivel': enrolled ? 'Primaria' : null,
  'grado': enrolled ? '3°' : null,
  'seccion': enrolled ? 'A' : null,
};

Widget _screen(GuardianApi api) =>
    MaterialApp(home: Scaffold(body: GuardianChildrenScreen(api: api)));

void main() {
  testWidgets('muestra los hijos con su matrícula', (tester) async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/apoderado/hijos');
      expect(request.headers['Authorization'], 'Bearer $_token');
      return _json([_child()]);
    });
    await tester.pumpWidget(_screen(_api(client)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Lucía Quispe Mamani'), findsOneWidget);
    expect(find.text('Código: E-0007'), findsOneWidget);
    expect(find.text('Parentesco: Madre (contacto principal)'), findsOneWidget);
    expect(find.text('Primaria · 3° · A'), findsOneWidget);
    expect(find.text('Periodo 2026 · Matrícula ACTIVA'), findsOneWidget);
    expect(find.text(_token), findsNothing);
  });

  testWidgets('indica cuando el hijo no tiene matrícula', (tester) async {
    final client = MockClient((_) async => _json([_child(enrolled: false)]));
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(find.text('Sin matrícula registrada'), findsOneWidget);
  });

  testWidgets('muestra un mensaje cuando no hay hijos vinculados', (
    tester,
  ) async {
    final client = MockClient((_) async => _json([]));
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aún no tienes hijos vinculados'), findsOneWidget);
  });

  testWidgets('403 muestra el mensaje y Reintentar vuelve a consultar', (
    tester,
  ) async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return calls == 1
          ? _json({'codigo': 'SIN_PERFIL'}, 403)
          : _json([_child()]);
    });
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(
      find.text('Tu cuenta no tiene un perfil de apoderado registrado.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Lucía Quispe Mamani'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('un fallo de red muestra el mensaje de conexión', (tester) async {
    final client = MockClient((_) async => throw http.ClientException('sin red'));
    await tester.pumpWidget(_screen(_api(client)));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo conectar'), findsOneWidget);
  });

  testWidgets('el panel abre Mis hijos desde la navegación', (tester) async {
    final client = MockClient((_) async => _json([_child()]));
    await tester.pumpWidget(
      MaterialApp(
        home: GuardianPanel(
          session: Session(
            _token,
            DateTime.now().add(const Duration(hours: 1)),
            1,
            'apoderado.prueba',
            'Nombre de prueba',
            'Apellido de prueba',
            const ['APODERADO'],
          ),
          onLogout: () {},
          api: _api(client),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('guardian-nav-${GuardianSection.hijos.name}')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lucía Quispe Mamani'), findsOneWidget);
  });
}
