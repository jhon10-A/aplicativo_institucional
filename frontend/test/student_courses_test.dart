import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/screens/student_courses_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';

import 'auth_test.dart' show responseFixture;
import 'student_profile_test.dart' show enrollmentFixture;

Map<String, Object?> courseFixture({
  String period = '2026',
  String? description,
}) => {
  'asignacionId': 501,
  'cursoId': 1,
  'nombre': 'Matemática',
  'descripcion': description,
  'activo': true,
  'docente': 'Docente Prueba',
  'periodo': period,
  'nivel': 'SECUNDARIA',
  'grado': 'Primero',
  'seccion': 'A',
};

void main() {
  StudentApi api(Future<http.Response> Function(http.Request) handler) =>
      StudentApi(
        baseUrl: 'http://localhost:8080',
        token: 'isolated-test-token',
        client: MockClient(handler),
      );
  Widget screen(StudentApi client, {VoidCallback? expired}) => MaterialApp(
    home: Scaffold(
      body: StudentCoursesScreen(
        apiFactory: () => client,
        onUnauthorized: expired ?? () {},
        onHome: () {},
      ),
    ),
  );
  http.Response json(Object? value, [int status = 200]) => http.Response(
    jsonEncode(value),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
  Future<void> select(WidgetTester tester, String period) async {
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('$period ·').last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'carga, seleccion explicita, lista, detalle y cambio de periodo',
    (tester) async {
      final pending = Completer<http.Response>();
      final paths = <String>[];
      await tester.pumpWidget(
        screen(
          api((request) async {
            paths.add(request.url.path);
            expect(
              request.headers['Authorization'],
              'Bearer isolated-test-token',
            );
            if (request.url.path.endsWith('/matriculas')) return pending.future;
            if (request.url.path.endsWith('/501')) {
              return json(courseFixture(description: 'Descripción del curso'));
            }
            return json([
              courseFixture(
                period: request.url.path.contains('/2025/') ? '2025' : '2026',
              ),
            ]);
          }),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(
        json([enrollmentFixture('2026'), enrollmentFixture('2025')]),
      );
      await tester.pumpAndSettle();
      expect(paths, ['/api/estudiante/matriculas']);
      expect(
        find.text('Selecciona una matrícula para consultar sus cursos.'),
        findsOneWidget,
      );
      await select(tester, '2026');
      expect(paths.last, '/api/estudiante/matriculas/2026/cursos');
      expect(find.text('Docente: Docente Prueba'), findsOneWidget);
      expect(find.text('Periodo: 2026'), findsOneWidget);
      expect(find.text('Grado: Primero'), findsOneWidget);
      expect(find.text('Sección: A'), findsOneWidget);
      await tester.tap(find.text('Matemática'));
      await tester.pumpAndSettle();
      expect(paths.last, '/api/estudiante/matriculas/2026/cursos/501');
      expect(find.text('Detalle del curso'), findsOneWidget);
      expect(find.text('Descripción del curso'), findsOneWidget);
      await tester.tap(find.text('Volver a cursos'));
      await tester.pumpAndSettle();
      await select(tester, '2025');
      expect(paths.last, '/api/estudiante/matriculas/2025/cursos');
      expect(find.text('Periodo: 2025'), findsOneWidget);
      expect(find.text('Periodo: 2026'), findsNothing);
      expect(find.textContaining('isolated-test-token'), findsNothing);
    },
  );

  testWidgets('sin matriculas y sin cursos son estados distintos', (
    tester,
  ) async {
    await tester.pumpWidget(screen(api((_) async => json([]))));
    await tester.pumpAndSettle();
    expect(find.text('No tienes matrículas registradas.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      screen(
        api(
          (request) async => request.url.path.endsWith('/matriculas')
              ? json([enrollmentFixture('2026')])
              : json([]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await select(tester, '2026');
    expect(
      find.text('No hay cursos asignados a esta matrícula.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'error de lista y detalle permiten reintentar sin datos anteriores',
    (tester) async {
      var listCalls = 0;
      var detailCalls = 0;
      await tester.pumpWidget(
        screen(
          api((request) async {
            if (request.url.path.endsWith('/matriculas')) {
              return json([enrollmentFixture('2026')]);
            }
            if (request.url.path.endsWith('/501')) {
              if (++detailCalls == 1) return json({}, 500);
              return json(courseFixture());
            }
            if (++listCalls == 1) throw http.ClientException('private detail');
            return json([courseFixture()]);
          }),
        ),
      );
      await tester.pumpAndSettle();
      await select(tester, '2026');
      expect(
        find.text('No se pudo conectar. Comprueba tu conexión.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Matemática'));
      await tester.pumpAndSettle();
      expect(find.text('Matemática'), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Sin descripción registrada.'), findsOneWidget);
      expect(find.textContaining('private detail'), findsNothing);
    },
  );

  for (final status in [401, 403, 404]) {
    testWidgets('maneja HTTP $status y cierre de sesion', (tester) async {
      var expired = 0;
      await tester.pumpWidget(
        screen(
          api((_) async => json({'codigo': 'SIN_PERFIL'}, status)),
          expired: () => expired++,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(expired, status == 401 ? 1 : 0);
      expect(
        find.text('Reintentar'),
        status == 404 ? findsOneWidget : findsNothing,
      );
    });
  }

  testWidgets('descarta respuestas al abandonar la pantalla', (tester) async {
    final pending = Completer<http.Response>();
    await tester.pumpWidget(screen(api((_) => pending.future)));
    await tester.pumpWidget(const SizedBox());
    pending.complete(json([]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu Cursos abre la pantalla funcional y vuelve al inicio', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentPanel(
          session: Session.fromJson(responseFixture()),
          onLogout: () {},
          studentApiFactory: () => api((_) async => json([])),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('student-shortcut-cursos')));
    await tester.pumpAndSettle();
    expect(find.byType(StudentCoursesScreen), findsOneWidget);
    expect(find.text('No tienes matrículas registradas.'), findsOneWidget);
    await tester.tap(find.text('Volver al inicio del panel'));
    await tester.pumpAndSettle();
    expect(find.text('Panel del estudiante'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets(
      'cursos y detalle sin desbordamientos con texto ampliado $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = api((request) async {
          if (request.url.path.endsWith('/matriculas')) {
            return json([enrollmentFixture('2026')]);
          }
          if (request.url.path.endsWith('/501')) return json(courseFixture());
          return json([courseFixture()]);
        });
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: StudentCoursesScreen(
                apiFactory: () => client,
                onUnauthorized: () {},
                onHome: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await select(tester, '2026');
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Matemática'));
        await tester.tap(find.text('Matemática'));
        await tester.pumpAndSettle();
        expect(find.text('Detalle del curso'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('cliente restringe rutas y distingue cursos no disponibles', () async {
    final client = api((_) async => json({'codigo': 'NO_DISPONIBLE'}, 404));
    addTearDown(client.dispose);
    await expectLater(
      client.get('matriculas/102/cursos/501'),
      throwsA(
        isA<StudentFailure>().having(
          (e) => e.kind,
          'kind',
          StudentFailureKind.unavailable,
        ),
      ),
    );
    for (final path in [
      'matriculas/0/cursos',
      'matriculas/1/cursos?usuarioId=2',
      'matriculas/1/cursos/../2',
    ]) {
      await expectLater(
        client.get(path),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            StudentFailureKind.invalid,
          ),
        ),
      );
    }
  });
}
