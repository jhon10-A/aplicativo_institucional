import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/screens/student_profile_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';

import 'auth_test.dart' show responseFixture;

Map<String, Object?> profileFixture() => {
  'id': 11,
  'usuarioId': 1,
  'nombreUsuario': 'fixture1',
  'nombres': 'Primera',
  'apellidos': 'Persona',
  'codigoEstudiante': 'E1',
  'correo': null,
  'telefono': null,
  'documentoIdentidad': null,
  'fechaNacimiento': null,
};
Map<String, Object?> enrollmentFixture(String period) => {
  'id': int.parse(period),
  'estado': 'ACTIVA',
  'fechaMatricula': '$period-03-01',
  'periodo': {
    'id': int.parse(period),
    'nombre': period,
    'fechaInicio': '$period-03-01',
    'fechaFin': '$period-12-31',
    'activo': true,
  },
  'seccion': {
    'id': 1,
    'nombre': 'A',
    'grado': {'id': 1, 'nombre': 'Primero', 'nivel': 'SECUNDARIA'},
  },
};

void main() {
  StudentApi client(Future<http.Response> Function(http.Request) handler) =>
      StudentApi(
        baseUrl: 'http://localhost:8080',
        token: 'isolated-test-token',
        client: MockClient(handler),
      );
  Widget screen(StudentApi Function() factory, {VoidCallback? expired}) =>
      MaterialApp(
        home: Scaffold(
          body: StudentProfileScreen(
            apiFactory: factory,
            onUnauthorized: expired ?? () {},
            onHome: () {},
          ),
        ),
      );

  testWidgets(
    'muestra carga, perfil real y todas las matriculas sin elegir una',
    (tester) async {
      final pending = Completer<http.Response>();
      await tester.pumpWidget(
        screen(
          () => client((request) async {
            if (request.url.path.endsWith('/perfil')) return pending.future;
            return http.Response(
              jsonEncode([
                enrollmentFixture('2026'),
                enrollmentFixture('2025'),
              ]),
              200,
            );
          }),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(http.Response(jsonEncode(profileFixture()), 200));
      await tester.pumpAndSettle();
      expect(find.text('Nombres: Primera Persona'), findsOneWidget);
      expect(find.text('Código de estudiante: E1'), findsOneWidget);
      expect(find.text('Correo: No registrado'), findsOneWidget);
      expect(find.text('Periodo: 2026'), findsOneWidget);
      expect(find.text('Periodo: 2025'), findsOneWidget);
      expect(find.textContaining('isolated-test-token'), findsNothing);
    },
  );

  testWidgets('distingue perfil inexistente y ausencia de matriculas', (
    tester,
  ) async {
    await tester.pumpWidget(
      screen(() => client((_) async => http.Response('{}', 404))),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No tienes un perfil de estudiante registrado.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      screen(
        () => client(
          (r) async => http.Response(
            jsonEncode(r.url.path.endsWith('/perfil') ? profileFixture() : []),
            200,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nombres: Primera Persona'), findsOneWidget);
    expect(find.text('No tienes matrículas registradas.'), findsOneWidget);
  });

  testWidgets('permite reintentar despues de fallo de conexion', (
    tester,
  ) async {
    var attempt = 0;
    await tester.pumpWidget(
      screen(() {
        attempt++;
        return client((r) async {
          if (attempt == 1) throw http.ClientException('private detail');
          return http.Response(
            jsonEncode(r.url.path.endsWith('/perfil') ? profileFixture() : []),
            200,
          );
        });
      }),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo conectar.'), findsOneWidget);
    expect(find.textContaining('private detail'), findsNothing);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Nombres: Primera Persona'), findsOneWidget);
  });

  testWidgets('gestiona 401 y 403 sin exponer respuestas del servidor', (
    tester,
  ) async {
    var expired = 0;
    await tester.pumpWidget(
      screen(
        () => client((_) async => http.Response('private', 401)),
        expired: () => expired++,
      ),
    );
    await tester.pumpAndSettle();
    expect(expired, 1);
    expect(find.textContaining('Tu sesión ha vencido.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      screen(() => client((_) async => http.Response('private', 403))),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No tienes acceso al módulo Estudiante.'),
      findsOneWidget,
    );
    expect(find.text('private'), findsNothing);
  });

  testWidgets('rechaza respuesta incompleta', (tester) async {
    await tester.pumpWidget(
      screen(() => client((_) async => http.Response('{}', 200))),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudo cargar el perfil. Inténtalo nuevamente.'),
      findsOneWidget,
    );
  });

  testWidgets('descarta respuesta tardia tras salir de Perfil', (tester) async {
    final pending = Completer<http.Response>();
    var expired = 0;
    await tester.pumpWidget(
      screen(() => client((_) => pending.future), expired: () => expired++),
    );
    await tester.pumpWidget(const MaterialApp(home: Text('Otra pantalla')));
    pending.complete(http.Response('{}', 401));
    await tester.pumpAndSettle();
    expect(find.text('Otra pantalla'), findsOneWidget);
    expect(expired, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opcion Perfil del menu carga sus endpoints', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentPanel(
          session: Session.fromJson(responseFixture()),
          onLogout: () {},
          studentApiFactory: () => client(
            (r) async => http.Response(
              jsonEncode(
                r.url.path.endsWith('/perfil') ? profileFixture() : [],
              ),
              200,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('student-nav-perfil')));
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Nombres: Primera Persona'), findsOneWidget);
  });

  testWidgets('perfil se adapta a movil con texto ampliado', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
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
        home: Scaffold(
          body: StudentProfileScreen(
            apiFactory: () => client(
              (r) async => http.Response(
                jsonEncode(
                  r.url.path.endsWith('/perfil')
                      ? profileFixture()
                      : [enrollmentFixture('2026')],
                ),
                200,
              ),
            ),
            onUnauthorized: () {},
            onHome: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
