import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/screens/student_tasks_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';

import 'auth_test.dart' show responseFixture;
import 'student_profile_test.dart' show enrollmentFixture;
import 'student_courses_test.dart' show courseFixture;

Map<String, Object?> taskFixture({
  int id = 701,
  String title = 'Álgebra',
  bool submitted = false,
  bool reviewed = true,
  String? deadline,
}) => {
  'id': id,
  'asignacionId': 501,
  'cursoId': 1,
  'curso': 'Matemática',
  'docente': 'Docente Prueba',
  'titulo': title,
  'descripcion': 'Resolver ejercicios',
  'archivoUrl': null,
  'fechaPublicacion': '2026-04-01T08:00:00',
  'fechaLimite': deadline ?? '2026-04-10T18:00:00',
  'puntajeMaximo': 20,
  'estadoEntrega': !submitted
      ? 'PENDIENTE'
      : reviewed
      ? 'REVISADA'
      : 'ENTREGADA',
  'entrega': submitted
      ? {
          'id': 801,
          'comentario': 'Mi comentario',
          'archivoUrl': 'https://example.invalid/propia.pdf',
          'fechaEntrega': '2026-04-05T10:00:00',
          'puntaje': 18,
          'retroalimentacion': 'Buen trabajo',
          'fechaRevision': reviewed ? '2026-04-06T10:00:00' : null,
        }
      : null,
};

void main() {
  http.Response json(Object? data, [int status = 200]) => http.Response(
    jsonEncode(data),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
  StudentApi api(Future<http.Response> Function(http.Request) handler) =>
      StudentApi(
        baseUrl: 'http://localhost:8080',
        token: 'isolated-test-token',
        client: MockClient(handler),
      );
  Widget screen(StudentApi client, {VoidCallback? expired}) => MaterialApp(
    home: Scaffold(
      body: StudentTasksScreen(
        apiFactory: () => client,
        onUnauthorized: expired ?? () {},
        onHome: () {},
      ),
    ),
  );
  Future<void> choose(WidgetTester tester, String label, String text) async {
    final dropdown = find.ancestor(
      of: find.text(label),
      matching: find.byType(DropdownButtonFormField<int>),
    );
    final desired = int.tryParse(text.split(' ').first);
    if (label == 'Matrícula y año escolar' &&
        desired != null &&
        dropdown.evaluate().isNotEmpty &&
        tester.widget<DropdownButtonFormField<int>>(dropdown).initialValue ==
            desired) {
      return;
    }
    if (dropdown.evaluate().isEmpty) return;
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'carga, seleccion explicita de matricula, filtro de curso y detalle propio',
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
            if (request.url.path.endsWith('/cursos')) {
              return json([courseFixture()]);
            }
            if (request.url.path.endsWith('/701')) {
              return json(taskFixture(submitted: true));
            }
            return json([taskFixture()]);
          }),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(
        json([enrollmentFixture('2026'), enrollmentFixture('2025')]),
      );
      await tester.pumpAndSettle();
      expect(paths, ['/api/estudiante/matriculas']);
      await choose(tester, 'Matrícula y año escolar', '2026 ·');
      expect(paths.last, '/api/estudiante/matriculas/2026/tareas');
      expect(find.text('Año escolar: 2026'), findsOneWidget);
      expect(find.text('Fecha límite: 10/04/2026 18:00'), findsOneWidget);
      expect(find.text('Estado de entrega: Vencida'), findsOneWidget);
      await choose(tester, 'Curso', 'Matemática');
      expect(paths.last, '/api/estudiante/matriculas/2026/cursos/501/tareas');
      await tester.tap(find.text('Álgebra'));
      await tester.pumpAndSettle();
      expect(paths.last, '/api/estudiante/matriculas/2026/tareas/701');
      expect(find.text('Detalle de la tarea'), findsOneWidget);
      expect(find.text('Estado de entrega: Revisada'), findsOneWidget);
      expect(find.text('Comentario: Mi comentario'), findsOneWidget);
      expect(find.text('Puntaje: 18.0'), findsOneWidget);
      expect(find.text('Retroalimentación: Buen trabajo'), findsOneWidget);
      expect(find.textContaining('isolated-test-token'), findsNothing);
      await tester.ensureVisible(find.text('Volver a tareas'));
      await tester.tap(find.text('Volver a tareas'));
      await tester.pumpAndSettle();
      expect(paths.last, '/api/estudiante/matriculas/2026/cursos/501/tareas');
      await choose(tester, 'Matrícula y año escolar', '2025 ·');
      expect(paths.last, '/api/estudiante/matriculas/2025/tareas');
      expect(find.text('Todos los cursos'), findsOneWidget);
    },
  );

  testWidgets('distingue ausencia de matriculas y tareas vacias', (
    tester,
  ) async {
    await tester.pumpWidget(screen(api((_) async => json([]))));
    await tester.pumpAndSettle();
    expect(find.text('No tienes matrículas registradas.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      screen(
        api((request) async {
          if (request.url.path.endsWith('/matriculas')) {
            return json([enrollmentFixture('2026')]);
          }
          return json([]);
        }),
      ),
    );
    await tester.pumpAndSettle();
    await choose(tester, 'Matrícula y año escolar', '2026 ·');
    expect(
      find.text('No hay tareas disponibles para esta selección.'),
      findsOneWidget,
    );
  });

  testWidgets('año escolar y estado usan fecha y entrega de la API', (
    tester,
  ) async {
    final enrollment = enrollmentFixture('2026');
    (enrollment['periodo'] as Map<String, Object?>)['nombre'] =
        'TEST_EST_a144bf99';
    final pendingDeadline = DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String();
    await tester.pumpWidget(
      screen(
        api(
          (request) async => request.url.path.endsWith('/matriculas')
              ? json([enrollment])
              : request.url.path.endsWith('/cursos')
              ? json([])
              : json([
                  taskFixture(deadline: pendingDeadline),
                  taskFixture(
                    id: 702,
                    title: 'Tarea vencida',
                    deadline: '2020-04-10T18:00:00',
                  ),
                  taskFixture(
                    id: 703,
                    title: 'Tarea entregada',
                    submitted: true,
                    reviewed: false,
                  ),
                  taskFixture(
                    id: 704,
                    title: 'Tarea revisada',
                    submitted: true,
                  ),
                ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Año escolar: 2026'), findsOneWidget);
    expect(find.text('Año escolar: TEST_EST_a144bf99'), findsNothing);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    expect(find.text('Estado de entrega: Pendiente'), findsOneWidget);
    expect(find.text('Estado de entrega: Vencida'), findsOneWidget);
    expect(find.text('Estado de entrega: Entregada'), findsOneWidget);
    expect(find.text('Estado de entrega: Revisada'), findsOneWidget);
  });

  testWidgets(
    'reintenta errores de lista y detalle sin mostrar datos anteriores',
    (tester) async {
      var lists = 0;
      var details = 0;
      await tester.pumpWidget(
        screen(
          api((request) async {
            if (request.url.path.endsWith('/matriculas')) {
              return json([enrollmentFixture('2026')]);
            }
            if (request.url.path.endsWith('/cursos')) {
              return json([courseFixture()]);
            }
            if (request.url.path.endsWith('/701')) {
              if (++details == 1) return json({'codigo': 'NO_DISPONIBLE'}, 404);
              return json(taskFixture());
            }
            if (++lists == 1) throw http.ClientException('private detail');
            return json([taskFixture()]);
          }),
        ),
      );
      await tester.pumpAndSettle();
      await choose(tester, 'Matrícula y año escolar', '2026 ·');
      expect(
        find.text('No se pudo conectar. Comprueba tu conexión.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Álgebra'));
      await tester.pumpAndSettle();
      expect(find.text('Álgebra'), findsNothing);
      expect(
        find.text('La matrícula, el curso o la tarea no está disponible.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Resolver ejercicios'), findsOneWidget);
      expect(find.text('Mi entrega'), findsNothing);
      expect(find.textContaining('private detail'), findsNothing);
    },
  );

  for (final status in [401, 403, 404, 500]) {
    testWidgets('gestiona HTTP $status sin mostrar cuerpos privados', (
      tester,
    ) async {
      var expired = 0;
      await tester.pumpWidget(
        screen(
          api(
            (_) async => json({
              'codigo': 'SIN_PERFIL',
              'private': 'do not show',
            }, status),
          ),
          expired: () => expired++,
        ),
      );
      await tester.pumpAndSettle();
      expect(expired, status == 401 ? 1 : 0);
      expect(
        find.text('Reintentar'),
        [401, 403].contains(status) ? findsNothing : findsOneWidget,
      );
      expect(find.textContaining('do not show'), findsNothing);
    });
  }

  testWidgets('descarta respuestas pendientes al salir', (tester) async {
    final pending = Completer<http.Response>();
    await tester.pumpWidget(screen(api((_) => pending.future)));
    await tester.pumpWidget(const SizedBox());
    pending.complete(json([]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('panel abre Tareas funcional y vuelve al inicio', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentPanel(
          session: Session.fromJson(responseFixture()),
          onLogout: () {},
          studentApiFactory: () => api((_) async => json([])),
        ),
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('student-shortcut-tareas')),
    );
    await tester.tap(find.byKey(const ValueKey('student-shortcut-tareas')));
    await tester.pumpAndSettle();
    expect(find.text('Abrir pantalla completa'), findsNothing);
    expect(find.byType(StudentTasksScreen), findsOneWidget);
    expect(find.text('No tienes matrículas registradas.'), findsOneWidget);
    await tester.tap(find.text('Volver al inicio del panel'));
    await tester.pumpAndSettle();
    expect(find.text('Hola,'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets('tareas y detalle adaptables con texto ampliado $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = api((request) async {
        if (request.url.path.endsWith('/matriculas')) {
          return json([enrollmentFixture('2026')]);
        }
        if (request.url.path.endsWith('/cursos')) {
          return json([courseFixture()]);
        }
        if (request.url.path.endsWith('/701')) {
          return json(taskFixture(submitted: true));
        }
        return json([taskFixture()]);
      });
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: StudentTasksScreen(
              apiFactory: () => client,
              onUnauthorized: () {},
              onHome: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await choose(tester, 'Matrícula y año escolar', '2026 ·');
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Álgebra'));
      await tester.tap(find.text('Álgebra'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle de la tarea'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('cliente permite solo rutas de consulta de tareas validas', () async {
    final client = api((request) async {
      expect(request.url.query, isEmpty);
      expect(request.headers['Authorization'], 'Bearer isolated-test-token');
      return json([]);
    });
    addTearDown(client.dispose);
    for (final route in [
      'matriculas/102/tareas',
      'matriculas/102/cursos/501/tareas',
      'matriculas/102/tareas/701',
    ]) {
      expect(await client.get(route), isEmpty);
    }
    for (final route in [
      'matriculas/0/tareas',
      'matriculas/1/tareas?usuarioId=2',
      'matriculas/1/entregas/2',
    ]) {
      await expectLater(
        client.get(route),
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
