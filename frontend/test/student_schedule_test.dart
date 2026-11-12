import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/features/student/screens/student_schedule_screen.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/student_schedule.dart';

import 'student_profile_test.dart' show enrollmentFixture;

Map<String, Object?> scheduleFixture({
  int id = 601,
  int weekday = 1,
  String start = '08:00:00',
  String end = '08:45:00',
  String course = 'Matemática',
  String teacher = 'Docente asignado',
  String? room = 'Aula 1',
}) => {
  'id': id,
  'matriculaId': 2026,
  'asignacionId': 501,
  'cursoId': 1,
  'curso': course,
  'docente': teacher,
  'periodoId': 2026,
  'periodo': '2026',
  'nivel': 'SECUNDARIA',
  'grado': 'Primero',
  'seccion': 'A',
  'diaSemana': weekday,
  'horaInicio': start,
  'horaFin': end,
  'aula': room,
};

void main() {
  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  StudentApi api(Future<http.Response> Function(http.Request) handler) =>
      StudentApi(
        baseUrl: 'http://localhost:8080',
        token: 'isolated-test-token',
        client: MockClient(handler),
      );

  Widget screen({
    required StudentApi Function() apiFactory,
    VoidCallback? expired,
    VoidCallback? onHome,
  }) => MaterialApp(
    home: Scaffold(
      body: StudentScheduleScreen(
        apiFactory: apiFactory,
        onUnauthorized: expired ?? () {},
        onHome: onHome ?? () {},
      ),
    ),
  );

  testWidgets('selecciona matrícula activa y presenta datos reales por día', (
    tester,
  ) async {
    final paths = <String>[];
    await tester.pumpWidget(
      screen(
        apiFactory: () => api((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/matriculas')) {
            return json([
              enrollmentFixture('2026', periodName: 'TEST_EST_a144bf99'),
            ]);
          }
          return json([
            scheduleFixture(),
            scheduleFixture(
              id: 602,
              weekday: 3,
              start: '10:00:00',
              end: '10:45:00',
              course: 'Arte',
              room: null,
            ),
          ]);
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(paths, [
      '/api/estudiante/matriculas',
      '/api/estudiante/matriculas/2026/horario',
    ]);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    expect(find.text('Año escolar: 2026'), findsOneWidget);
    expect(find.text('Secundaria · 1.º grado · Sección A'), findsOneWidget);
    expect(find.textContaining('TEST_EST'), findsNothing);
    expect(find.text('Lunes'), findsOneWidget);
    expect(find.text('08:00–08:45'), findsOneWidget);
    expect(find.text('Matemática'), findsOneWidget);
    expect(find.text('Docente: Docente asignado'), findsNWidgets(2));
    expect(find.text('Aula: Aula 1'), findsOneWidget);
    expect(find.text('Miércoles'), findsOneWidget);
    expect(find.text('10:00–10:45'), findsOneWidget);
    expect(find.text('Arte'), findsOneWidget);
    expect(find.textContaining('Aula:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lista vacía muestra estado vacío sin datos de ejemplo', (
    tester,
  ) async {
    await tester.pumpWidget(
      screen(
        apiFactory: () => api(
          (request) async => request.url.path.endsWith('/matriculas')
              ? json([enrollmentFixture('2026')])
              : json([]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Todavía no hay horarios registrados para esta matrícula.'),
      findsOneWidget,
    );
    expect(find.text('Matemática'), findsNothing);
    expect(find.text('Docente asignado'), findsNothing);
  });

  testWidgets('error de conexión permite reintentar el endpoint', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      screen(
        apiFactory: () => api((request) async {
          if (request.url.path.endsWith('/matriculas')) {
            return json([enrollmentFixture('2026')]);
          }
          if (++attempts == 1) {
            throw http.ClientException('internal test connection error');
          }
          return json([]);
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No se pudo conectar. Comprueba tu conexión e inténtalo nuevamente.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('internal test'), findsNothing);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(
      find.text('Todavía no hay horarios registrados para esta matrícula.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'sesión no autorizada notifica expiración y no ofrece reintento',
    (tester) async {
      var expired = 0;
      await tester.pumpWidget(
        screen(
          apiFactory: () => api((request) async {
            if (request.url.path.endsWith('/matriculas')) {
              return json([enrollmentFixture('2026')]);
            }
            return json({'private': 'body'}, 401);
          }),
          expired: () => expired++,
        ),
      );
      await tester.pumpAndSettle();
      expect(expired, 1);
      expect(
        find.text('Tu sesión ha vencido. Vuelve a iniciar sesión.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsNothing);
      expect(find.textContaining('body'), findsNothing);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1280, 900),
  ]) {
    testWidgets('horario semanal adaptable en $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        screen(
          apiFactory: () => api(
            (request) async => request.url.path.endsWith('/matriculas')
                ? json([enrollmentFixture('2026')])
                : json([scheduleFixture()]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lunes'), findsOneWidget);
      expect(find.text('Viernes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('rechaza día y hora fuera del contrato del endpoint', () {
    expect(
      () => StudentSchedule.fromJson(scheduleFixture(weekday: 6)),
      throwsFormatException,
    );
    expect(
      () => StudentSchedule.fromJson({
        ...scheduleFixture(),
        'horaInicio': '25:00:00',
      }),
      throwsFormatException,
    );
  });

  testWidgets('botón de regreso ejecuta la navegación al panel', (
    tester,
  ) async {
    var returned = false;
    await tester.pumpWidget(
      screen(
        apiFactory: () => api(
          (request) async => request.url.path.endsWith('/matriculas')
              ? json([enrollmentFixture('2026')])
              : json([]),
        ),
        onHome: () => returned = true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver al inicio del panel'));
    expect(returned, isTrue);
  });
}
