import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/student_attendance.dart';
import 'package:aplicativo_institucional/features/student/screens/student_attendance_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';

import 'auth_test.dart' show responseFixture;
import 'student_profile_test.dart' show enrollmentFixture;
import 'student_courses_test.dart' show courseFixture;

Map<String, Object?> attendanceFixture({
  int id = 1001,
  String state = 'PRESENTE',
  String period = '2026',
}) => {
  'id': id,
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
  'fecha': '2026-04-01',
  'estado': state,
  'observacion': 'Observación registrada',
  'registradoEn': '2026-04-01T10:00:00',
};
Map<String, Object?> pageFixture(List<Map<String, Object?>> records) => {
  'registros': records,
  'resumen': {
    'total': records.length,
    'presente': records.where((r) => r['estado'] == 'PRESENTE').length,
    'falta': records.where((r) => r['estado'] == 'FALTA').length,
    'tardanza': records.where((r) => r['estado'] == 'TARDANZA').length,
    'justificada': records.where((r) => r['estado'] == 'JUSTIFICADA').length,
  },
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
      body: StudentAttendanceScreen(
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
    if (label == 'Matrícula y periodo' &&
        desired != null &&
        tester.widget<DropdownButtonFormField<int>>(dropdown).initialValue ==
            desired) {
      return;
    }
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'carga, seleccion explicita, resumen, curso, fechas y detalle conservan filtros',
    (tester) async {
      final pending = Completer<http.Response>();
      final urls = <Uri>[];
      await tester.pumpWidget(
        screen(
          api((request) async {
            urls.add(request.url);
            expect(
              request.headers['Authorization'],
              'Bearer isolated-test-token',
            );
            if (request.url.path.endsWith('/matriculas')) return pending.future;
            if (request.url.path.endsWith('/cursos')) {
              return json([courseFixture()]);
            }
            if (request.url.path.endsWith('/1001')) {
              return json(attendanceFixture());
            }
            return json(
              pageFixture([
                attendanceFixture(
                  period: request.url.path.contains('/2025/') ? '2025' : '2026',
                ),
              ]),
            );
          }),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(
        json([enrollmentFixture('2026'), enrollmentFixture('2025')]),
      );
      await tester.pumpAndSettle();
      expect(urls.length, 1);
      await choose(tester, 'Matrícula y periodo', '2026 ·');
      expect(urls.last.path, '/api/estudiante/matriculas/2026/asistencias');
      expect(find.text('Total: 1'), findsOneWidget);
      expect(find.text('Presentes: 1'), findsOneWidget);
      expect(find.text('Faltas: 0'), findsOneWidget);
      await choose(tester, 'Curso', 'Matemática');
      expect(
        urls.last.path,
        '/api/estudiante/matriculas/2026/cursos/501/asistencias',
      );
      await tester.enterText(
        find.byKey(const ValueKey('attendance-from')),
        '2026-04-01',
      );
      await tester.enterText(
        find.byKey(const ValueKey('attendance-to')),
        '2026-04-02',
      );
      await tap(tester, 'Aplicar fechas');
      expect(urls.last.queryParameters, {
        'desde': '2026-04-01',
        'hasta': '2026-04-02',
      });
      await tap(tester, '01/04/2026 · Matemática');
      expect(
        urls.last.path,
        '/api/estudiante/matriculas/2026/asistencias/1001',
      );
      expect(urls.last.query, isEmpty);
      expect(find.text('Detalle de la asistencia'), findsOneWidget);
      expect(find.text('Observación registrada'), findsOneWidget);
      expect(find.text('Estado: Presente'), findsOneWidget);
      await tap(tester, 'Volver a asistencias');
      expect(urls.last.queryParameters, {
        'desde': '2026-04-01',
        'hasta': '2026-04-02',
      });
      await tap(tester, 'Limpiar fechas');
      expect(urls.last.query, isEmpty);
      await choose(tester, 'Matrícula y periodo', '2025 ·');
      expect(urls.last.path, '/api/estudiante/matriculas/2025/asistencias');
      expect(find.text('Periodo: 2025'), findsOneWidget);
      expect(find.text('Todos los cursos'), findsOneWidget);
      expect(find.textContaining('isolated-test-token'), findsNothing);
    },
  );

  testWidgets('fechas imposibles y rangos invertidos no envian consultas', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      screen(
        api((request) async {
          calls++;
          if (request.url.path.endsWith('/matriculas')) {
            return json([enrollmentFixture('2026')]);
          }
          if (request.url.path.endsWith('/cursos')) {
            return json([courseFixture()]);
          }
          return json(pageFixture([]));
        }),
      ),
    );
    await tester.pumpAndSettle();
    await choose(tester, 'Matrícula y periodo', '2026 ·');
    final before = calls;
    await tester.enterText(
      find.byKey(const ValueKey('attendance-from')),
      '2026-02-30',
    );
    await tap(tester, 'Aplicar fechas');
    expect(
      find.text('Usa fechas válidas AAAA-MM-DD y un rango en orden.'),
      findsOneWidget,
    );
    expect(calls, before);
    await tester.enterText(
      find.byKey(const ValueKey('attendance-from')),
      '2026-04-03',
    );
    await tester.enterText(
      find.byKey(const ValueKey('attendance-to')),
      '2026-04-02',
    );
    await tap(tester, 'Aplicar fechas');
    expect(calls, before);
  });

  testWidgets(
    'todos los estados y resumen reflejan solo registros existentes',
    (tester) async {
      final records = ['PRESENTE', 'FALTA', 'TARDANZA', 'JUSTIFICADA'].indexed
          .map((e) => attendanceFixture(id: 1001 + e.$1, state: e.$2))
          .toList();
      await tester.pumpWidget(
        screen(
          api((request) async {
            if (request.url.path.endsWith('/matriculas')) {
              return json([enrollmentFixture('2026')]);
            }
            if (request.url.path.endsWith('/cursos')) {
              return json([courseFixture()]);
            }
            return json(pageFixture(records));
          }),
        ),
      );
      await tester.pumpAndSettle();
      await choose(tester, 'Matrícula y periodo', '2026 ·');
      for (final label in [
        'Total: 4',
        'Presentes: 1',
        'Faltas: 1',
        'Tardanzas: 1',
        'Justificadas: 1',
        'Estado: Presente',
        'Estado: Falta',
        'Estado: Tardanza',
        'Estado: Justificada',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.textContaining('%'), findsNothing);
    },
  );

  testWidgets('sin matriculas y rango sin datos no inventan faltas', (
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
          if (request.url.path.endsWith('/cursos')) {
            return json([courseFixture()]);
          }
          return json(pageFixture([]));
        }),
      ),
    );
    await tester.pumpAndSettle();
    await choose(tester, 'Matrícula y periodo', '2026 ·');
    expect(
      find.text('No hay asistencias registradas para esta selección.'),
      findsOneWidget,
    );
    expect(find.text('Resumen de registros consultados'), findsNothing);
    expect(find.text('Estado: Falta'), findsNothing);
  });

  testWidgets('errores de listado y detalle permiten reintentar', (
    tester,
  ) async {
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
          if (request.url.path.endsWith('/1001')) {
            if (++details == 1) return json({'codigo': 'NO_DISPONIBLE'}, 404);
            return json(attendanceFixture());
          }
          if (++lists == 1) throw http.ClientException('private error');
          return json(pageFixture([attendanceFixture()]));
        }),
      ),
    );
    await tester.pumpAndSettle();
    await choose(tester, 'Matrícula y periodo', '2026 ·');
    expect(
      find.text('No se pudo conectar. Comprueba tu conexión.'),
      findsOneWidget,
    );
    await tap(tester, 'Reintentar');
    await tap(tester, '01/04/2026 · Matemática');
    expect(
      find.text('La matrícula, el curso o la asistencia no está disponible.'),
      findsOneWidget,
    );
    expect(find.text('Observación registrada'), findsNothing);
    await tap(tester, 'Reintentar');
    expect(find.text('Observación registrada'), findsOneWidget);
    expect(find.textContaining('private error'), findsNothing);
  });

  for (final status in [401, 403, 404, 500]) {
    testWidgets('HTTP $status sin exposicion de cuerpos privados', (
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

  testWidgets('abandono descarta respuestas tardias', (tester) async {
    final pending = Completer<http.Response>();
    await tester.pumpWidget(screen(api((_) => pending.future)));
    await tester.pumpWidget(const SizedBox());
    pending.complete(json([]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('panel navega a Asistencia y regresa al inicio', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentPanel(
          session: Session.fromJson(responseFixture()),
          onLogout: () {},
          studentApiFactory: () => api((_) async => json([])),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('student-shortcut-asistencia')),
      findsNothing,
    );
    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('student-nav-asistencia')));
    await tester.pumpAndSettle();
    expect(find.byType(StudentAttendanceScreen), findsOneWidget);
    await tap(tester, 'Volver al inicio del panel');
    expect(find.text('Hola,'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets('asistencia y detalle con texto ampliado $size', (
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
        if (request.url.path.endsWith('/1001')) {
          return json(attendanceFixture());
        }
        return json(pageFixture([attendanceFixture()]));
      });
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: StudentAttendanceScreen(
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
      await tap(tester, '01/04/2026 · Matemática');
      expect(find.text('Detalle de la asistencia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('cliente valida fechas estrictas y limita parametros a los listados de asistencia', () async {
    expect(validAttendanceDate('2024-02-29'), isTrue);
    expect(validAttendanceDate('2026-02-29'), isFalse);
    var calls = 0;
    final client = api((request) async {
      calls++;
      expect(request.headers['Authorization'], 'Bearer isolated-test-token');
      expect(request.url.queryParameters, {
        'desde': '2026-04-01',
        'hasta': '2026-04-03',
      });
      return json(pageFixture([]));
    });
    addTearDown(client.dispose);
    await client.get(
      'matriculas/102/asistencias',
      query: {'desde': '2026-04-01', 'hasta': '2026-04-03'},
    );
    for (final query in [
      {'desde': '2026-02-30'},
      {'desde': '2026-04-03', 'hasta': '2026-04-01'},
      {'usuarioId': '2'},
    ]) {
      await expectLater(
        client.get('matriculas/102/asistencias', query: query),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            StudentFailureKind.validation,
          ),
        ),
      );
    }
    await expectLater(
      client.get('perfil', query: {'desde': '2026-04-01'}),
      throwsA(isA<StudentFailure>()),
    );
    expect(calls, 1);
  });
}
