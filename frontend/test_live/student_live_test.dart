// Explicit opt-in: read-only Flutter widget/client tests against the live fixture.
// Does not create users, send deliveries or remove data. No secrets are embedded.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/screens/student_profile_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_courses_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_tasks_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_grades_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_attendance_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_notices_screen.dart';

IOClient realClient() {
  // Flutter's default widget binding stubs network requests. This opt-in suite
  // restores real IO only while constructing its own explicit loopback client.
  final previous = HttpOverrides.current;
  HttpOverrides.global = null;
  try {
    return IOClient(HttpClient());
  } finally {
    HttpOverrides.global = previous;
  }
}

void main() {
  final directory = Platform.environment['STUDENT_LIVE_DIR'];
  testWidgets('pantallas Estudiante con HTTP y MySQL reales autorizados', (
    tester,
  ) async {
    final credentials = jsonDecode(
      File('$directory/credentials.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final fixture = jsonDecode(
      File('$directory/fixture.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final base = credentials['baseUrl'] as String;
    expect(base, 'http://localhost:8081');
    final session = await tester.runAsync(
      () => AuthApi(baseUrl: base, clientFactory: realClient).login(
        credentials['usernameA'] as String,
        credentials['password'] as String,
      ),
    );
    expect(session!.roles, contains('ESTUDIANTE'));
    StudentApi factory() => StudentApi(
      baseUrl: base,
      token: session.accessToken,
      client: realClient(),
    );
    final enrollment = (fixture['enrollments'] as List).first as int;
    final task = (fixture['tasks'] as List).first as int;
    final marker = fixture['marker'] as String;
    final api = factory();
    try {
      await tester.runAsync(() async {
        final delivery = await api.submission(enrollment, task);
        expect(delivery['estadoEntrega'], 'ENTREGADA');
        final attachment = await api.submissionFile(enrollment, task);
        expect(utf8.decode(attachment.bytes), contains(marker));
        final other = (fixture['enrollments'] as List)[1];
        await expectLater(
          api.get('matriculas/$other/tareas'),
          throwsA(
            isA<StudentFailure>().having(
              (e) => e.kind,
              'kind',
              StudentFailureKind.unavailable,
            ),
          ),
        );
      });
    } finally {
      api.dispose();
    }
    Future<void> networkSettles() async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    void unauthorized() => fail('La sesion real fue rechazada');
    final screens = <Widget>[
      StudentProfileScreen(
        apiFactory: factory,
        onUnauthorized: unauthorized,
        onHome: () {},
      ),
      StudentCoursesScreen(
        apiFactory: factory,
        onUnauthorized: unauthorized,
        onHome: () {},
      ),
      StudentTasksScreen(
        apiFactory: factory,
        onUnauthorized: unauthorized,
        onHome: () {},
      ),
      StudentGradesScreen(
        apiFactory: factory,
        onUnauthorized: unauthorized,
        onHome: () {},
      ),
      StudentAttendanceScreen(
        apiFactory: factory,
        onUnauthorized: unauthorized,
        onHome: () {},
      ),
      StudentNoticesScreen(
        apiFactory: factory,
        onUnauthorized: unauthorized,
        onHome: () {},
      ),
    ];
    for (final screen in screens) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: screen)));
      await networkSettles();
      final selectors = find.byType(DropdownButtonFormField<int>);
      if (selectors.evaluate().isNotEmpty) {
        tester.widget<DropdownButtonFormField<int>>(selectors.first).onChanged!(
          enrollment,
        );
        await networkSettles();
      }
      expect(
        find.textContaining(marker),
        findsWidgets,
        reason: 'No se mostraron datos reales en ${screen.runtimeType}',
      );
      final tiles = find.byType(ListTile);
      if (screen is! StudentProfileScreen && tiles.evaluate().isNotEmpty) {
        await tester.ensureVisible(tiles.first);
        await tester.tap(tiles.first);
        await networkSettles();
        expect(find.textContaining(marker), findsWidgets);
      }
      await tester.pumpWidget(const SizedBox());
    }
  }, skip: directory == null);
}
