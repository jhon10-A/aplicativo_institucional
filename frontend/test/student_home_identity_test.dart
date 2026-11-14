import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';

import 'auth_test.dart' show responseFixture;
import 'student_profile_test.dart' show profileFixture, enrollmentFixture;

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Widget panel(
  Future<http.Response> Function(http.Request) handler, {
  VoidCallback? expired,
  TargetPlatform? platform,
}) => MaterialApp(
  theme: platform == null ? null : ThemeData(platform: platform),
  home: StudentPanel(
    session: Session.fromJson(responseFixture()),
    onLogout: expired ?? () {},
    studentApiFactory: () => StudentApi(
      baseUrl: 'http://localhost:8080',
      token: 'isolated-test-token',
      client: MockClient(handler),
    ),
  ),
);

void main() {
  for (final photo in [
    null,
    '',
    'http://example.com/foto.png',
    'https://example.com/no-existe.png',
  ]) {
    testWidgets(
      'Jhon usa avatar neutro si la foto no está disponible: $photo',
      (tester) async {
        tester.view.physicalSize = const Size(392, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          panel((request) async {
            if (request.url.path.endsWith('/perfil')) {
              return json({
                ...profileFixture(photoUrl: photo),
                'nombres': 'Jhon',
                'apellidos': 'Avalos',
                'codigoEstudiante': 'EST-0001',
              });
            }
            return json([]);
          }, platform: TargetPlatform.android),
        );
        await tester.pumpAndSettle();
        expect(find.text('Jhon Avalos'), findsOneWidget);
        final neutral = find.byKey(
          const ValueKey('student-home-neutral-avatar'),
        );
        expect(neutral, findsOneWidget);
        expect(tester.widget<Icon>(neutral).icon, Icons.person_outline_rounded);
        final circle = find
            .ancestor(of: neutral, matching: find.byType(ClipOval))
            .first;
        expect(tester.getSize(circle), const Size(56, 56));
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is AssetImage &&
                (w.image as AssetImage).assetName ==
                    'assets/student/avatar_ilustrado.png',
          ),
          findsNothing,
        );
        if (photo == null || !photo.startsWith('https://')) {
          expect(
            find.byKey(const ValueKey('student-home-photo')),
            findsNothing,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'cabecera muestra documento propio y grado sin inventar turno ni fila de periodo',
    (tester) async {
      await tester.pumpWidget(
        panel((request) async {
          expect(
            request.headers['Authorization'],
            'Bearer isolated-test-token',
          );
          if (request.url.path.endsWith('/perfil')) {
            return json({
              ...profileFixture(),
              'documentoIdentidad': '87654321',
            });
          }
          if (request.url.path.endsWith('/matriculas')) {
            return json([enrollmentFixture('2026')]);
          }
          return json([]);
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('DNI: 87654321'), findsOneWidget);
      expect(find.text('Primera Persona'), findsOneWidget);
      expect(find.text('Código: E1'), findsOneWidget);
      expect(find.text('Horario: sin registrar'), findsOneWidget);
      expect(find.text('Estudiante · Primero · Sección A'), findsOneWidget);
      expect(find.text('Usuario: prueba'), findsNothing);
      expect(find.text('Roles: ESTUDIANTE'), findsNothing);
      expect(find.text('Panel del estudiante'), findsNothing);
      expect(find.text('Periodo 2026'), findsNothing);
      expect(find.byTooltip('Actualizar resúmenes'), findsNothing);
      expect(find.textContaining('Mañana'), findsNothing);
    },
  );

  testWidgets(
    'inicio utiliza foto segura del perfil y conserva el avatar como respaldo',
    (tester) async {
      await tester.pumpWidget(
        panel((request) async {
          if (request.url.path.endsWith('/perfil')) {
            return json({
              ...profileFixture(photoUrl: 'https://example.com/foto.png'),
              'nombres': 'Jhon',
              'apellidos': 'Avalos',
            });
          }
          return json([]);
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jhon Avalos'), findsOneWidget);
      expect(find.text('Código: E1'), findsOneWidget);
      final image = tester.widget<Image>(
        find.byKey(const ValueKey('student-home-photo')),
      );
      expect(image.image, isA<NetworkImage>());
      expect((image.image as NetworkImage).url, 'https://example.com/foto.png');
      expect(image.errorBuilder, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DNI distingue carga, error y documento no registrado al reintentar',
    (tester) async {
      final pending = Completer<http.Response>();
      var calls = 0;
      await tester.pumpWidget(
        panel((request) async {
          if (request.url.path.endsWith('/perfil')) {
            return ++calls == 1 ? pending.future : json(profileFixture());
          }
          return json([]);
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('DNI: Cargando…'), findsOneWidget);
      pending.complete(json({'private': 'not shown'}, 503));
      await tester.pumpAndSettle();
      expect(find.text('DNI: No disponible'), findsOneWidget);
      expect(find.text('DNI: No registrado'), findsNothing);
      expect(find.textContaining('not shown'), findsNothing);
      await tester.tap(find.byTooltip('Reintentar perfil'));
      await tester.pumpAndSettle();
      expect(find.text('DNI: No registrado'), findsOneWidget);
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('perfil y resumen con sesión vencida notifican una sola vez', (
    tester,
  ) async {
    var expired = 0;
    await tester.pumpWidget(
      panel((_) async => json({}, 401), expired: () => expired++),
    );
    await tester.pumpAndSettle();
    expect(expired, 1);
    expect(find.textContaining('87654321'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
