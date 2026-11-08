import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/main.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/student_task.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';
import 'package:aplicativo_institucional/features/student/screens/student_submission_screen.dart';

import 'auth_test.dart' show responseFixture;
import 'institutional_test.dart' show openAccess, credentials;
import 'student_tasks_test.dart' show taskFixture;
import 'student_submission_test.dart' show deliveryFixture;

void main() {
  for (final existing in [false, true]) {
    testWidgets(
      'vencimiento elimina ${existing ? 'recibo privado' : 'respuesta sin enviar'} y rutas de entrega',
      (tester) async {
        final auth = AuthApi(
          baseUrl: 'http://localhost:8080',
          clientFactory: () => MockClient((_) async {
            final fixture = responseFixture();
            fixture['expiresAt'] = DateTime.now()
                .add(const Duration(seconds: 60))
                .toIso8601String();
            return http.Response(jsonEncode(fixture), 200);
          }),
        );
        final student = StudentApi(
          baseUrl: 'http://localhost:8080',
          token: 'isolated-test-token',
          client: MockClient(
            (_) async => http.Response(
              jsonEncode(deliveryFixture()),
              200,
              headers: {'content-type': 'application/json'},
            ),
          ),
        );
        addTearDown(student.dispose);
        await tester.pumpWidget(MyApp(authApi: auth));
        await openAccess(tester, 'Estudiante');
        await credentials(tester);
        final context = tester.element(find.byType(StudentPanel));
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StudentSubmissionScreen(
              api: student,
              enrollment: 102,
              task: StudentTask.fromJson(taskFixture(submitted: existing)),
              onUnauthorized: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (existing) {
          expect(find.text('Respuesta: Mi respuesta'), findsOneWidget);
        } else {
          await tester.enterText(
            find.byType(TextField),
            'respuesta-privada-de-prueba',
          );
          expect(find.text('respuesta-privada-de-prueba'), findsOneWidget);
        }
        await tester.pump(const Duration(seconds: 61));
        await tester.pumpAndSettle();
        expect(find.byType(StudentSubmissionScreen), findsNothing);
        expect(find.byType(StudentPanel), findsNothing);
        expect(find.text('Respuesta: Mi respuesta'), findsNothing);
        expect(find.text('respuesta-privada-de-prueba'), findsNothing);
        expect(find.text('¡Bienvenidos!'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(StudentSubmissionScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
