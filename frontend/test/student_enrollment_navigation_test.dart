import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';
import 'package:aplicativo_institucional/features/student/screens/student_progress_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_tasks_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_grades_screen.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/student_profile.dart';
import 'package:aplicativo_institucional/features/student/student_enrollment_selection.dart';

import 'auth_test.dart' show responseFixture;
import 'student_profile_test.dart' show enrollmentFixture;
import 'student_tasks_test.dart' show taskFixture;
import 'student_grades_test.dart' show gradeFixture;

void main() {
  test(
    'recuerda solo IDs propios y no elige arbitrariamente entre varias activas',
    () {
      final a = StudentEnrollment.fromJson(enrollmentFixture('2026'));
      final b = StudentEnrollment.fromJson(enrollmentFixture('2025'));
      expect(resolveStudentEnrollment([a], null), a.id);
      expect(resolveStudentEnrollment([a], 999), a.id);
      expect(resolveStudentEnrollment([a, b], b.id), b.id);
      expect(resolveStudentEnrollment([a, b], null), isNull);
      expect(resolveStudentEnrollment([], a.id), isNull);
      final historical = enrollmentFixture('2025');
      historical['estado'] = 'FINALIZADA';
      expect(
        resolveStudentEnrollment([
          a,
          StudentEnrollment.fromJson(historical),
        ], null),
        a.id,
      );
    },
  );

  for (final multiple in [false, true]) {
    testWidgets(
      'tarjetas abren datos directamente y conservan contexto; varias=$multiple',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final paths = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            home: StudentPanel(
              session: Session.fromJson(responseFixture()),
              onLogout: () {},
              studentApiFactory: () => StudentApi(
                baseUrl: 'http://localhost:8080',
                token: 'isolated-test-token',
                client: MockClient((request) async {
                  expect(
                    request.headers['Authorization'],
                    'Bearer isolated-test-token',
                  );
                  paths.add(request.url.path);
                  final path = request.url.path;
                  final Object body = path.endsWith('/matriculas')
                      ? [
                          enrollmentFixture('2026'),
                          if (multiple) enrollmentFixture('2025'),
                        ]
                      : path.endsWith('/tareas/701')
                      ? taskFixture(deadline: '2099-12-31T12:00:00')
                      : path.endsWith('/tareas')
                      ? [
                          taskFixture(
                            title: 'Tarea pendiente',
                            deadline: '2099-12-31T12:00:00',
                          ),
                          taskFixture(
                            id: 702,
                            title: 'Tarea vencida',
                            deadline: '2026-04-10T18:00:00',
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
                        ]
                      : path.endsWith('/calificaciones/901')
                      ? gradeFixture()
                      : path.endsWith('/calificaciones')
                      ? [gradeFixture()]
                      : path.endsWith('/asistencias')
                      ? {
                          'registros': [],
                          'resumen': {
                            'total': 0,
                            'presente': 0,
                            'falta': 0,
                            'tardanza': 0,
                            'justificada': 0,
                          },
                        }
                      : [];
                  return http.Response(
                    jsonEncode(body),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8',
                    },
                  );
                }),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final cardStyles = {
          'cursos': (
            const Color(0xFF009CF5),
            Icons.menu_book_outlined,
            'Mis Cursos',
          ),
          'tareas': (
            const Color(0xFFA24BDE),
            Icons.assignment_turned_in_outlined,
            'Mis Tareas',
          ),
          'calificaciones': (
            const Color(0xFF27B541),
            Icons.description_outlined,
            'Mis Notas',
          ),
          'progreso': (
            const Color(0xFFFFA000),
            Icons.bar_chart_rounded,
            'Mi Progreso',
          ),
        };
        double? cardTop;
        double? previousLeft;
        for (final style in cardStyles.entries) {
          final card = find.byKey(ValueKey('student-shortcut-${style.key}'));
          final material = tester
              .element(card)
              .findAncestorWidgetOfExactType<Material>()!;
          expect(material.color, style.value.$1);
          expect(
            find.descendant(of: card, matching: find.byIcon(style.value.$2)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: card, matching: find.text(style.value.$3)),
            findsOneWidget,
          );
          final position = tester.getTopLeft(card);
          expect(position.dy, cardTop ?? position.dy);
          if (previousLeft != null) {
            expect(position.dx, greaterThan(previousLeft));
          }
          cardTop = position.dy;
          previousLeft = position.dx;
        }
        if (multiple) {
          await tester.ensureVisible(
            find.byTooltip('Seleccionar matrícula y periodo'),
          );
          await tester.tap(find.byTooltip('Seleccionar matrícula y periodo'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('2026 · Primero · Sección A'));
          await tester.pumpAndSettle();
        }
        var expectedPeriod = 2026;
        for (final entry in {
          'cursos': 'cursos',
          'tareas': 'tareas',
          'calificaciones': 'calificaciones',
          'progreso': 'calificaciones',
        }.entries) {
          paths.clear();
          await tester.ensureVisible(
            find.byKey(ValueKey('student-shortcut-${entry.key}')),
          );
          await tester.tap(
            find.byKey(ValueKey('student-shortcut-${entry.key}')),
          );
          await tester.pumpAndSettle();
          if (entry.key == 'cursos' ||
              entry.key == 'tareas' ||
              entry.key == 'calificaciones' ||
              entry.key == 'progreso') {
            expect(find.text('Año escolar: $expectedPeriod'), findsOneWidget);
            expect(find.text('Abrir pantalla completa'), findsNothing);
          }
          expect(find.text('Selecciona una matrícula'), findsNothing);
          expect(
            paths,
            contains(
              '/api/estudiante/matriculas/$expectedPeriod/${entry.value}',
            ),
          );
          if (multiple &&
              (entry.key == 'cursos' ||
                  entry.key == 'calificaciones' ||
                  entry.key == 'progreso')) {
            await tester.tap(find.byType(DropdownButtonFormField<int>).first);
            await tester.pumpAndSettle();
            await tester.tap(find.textContaining('2025 ·').last);
            await tester.pumpAndSettle();
            expect(
              paths,
              contains('/api/estudiante/matriculas/2025/${entry.value}'),
            );
            expectedPeriod = 2025;
          }
          if (entry.key == 'progreso') {
            expect(find.byType(StudentProgressScreen), findsOneWidget);
            expect(
              find.text('Secundaria · 1.º grado · Sección A'),
              findsOneWidget,
            );
            expect(find.text('Pendientes: 1'), findsOneWidget);
            expect(find.text('Entregadas: 1'), findsOneWidget);
            expect(find.text('Revisadas: 1'), findsOneWidget);
            expect(find.text('Vencidas: 1'), findsOneWidget);
            expect(find.text('Calificaciones por curso'), findsOneWidget);
            final task = find.ancestor(
              of: find.text('Tarea pendiente'),
              matching: find.byType(ListTile),
            );
            await tester.ensureVisible(task);
            await tester.tap(task);
            await tester.pumpAndSettle();
            expect(find.byType(StudentTasksScreen), findsOneWidget);
            expect(find.text('Detalle de la tarea'), findsOneWidget);
            expect(
              paths,
              contains('/api/estudiante/matriculas/$expectedPeriod/tareas/701'),
            );
            await tester.ensureVisible(find.text('Volver al inicio del panel'));
            await tester.tap(find.text('Volver al inicio del panel'));
            await tester.pumpAndSettle();
            await tester.ensureVisible(
              find.byKey(const ValueKey('student-shortcut-progreso')),
            );
            await tester.tap(
              find.byKey(const ValueKey('student-shortcut-progreso')),
            );
            await tester.pumpAndSettle();
            final grade = find.ancestor(
              of: find.text('Examen'),
              matching: find.byType(ListTile),
            );
            await tester.ensureVisible(grade);
            await tester.tap(grade);
            await tester.pumpAndSettle();
            expect(find.byType(StudentGradesScreen), findsOneWidget);
            expect(find.text('Detalle de la calificación'), findsOneWidget);
            expect(
              paths,
              contains(
                '/api/estudiante/matriculas/$expectedPeriod/calificaciones/901',
              ),
            );
            await tester.ensureVisible(find.text('Volver al inicio del panel'));
            await tester.tap(find.text('Volver al inicio del panel'));
            await tester.pumpAndSettle();
            expect(find.text('Hola,'), findsOneWidget);
            expect(tester.takeException(), isNull);
            continue;
          }
          if (entry.key == 'cursos' ||
              entry.key == 'tareas' ||
              entry.key == 'calificaciones') {
            await tester.ensureVisible(find.text('Volver al inicio del panel'));
            await tester.tap(find.text('Volver al inicio del panel'));
          } else {
            await tester.tap(
              find.byKey(const ValueKey('student-bottom-inicio')),
            );
          }
          await tester.pumpAndSettle();
          expect(find.text('Periodo $expectedPeriod'), findsNothing);
          expect(find.byTooltip('Actualizar resúmenes'), findsNothing);
          if (multiple) {
            expect(
              tester
                  .widget<PopupMenuButton<int>>(
                    find.byType(PopupMenuButton<int>),
                  )
                  .initialValue,
              expectedPeriod,
            );
          }
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
