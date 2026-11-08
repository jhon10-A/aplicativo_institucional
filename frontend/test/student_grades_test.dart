import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/screens/student_grades_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';

import 'auth_test.dart' show responseFixture;
import 'student_profile_test.dart' show enrollmentFixture;
import 'student_courses_test.dart' show courseFixture;

Map<String, Object?> gradeFixture({
  String period = '2026',
  num note = 18.75,
  String? observation,
}) => {
  'id': 901,
  'matriculaId': 102,
  'asignacionId': 501,
  'cursoId': 1,
  'curso': 'Matemática',
  'docente': 'Docente Prueba',
  'periodoId': 2,
  'periodo': period,
  'nivel': 'SECUNDARIA',
  'grado': 'Primero',
  'seccion': 'A',
  'etapa': 'Bimestre 1',
  'concepto': 'Examen',
  'nota': note,
  'observacion': observation,
  'registradoEn': '2026-04-03T10:00:00',
};

void main() {
  http.Response json(Object data, [int status = 200]) => http.Response(
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
      body: StudentGradesScreen(
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
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'carga y seleccion explicita, cursos, detalle y cambio de periodo',
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
            if (request.url.path.endsWith('/901')) {
              return json(gradeFixture(observation: 'Buen trabajo'));
            }
            return json([
              gradeFixture(
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
      await choose(tester, 'Matrícula y periodo', '2026 ·');
      expect(paths.last, '/api/estudiante/matriculas/2026/calificaciones');
      expect(find.text('Nota registrada: 18.75 / 20'), findsOneWidget);
      expect(find.text('Etapa: Bimestre 1'), findsOneWidget);
      await choose(tester, 'Curso', 'Matemática');
      expect(
        paths.last,
        '/api/estudiante/matriculas/2026/cursos/501/calificaciones',
      );
      await tester.tap(find.text('Examen'));
      await tester.pumpAndSettle();
      expect(paths.last, '/api/estudiante/matriculas/2026/calificaciones/901');
      expect(find.text('Detalle de la calificación'), findsOneWidget);
      expect(find.text('Buen trabajo'), findsOneWidget);
      expect(find.text('Docente: Docente Prueba'), findsOneWidget);
      expect(find.text('Registrada: 03/04/2026 10:00'), findsOneWidget);
      await tester.ensureVisible(find.text('Volver a calificaciones'));
      await tester.tap(find.text('Volver a calificaciones'));
      await tester.pumpAndSettle();
      expect(
        paths.last,
        '/api/estudiante/matriculas/2026/cursos/501/calificaciones',
      );
      await choose(tester, 'Matrícula y periodo', '2025 ·');
      expect(paths.last, '/api/estudiante/matriculas/2025/calificaciones');
      expect(find.text('Periodo: 2025'), findsOneWidget);
      expect(find.text('Todos los cursos'), findsOneWidget);
      expect(find.textContaining('isolated-test-token'), findsNothing);
    },
  );

  testWidgets(
    'sin matriculas o sin notas no inventa evaluaciones ni promedios',
    (tester) async {
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
            if (request.url.path.endsWith('/cursos')) {
              return json([courseFixture()]);
            }
            return json([]);
          }),
        ),
      );
      await tester.pumpAndSettle();
      await choose(tester, 'Matrícula y periodo', '2026 ·');
      expect(
        find.text('No hay calificaciones registradas para esta selección.'),
        findsOneWidget,
      );
      expect(find.textContaining('Nota registrada:'), findsNothing);
      expect(find.textContaining('Promedio'), findsNothing);
      expect(find.textContaining('Pendiente'), findsNothing);
    },
  );

  testWidgets('nota cero registrada no se presenta como pendiente', (
    tester,
  ) async {
    await tester.pumpWidget(
      screen(
        api((request) async {
          if (request.url.path.endsWith('/matriculas')) {
            return json([enrollmentFixture('2026')]);
          }
          if (request.url.path.endsWith('/cursos')) {
            return json([courseFixture()]);
          }
          if (request.url.path.endsWith('/901')) {
            return json(gradeFixture(note: 0));
          }
          return json([gradeFixture(note: 0)]);
        }),
      ),
    );
    await tester.pumpAndSettle();
    await choose(tester, 'Matrícula y periodo', '2026 ·');
    expect(find.text('Nota registrada: 0.00 / 20'), findsOneWidget);
    await tester.tap(find.text('Examen'));
    await tester.pumpAndSettle();
    expect(find.text('Sin observaciones registradas.'), findsOneWidget);
    expect(find.textContaining('Pendiente'), findsNothing);
  });

  testWidgets(
    'errores de lista y detalle permiten reintentar sin datos anteriores',
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
            if (request.url.path.endsWith('/901')) {
              if (++details == 1) return json({'codigo': 'NO_DISPONIBLE'}, 404);
              return json(gradeFixture());
            }
            if (++lists == 1) throw http.ClientException('private error');
            return json([gradeFixture()]);
          }),
        ),
      );
      await tester.pumpAndSettle();
      await choose(tester, 'Matrícula y periodo', '2026 ·');
      expect(
        find.text('No se pudo conectar. Comprueba tu conexión.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Examen'));
      await tester.pumpAndSettle();
      expect(find.text('Examen'), findsNothing);
      expect(
        find.text(
          'La matrícula, el curso o la calificación no está disponible.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Examen'), findsOneWidget);
      expect(find.textContaining('private error'), findsNothing);
    },
  );

  for (final status in [401, 403, 404, 500]) {
    testWidgets('gestiona HTTP $status sin cuerpos internos', (tester) async {
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

  testWidgets('descarta datos pendientes al abandonar la pantalla', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    await tester.pumpWidget(screen(api((_) => pending.future)));
    await tester.pumpWidget(const SizedBox());
    pending.complete(json([]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('panel abre Calificaciones y vuelve al inicio', (tester) async {
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
      find.byKey(const ValueKey('student-shortcut-calificaciones')),
    );
    expect(find.text('Consulta tus notas por curso y periodo'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('student-shortcut-calificaciones')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StudentGradesScreen), findsOneWidget);
    await tester.tap(find.text('Volver al inicio del panel'));
    await tester.pumpAndSettle();
    expect(find.text('Panel del estudiante'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets('calificaciones y detalle con texto ampliado $size', (
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
        if (request.url.path.endsWith('/901')) return json(gradeFixture());
        return json([gradeFixture()]);
      });
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: StudentGradesScreen(
              apiFactory: () => client,
              onUnauthorized: () {},
              onHome: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await choose(tester, 'Matrícula y periodo', '2026 ·');
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Examen'));
      await tester.tap(find.text('Examen'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle de la calificación'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('cliente restringe rutas de calificaciones y clasifica 404', () async {
    final client = api((request) async {
      expect(request.headers['Authorization'], 'Bearer isolated-test-token');
      expect(request.url.query, isEmpty);
      return json({'codigo': 'NO_DISPONIBLE'}, 404);
    });
    addTearDown(client.dispose);
    for (final route in [
      'matriculas/102/calificaciones',
      'matriculas/102/cursos/501/calificaciones',
      'matriculas/102/calificaciones/901',
    ]) {
      await expectLater(
        client.get(route),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            StudentFailureKind.unavailable,
          ),
        ),
      );
    }
    for (final route in [
      'matriculas/0/calificaciones',
      'matriculas/1/calificaciones?usuarioId=2',
      'matriculas/1/calificaciones/../2',
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
