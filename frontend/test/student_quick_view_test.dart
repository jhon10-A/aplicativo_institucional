import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/screens/student_courses_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_grades_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_progress_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';
import 'package:aplicativo_institucional/features/student/screens/student_submission_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_tasks_screen.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/student_section.dart';
import 'package:aplicativo_institucional/features/student/widgets/student_quick_view.dart';

import 'auth_test.dart' show responseFixture;
import 'student_profile_test.dart' show enrollmentFixture;
import 'student_courses_test.dart' show courseFixture;
import 'student_tasks_test.dart' show taskFixture;
import 'student_grades_test.dart' show gradeFixture;
import 'student_attendance_test.dart' show attendanceFixture, pageFixture;

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
Map<String, Object?> futureTask() => {
  ...taskFixture(),
  'fechaLimite': '2099-12-31T12:00:00',
};
http.Response fixtureResponse(http.Request request) {
  expect(request.headers['Authorization'], 'Bearer isolated-test-token');
  final path = request.url.path;
  if (path.endsWith('/matriculas')) return json([enrollmentFixture('2026')]);
  if (path.endsWith('/cursos')) return json([courseFixture()]);
  if (path.endsWith('/cursos/501')) {
    return json(courseFixture(description: 'Descripción recibida'));
  }
  if (path.endsWith('/tareas')) return json([futureTask()]);
  if (path.endsWith('/tareas/701')) return json(futureTask());
  if (path.endsWith('/calificaciones')) return json([gradeFixture(note: 0)]);
  if (path.endsWith('/calificaciones/901')) return json(gradeFixture(note: 0));
  if (path.endsWith('/asistencias')) {
    return json(pageFixture([attendanceFixture()]));
  }
  if (path.endsWith('/asistencias/1001')) return json(attendanceFixture());
  return json([]);
}

Widget launcher({
  required StudentSection section,
  required StudentApi Function() factory,
  VoidCallback? expired,
  ValueChanged<int?>? selected,
  int? initial,
  double textScale = 1,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showStudentQuickView(
          context: context,
          section: section,
          apiFactory: factory,
          onUnauthorized: expired ?? () {},
          onEnrollmentChanged: selected ?? (_) {},
          enrollmentId: initial,
        ),
        child: const Text('Abrir'),
      ),
    ),
  ),
);
Finder inModal(Finder finder) =>
    find.descendant(of: find.byType(StudentQuickView), matching: finder);

void main() {
  testWidgets(
    'Mi Progreso informa ausencia de datos sin inventar indicadores',
    (tester) async {
      await tester.pumpWidget(
        launcher(
          section: StudentSection.progreso,
          factory: () => api(
            (r) async => r.url.path.endsWith('/matriculas')
                ? json([enrollmentFixture('2026')])
                : json([]),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(inModal(find.text('Mi Progreso')), findsOneWidget);
      expect(
        inModal(
          find.text(
            'Aún no hay calificaciones ni tareas registradas para mostrar tu seguimiento académico.',
          ),
        ),
        findsOneWidget,
      );
      expect(inModal(find.text('0.00')), findsNothing);
      expect(inModal(find.textContaining('%')), findsNothing);
      expect(inModal(find.textContaining('Promedio:')), findsNothing);
    },
  );

  testWidgets('Mi Progreso muestra estados reales y abre el detalle de tarea', (
    tester,
  ) async {
    final paths = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: StudentPanel(
          session: Session.fromJson(responseFixture()),
          onLogout: () {},
          studentApiFactory: () => api((r) async {
            paths.add(r.url.path);
            return fixtureResponse(r);
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('student-shortcut-asistencia')),
      findsNothing,
    );
    final card = find.byKey(const ValueKey('student-shortcut-progreso'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(StudentQuickView), findsNothing);
    expect(find.byType(StudentProgressScreen), findsOneWidget);
    expect(find.text('Año escolar: 2026'), findsOneWidget);
    expect(find.text('Secundaria · 1.º grado · Sección A'), findsOneWidget);
    expect(find.text('Matrícula: Activa'), findsOneWidget);
    expect(find.text('Pendientes: 1'), findsOneWidget);
    expect(find.text('Álgebra'), findsOneWidget);
    expect(find.text('Nota registrada'), findsNothing);
    await tester.ensureVisible(find.text('Álgebra'));
    await tester.tap(find.text('Álgebra'));
    await tester.pumpAndSettle();
    expect(paths, contains('/api/estudiante/matriculas/2026/tareas/701'));
    expect(find.text('Detalle de la tarea'), findsOneWidget);
  });

  final sections = {
    StudentSection.cursos: ('Matemática', '/cursos/501', 'Detalle del curso'),
    StudentSection.tareas: ('Álgebra', '/tareas/701', 'Detalle de la tarea'),
    StudentSection.calificaciones: (
      'Matemática',
      '/calificaciones/901',
      'Detalle de la calificación',
    ),
    StudentSection.progreso: (
      'Matemática',
      '/calificaciones/901',
      'Detalle de la calificación',
    ),
  };
  for (final entry in sections.entries) {
    testWidgets(
      '${entry.key.name}: abre, carga, cierra y navega al detalle real',
      (tester) async {
        final paths = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            home: StudentPanel(
              session: Session.fromJson(responseFixture()),
              onLogout: () {},
              studentApiFactory: () => api((request) async {
                paths.add(request.url.path);
                return fixtureResponse(request);
              }),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = find.byKey(ValueKey('student-shortcut-${entry.key.name}'));
        await tester.ensureVisible(card);
        await tester.tap(card);
        await tester.pumpAndSettle();
        if (entry.key == StudentSection.cursos) {
          expect(find.byType(StudentQuickView), findsNothing);
          expect(find.byType(StudentCoursesScreen), findsOneWidget);
          expect(find.text('Año escolar: 2026'), findsOneWidget);
          expect(paths, contains('/api/estudiante/matriculas/2026/cursos'));
          await tester.ensureVisible(find.text('Volver al inicio del panel'));
          await tester.tap(find.text('Volver al inicio del panel'));
          await tester.pumpAndSettle();
          expect(find.byType(StudentCoursesScreen), findsNothing);
          expect(find.text('Hola,'), findsOneWidget);
          expect(tester.takeException(), isNull);
          return;
        }
        if (entry.key == StudentSection.tareas) {
          expect(find.byType(StudentQuickView), findsNothing);
          expect(find.byType(StudentTasksScreen), findsOneWidget);
          expect(find.text('Año escolar: 2026'), findsOneWidget);
          expect(paths, contains('/api/estudiante/matriculas/2026/tareas'));
          await tester.tap(find.text(entry.value.$1));
          await tester.pumpAndSettle();
          expect(find.text(entry.value.$3), findsOneWidget);
          expect(
            paths,
            contains('/api/estudiante/matriculas/2026${entry.value.$2}'),
          );
          await tester.ensureVisible(find.text('Volver a tareas'));
          await tester.tap(find.text('Volver a tareas'));
          await tester.pumpAndSettle();
          expect(find.byType(StudentTasksScreen), findsOneWidget);
          await tester.ensureVisible(find.text('Volver al inicio del panel'));
          await tester.tap(find.text('Volver al inicio del panel'));
          await tester.pumpAndSettle();
          expect(find.byType(StudentTasksScreen), findsNothing);
          expect(find.text('Hola,'), findsOneWidget);
          expect(tester.takeException(), isNull);
          return;
        }
        if (entry.key == StudentSection.calificaciones) {
          expect(find.byType(StudentQuickView), findsNothing);
          expect(find.byType(StudentGradesScreen), findsOneWidget);
          expect(find.text('Año escolar: 2026'), findsOneWidget);
          expect(
            paths,
            contains('/api/estudiante/matriculas/2026/calificaciones'),
          );
          final exam = find.ancestor(
            of: find.text('Examen'),
            matching: find.byType(ListTile),
          );
          await tester.ensureVisible(exam);
          await tester.tap(exam);
          await tester.pumpAndSettle();
          expect(find.text(entry.value.$3), findsOneWidget);
          expect(
            paths,
            contains('/api/estudiante/matriculas/2026${entry.value.$2}'),
          );
          await tester.ensureVisible(find.text('Volver a calificaciones'));
          await tester.tap(find.text('Volver a calificaciones'));
          await tester.pumpAndSettle();
          expect(find.byType(StudentGradesScreen), findsOneWidget);
          await tester.ensureVisible(find.text('Volver al inicio del panel'));
          await tester.tap(find.text('Volver al inicio del panel'));
          await tester.pumpAndSettle();
          expect(find.byType(StudentGradesScreen), findsNothing);
          expect(find.text('Hola,'), findsOneWidget);
          expect(tester.takeException(), isNull);
          return;
        }
        if (entry.key == StudentSection.progreso) {
          expect(find.byType(StudentQuickView), findsNothing);
          expect(find.byType(StudentProgressScreen), findsOneWidget);
          expect(find.text('Año escolar: 2026'), findsOneWidget);
          expect(find.text('Pendientes: 1'), findsOneWidget);
          expect(find.text('Vencidas: 0'), findsOneWidget);
          expect(find.text('Calificaciones por curso'), findsOneWidget);
          expect(find.text('Examen'), findsOneWidget);
          final task = find.ancestor(
            of: find.text('Álgebra'),
            matching: find.byType(ListTile),
          );
          await tester.ensureVisible(task);
          await tester.tap(task);
          await tester.pumpAndSettle();
          expect(find.text('Detalle de la tarea'), findsOneWidget);
          expect(paths, contains('/api/estudiante/matriculas/2026/tareas/701'));
          await tester.ensureVisible(find.text('Volver a tareas'));
          await tester.tap(find.text('Volver a tareas'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Volver al inicio del panel'));
          await tester.tap(find.text('Volver al inicio del panel'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(card);
          await tester.tap(card);
          await tester.pumpAndSettle();
          final grade = find.ancestor(
            of: find.text('Examen'),
            matching: find.byType(ListTile),
          );
          await tester.ensureVisible(grade);
          await tester.tap(grade);
          await tester.pumpAndSettle();
          expect(find.text('Detalle de la calificación'), findsOneWidget);
          expect(
            paths,
            contains('/api/estudiante/matriculas/2026/calificaciones/901'),
          );
          await tester.ensureVisible(find.text('Volver al inicio del panel'));
          await tester.tap(find.text('Volver al inicio del panel'));
          await tester.pumpAndSettle();
          expect(find.byType(StudentProgressScreen), findsNothing);
          expect(find.text('Hola,'), findsOneWidget);
          expect(tester.takeException(), isNull);
          return;
        }
        expect(find.byType(StudentQuickView), findsOneWidget);
        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(inModal(find.text(entry.value.$1)), findsOneWidget);
        expect(inModal(find.text('Selecciona una matrícula')), findsNothing);
        expect(find.textContaining('Espacio de demostración'), findsNothing);
        if (entry.key == StudentSection.calificaciones) {
          expect(inModal(find.text('0.00')), findsOneWidget);
        }
        if (entry.key == StudentSection.asistencia) {
          expect(inModal(find.text('Presente: 1')), findsOneWidget);
        }
        await tester.tap(find.byTooltip('Cerrar vista rápida').first);
        await tester.pumpAndSettle();
        expect(find.byType(StudentQuickView), findsNothing);
        await tester.ensureVisible(card);
        await tester.tap(card);
        await tester.pumpAndSettle();
        await tester.ensureVisible(inModal(find.text(entry.value.$1)));
        await tester.tap(inModal(find.text(entry.value.$1)));
        await tester.pumpAndSettle();
        expect(find.byType(StudentQuickView), findsNothing);
        expect(
          paths,
          contains('/api/estudiante/matriculas/2026${entry.value.$2}'),
        );
        expect(find.text(entry.value.$3), findsOneWidget);
        if (entry.key == StudentSection.tareas) {
          await tester.ensureVisible(find.text('Entregar tarea'));
          await tester.tap(find.text('Entregar tarea'));
          await tester.pumpAndSettle();
          expect(find.byType(StudentSubmissionScreen), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('carga pendiente se puede cerrar y descarta respuestas tardías', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    await tester.pumpWidget(
      launcher(
        section: StudentSection.cursos,
        factory: () => api(
          (request) async => request.url.path.endsWith('/matriculas')
              ? json([enrollmentFixture('2026')])
              : pending.future,
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(inModal(find.byType(CircularProgressIndicator)), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar vista rápida').first);
    await tester.pump(const Duration(milliseconds: 250));
    pending.complete(json([courseFixture()]));
    await tester.pumpAndSettle();
    expect(find.byType(StudentQuickView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'error y reintento cargan datos; vacío no inventa calificaciones',
    (tester) async {
      var count = 0;
      await tester.pumpWidget(
        launcher(
          section: StudentSection.calificaciones,
          factory: () => api((request) async {
            if (request.url.path.endsWith('/matriculas')) {
              return json([enrollmentFixture('2026')]);
            }
            return ++count == 1
                ? json({'private': 'not displayed'}, 503)
                : json([]);
          }),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(inModal(find.text('Reintentar')), findsOneWidget);
      expect(find.textContaining('not displayed'), findsNothing);
      await tester.tap(inModal(find.text('Reintentar')));
      await tester.pumpAndSettle();
      expect(
        inModal(
          find.text('No hay calificaciones registradas para esta matrícula.'),
        ),
        findsOneWidget,
      );
      expect(inModal(find.text('0.00')), findsNothing);
    },
  );

  testWidgets('JWT vencido cierra modal y notifica sin dejar vistas privadas', (
    tester,
  ) async {
    var expired = 0;
    await tester.pumpWidget(
      launcher(
        section: StudentSection.cursos,
        expired: () => expired++,
        factory: () => api((r) async => json({}, 401)),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(expired, 1);
    expect(find.byType(StudentQuickView), findsNothing);
  });

  testWidgets(
    'matrícula recordada, cambio discreto y respuestas de otra selección descartadas',
    (tester) async {
      final oldResponse = Completer<http.Response>();
      final paths = <String>[];
      int? selected;
      await tester.pumpWidget(
        launcher(
          section: StudentSection.cursos,
          initial: 2025,
          selected: (id) => selected = id,
          factory: () => api((r) async {
            paths.add(r.url.path);
            if (r.url.path.endsWith('/matriculas')) {
              return json([
                enrollmentFixture('2026'),
                enrollmentFixture('2025'),
              ]);
            }
            return r.url.path.contains('/2025/')
                ? oldResponse.future
                : json([courseFixture()]);
          }),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(selected, 2025);
      // Loading prevents a second selection; closing must discard the pending response.
      await tester.tap(find.byTooltip('Cerrar vista rápida').first);
      await tester.pump(const Duration(milliseconds: 250));
      oldResponse.complete(json([courseFixture(period: '2025')]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cambiar matrícula en vista rápida'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026 · Primero · Sección A'));
      await tester.pumpAndSettle();
      expect(selected, 2026);
      expect(paths.last, '/api/estudiante/matriculas/2026/cursos');
      expect(inModal(find.text('Periodo 2026')), findsOneWidget);
    },
  );

  for (final size in [const Size(320, 568), const Size(1280, 900)]) {
    testWidgets('cuatro modales adaptables con texto ampliado $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final section in sections.keys) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(1.5),
            ),
            child: launcher(
              section: section,
              textScale: 1.5,
              factory: () => api((r) async => fixtureResponse(r)),
            ),
          ),
        );
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        expect(find.byType(StudentQuickView), findsOneWidget);
        expect(
          MediaQuery.textScalerOf(tester.element(find.byType(StudentQuickView)))
              .scale(1),
          1.5,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Cerrar vista rápida').first);
        await tester.pumpAndSettle();
        expect(find.byType(StudentQuickView), findsNothing);
      }
    });
  }
}
