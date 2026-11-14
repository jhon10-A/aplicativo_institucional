import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/student_section.dart';
import 'package:aplicativo_institucional/features/student/widgets/student_home.dart';
import 'package:aplicativo_institucional/features/student/widgets/student_presentation.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';

import 'auth_test.dart' show responseFixture;
import 'student_profile_test.dart' show enrollmentFixture, profileFixture;
import 'student_courses_test.dart' show courseFixture;
import 'student_schedule_test.dart' show scheduleFixture;
import 'student_notices_test.dart' show noticeFixture;

http.Response json(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const longCourse =
    'Ciencia y Tecnología con indagación y resolución de problemas';
const longTeacher = 'María Alejandra Fernández de los Ríos y Salazar';
const longTask =
    'Informe de indagación científica con análisis de resultados y conclusiones';

Object fixture(String path) {
  if (path.endsWith('/perfil')) return profileFixture();
  if (path.endsWith('/matriculas')) return [enrollmentFixture('2026')];
  if (path.endsWith('/cursos')) {
    return [
      for (var i = 0; i < 6; i++)
        {
          ...courseFixture(),
          'asignacionId': 501 + i,
          'nombre': '$longCourse $i',
          'docente': longTeacher,
        },
    ];
  }
  if (path.endsWith('/tareas')) {
    return [
      for (var i = 0; i < 6; i++)
        {
          'titulo': '$longTask $i',
          'curso': longCourse,
          'fechaLimite': '2099-12-31T18:00:00',
          'estadoEntrega': 'PENDIENTE',
        },
    ];
  }
  if (path.endsWith('/horario')) {
    return [
      for (var day = 1; day <= 5; day++)
        for (var block = 0; block < 5; block++)
          scheduleFixture(
            id: day * 10 + block,
            weekday: day,
            start: ['08:00', '08:55', '10:15', '11:10', '12:05'][block],
            end: ['08:55', '09:50', '11:10', '12:05', '13:00'][block],
            course: longCourse,
            teacher: longTeacher,
            room: 'Aula de quinto de secundaria A',
          ),
    ];
  }
  if (path.endsWith('/comunicados')) {
    return [
      {...noticeFixture(), 'id': 90, 'titulo': 'TEST_EST_a144bf99 General'},
      {
        ...noticeFixture(),
        'id': 91,
        'titulo': 'Jornada de actividad física y hábitos saludables',
      },
      {
        ...noticeFixture(),
        'id': 92,
        'titulo': 'Evaluación de Matemática y resolución de problemas',
      },
    ];
  }
  return [];
}

StudentApi api(Future<http.Response> Function(http.Request) handler) =>
    StudentApi(
      baseUrl: 'http://localhost:8080',
      token: 'isolated-test-token',
      client: MockClient(handler),
    );

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.windows]) {
    for (final width in [320.0, 360.0, 392.0, 412.0, 768.0, 1024.0]) {
      for (final scale in [1.0, 1.3, 1.5]) {
        testWidgets(
          'inicio $platform con datos largos $width px escala $scale',
          (tester) async {
            tester.view.physicalSize = Size(width, 850);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final selected = <StudentSection>[];
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(platform: platform),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: StudentHome(
                    session: Session.fromJson(responseFixture()),
                    onSelect: selected.add,
                    onUnauthorized: () {},
                    clock: () => DateTime.utc(2026, 11, 13, 14, 30),
                    apiFactory: () =>
                        api((r) async => json(fixture(r.url.path))),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('Horario: 08:00–13:00'), findsOneWidget);
            expect(find.text('Hoy · Viernes 13/11'), findsOneWidget);
            expect(find.text('TEST_EST_a144bf99 General'), findsNothing);
            expect(find.text('1 curso más · Ver todos'), findsOneWidget);
            expect(find.text('3 tareas más · Ver todos'), findsOneWidget);
            final shortcuts = [
              for (final s in [
                StudentSection.cursos,
                StudentSection.tareas,
                StudentSection.calificaciones,
                StudentSection.progreso,
              ])
                find.byKey(ValueKey('student-shortcut-${s.name}')),
            ];
            final first = tester.getRect(shortcuts.first);
            for (final shortcut in shortcuts) {
              final rect = tester.getRect(shortcut);
              expect(rect.top, closeTo(first.top, 1));
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(width));
              expect(rect.height, greaterThanOrEqualTo(48));
            }
            final cards = find.byType(StudentPreviewCard);
            expect(cards, findsNWidgets(4));
            final courses = tester.getRect(
              find.widgetWithText(StudentPreviewCard, 'Mis cursos'),
            );
            final tasks = tester.getRect(
              find.widgetWithText(StudentPreviewCard, 'Próximas tareas'),
            );
            if (width < 672 || scale > 1.2) {
              expect(tasks.top, greaterThanOrEqualTo(courses.bottom));
              expect(tasks.width, closeTo(courses.width, 1));
            } else {
              expect(tasks.top, closeTo(courses.top, 1));
              expect(courses.right, lessThan(tasks.left));
            }
            for (var i = 0; i < 4; i++) {
              await tester.ensureVisible(cards.at(i));
              await tester.pumpAndSettle();
              final rect = tester.getRect(cards.at(i));
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(width));
              expect(tester.takeException(), isNull);
            }
            await tester.ensureVisible(
              find.widgetWithText(TextButton, 'Ver completo'),
            );
            await tester.tap(find.widgetWithText(TextButton, 'Ver completo'));
            expect(selected.last, StudentSection.horario);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'intervalo distingue carga, fallo y reintento sin duplicar consulta',
    (tester) async {
      final pending = Completer<http.Response>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentHome(
              session: Session.fromJson(responseFixture()),
              onSelect: (_) {},
              onUnauthorized: () {},
              apiFactory: () => api((r) async {
                if (r.url.path.endsWith('/horario')) {
                  calls++;
                  return calls == 1
                      ? pending.future
                      : json([scheduleFixture()]);
                }
                return json(fixture(r.url.path));
              }),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Horario: Cargando…'), findsOneWidget);
      pending.complete(json({}, 503));
      await tester.pumpAndSettle();
      expect(find.text('Horario: no disponible'), findsOneWidget);
      await tester.ensureVisible(find.text('Reintentar'));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Horario: 08:00–08:45'), findsOneWidget);
      expect(calls, 2);
      unawaited(tester.binding.reassembleApplication());
      await tester.pumpAndSettle();
      expect(find.text('Horario: 08:00–08:45'), findsOneWidget);
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cambiar matrícula limpia el intervalo y descarta respuestas anteriores',
    (tester) async {
      final old = Completer<http.Response>();
      StudentHome home(int id) => StudentHome(
        selectedEnrollmentId: id,
        session: Session.fromJson(responseFixture()),
        onSelect: (_) {},
        onUnauthorized: () {},
        apiFactory: () => api((r) async {
          if (r.url.path.endsWith('/matriculas')) {
            return json([enrollmentFixture('2026'), enrollmentFixture('2025')]);
          }
          if (r.url.path.endsWith('/2026/horario')) return old.future;
          if (r.url.path.endsWith('/2025/horario')) return json([]);
          return json(r.url.path.endsWith('/perfil') ? profileFixture() : []);
        }),
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: home(2026))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Horario: Cargando…'), findsOneWidget);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: home(2025))));
      await tester.pumpAndSettle();
      expect(find.text('Horario: sin registrar'), findsOneWidget);
      old.complete(json([scheduleFixture(start: '07:00', end: '12:00')]));
      await tester.pumpAndSettle();
      expect(find.text('Horario: 07:00–12:00'), findsNothing);
      expect(find.text('Horario: sin registrar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'intervalo anterior desaparece mientras carga la matrícula nueva',
    (tester) async {
      final pending = Completer<http.Response>();
      StudentHome home(int id) => StudentHome(
        selectedEnrollmentId: id,
        session: Session.fromJson(responseFixture()),
        onSelect: (_) {},
        onUnauthorized: () {},
        apiFactory: () => api((r) async {
          if (r.url.path.endsWith('/matriculas')) {
            return json([enrollmentFixture('2026'), enrollmentFixture('2025')]);
          }
          if (r.url.path.endsWith('/2025/horario')) return pending.future;
          if (r.url.path.endsWith('/2026/horario')) {
            return json([scheduleFixture(start: '08:00', end: '13:00')]);
          }
          return json(r.url.path.endsWith('/perfil') ? profileFixture() : []);
        }),
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: home(2026))));
      await tester.pumpAndSettle();
      expect(find.text('Horario: 08:00–13:00'), findsOneWidget);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: home(2025))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Horario: 08:00–13:00'), findsNothing);
      expect(find.text('Horario: Cargando…'), findsOneWidget);
      pending.complete(json([]));
      await tester.pumpAndSettle();
      expect(find.text('Horario: sin registrar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'histórico no aparece en inicio pero conserva acceso en Comunicados',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StudentPanel(
            session: Session.fromJson(responseFixture()),
            onLogout: () {},
            studentApiFactory: () =>
                api((r) async => json(fixture(r.url.path))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('TEST_EST_a144bf99 General'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('student-bottom-comunicados')),
      );
      await tester.pumpAndSettle();
      expect(find.text('TEST_EST_a144bf99 General'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
