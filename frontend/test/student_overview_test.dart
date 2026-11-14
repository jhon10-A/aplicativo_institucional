import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';
import 'package:aplicativo_institucional/features/student/screens/student_schedule_screen.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/widgets/student_overview.dart';

import 'auth_test.dart' show responseFixture;
import 'student_profile_test.dart' show enrollmentFixture;
import 'student_courses_test.dart' show courseFixture;
import 'student_notices_test.dart' show noticeFixture;
import 'student_schedule_test.dart' show scheduleFixture;

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
StudentApi client(Future<http.Response> Function(http.Request) handler) =>
    StudentApi(
      baseUrl: 'http://localhost:8080',
      token: 'isolated-test-token',
      client: MockClient(handler),
    );

void main() {
  testWidgets('resumen conserva matrícula al navegar y no inventa horarios', (
    tester,
  ) async {
    final requested = <String>[];
    final session = Session.fromJson(responseFixture());
    await tester.pumpWidget(
      MaterialApp(
        home: StudentPanel(
          session: session,
          onLogout: () {},
          studentApiFactory: () => client((request) async {
            expect(
              request.headers['Authorization'],
              'Bearer isolated-test-token',
            );
            requested.add(request.url.path);
            if (request.url.path.endsWith('/matriculas')) {
              return json([
                enrollmentFixture('2026'),
                enrollmentFixture('2025'),
              ]);
            }
            if (request.url.path.endsWith('/cursos')) {
              return json([courseFixture()]);
            }
            if (request.url.path.endsWith('/tareas')) {
              return json([
                {
                  'titulo': 'Actividad pendiente',
                  'curso': 'Curso recibido',
                  'fechaLimite': '2099-12-31T12:00:00',
                  'estadoEntrega': 'PENDIENTE',
                },
                {
                  'titulo': 'Actividad ya entregada',
                  'curso': 'Curso recibido',
                  'fechaLimite': '2099-12-31T12:00:00',
                  'estadoEntrega': 'ENTREGADA',
                },
              ]);
            }
            if (request.url.path.endsWith('/comunicados')) {
              return json([noticeFixture()]);
            }
            if (request.url.path.endsWith('/horario')) {
              return json([
                scheduleFixture(
                  course: 'Curso recibido del horario',
                  teacher: 'Docente recibido del horario',
                  start: '08:00:00',
                  end: '08:45:00',
                ),
              ]);
            }
            return json([]);
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requested.any((path) => path.contains('/2026/')), isFalse);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    await tester.ensureVisible(
      find.byTooltip('Seleccionar matrícula y periodo'),
    );
    await tester.tap(find.byTooltip('Seleccionar matrícula y periodo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026 · Primero · Sección A'));
    await tester.pumpAndSettle();
    expect(requested, contains('/api/estudiante/matriculas/2026/cursos'));
    expect(find.text('Actividad pendiente'), findsOneWidget);
    expect(find.text('Actividad ya entregada'), findsNothing);
    expect(
      find.textContaining('Estudiante · Primero · Sección A'),
      findsOneWidget,
    );
    expect(find.text('Mi Horario de Clases'), findsOneWidget);
    expect(requested, contains('/api/estudiante/matriculas/2026/horario'));
    expect(find.text('Lun 08:00\n08:45'), findsOneWidget);
    expect(find.text('Curso recibido del horario'), findsOneWidget);
    final openSchedule = find.widgetWithText(TextButton, 'Ver completo');
    expect(tester.widget<TextButton>(openSchedule).onPressed, isNotNull);
    await tester.ensureVisible(openSchedule);
    await tester.tap(openSchedule);
    await tester.pumpAndSettle();
    expect(find.byType(StudentScheduleScreen), findsOneWidget);
    expect(find.text('Año escolar: 2026'), findsOneWidget);
    expect(find.text('Docente: Docente recibido del horario'), findsOneWidget);
    await tester.ensureVisible(find.text('Volver al inicio del panel'));
    await tester.tap(find.text('Volver al inicio del panel'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentScheduleScreen), findsNothing);
    expect(find.text('Mi asistencia'), findsNothing);
    expect(find.text('07:30'), findsNothing);
    expect(find.text('Recreo'), findsNothing);
    expect(find.byType(Drawer), findsNothing);
    await tester.tap(find.byKey(const ValueKey('student-bottom-comunicados')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('student-bottom-inicio')));
    await tester.pumpAndSettle();
    expect(find.text('Periodo 2026'), findsNothing);
    expect(
      tester
          .widget<PopupMenuButton<int>>(find.byType(PopupMenuButton<int>))
          .initialValue,
      2026,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'carga, error y reintento del resumen no sustituyen datos reales',
    (tester) async {
      final pending = Completer<http.Response>();
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudentOverview(
                onSelect: (_) {},
                onUnauthorized: () {},
                apiFactory: () => client((request) async {
                  if (request.url.path.endsWith('/matriculas')) {
                    return json([enrollmentFixture('2026')]);
                  }
                  if (request.url.path.endsWith('/asistencias')) {
                    return json({
                      'registros': [],
                      'resumen': {
                        'total': 0,
                        'presente': 0,
                        'falta': 0,
                        'tardanza': 0,
                        'justificada': 0,
                      },
                    });
                  }
                  if (request.url.path.endsWith('/cursos')) {
                    attempts++;
                    return attempts == 1
                        ? pending.future
                        : json([courseFixture()]);
                  }
                  return json([]);
                }),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      pending.complete(json({}, 503));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo cargar esta información.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Matemática'), findsOneWidget);
      expect(find.text('No hay comunicados disponibles.'), findsOneWidget);
      expect(attempts, 2);
    },
  );

  testWidgets(
    'un JWT vencido cierra sesión una sola vez y descarta respuestas',
    (tester) async {
      var expired = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudentOverview(
                onSelect: (_) {},
                onUnauthorized: () => expired++,
                apiFactory: () => client(
                  (r) async => r.url.path.endsWith('/matriculas')
                      ? json([enrollmentFixture('2026')])
                      : json({}, 401),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(expired, 1);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
