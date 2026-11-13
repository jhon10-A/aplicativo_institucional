import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/screens/student_notices_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_panel.dart';

import 'auth_test.dart' show responseFixture;
import 'student_profile_test.dart' show enrollmentFixture;

Map<String, Object?> noticeFixture({bool specific = false}) => {
  'id': specific ? 3 : 1,
  'titulo': specific ? 'Comunicado de sección' : 'Comunicado general',
  'contenido': 'Contenido íntegro del comunicado.',
  'remitente': 'Remitente Prueba',
  'publicadoEn': '2026-11-01T09:00:00',
  'fechaVencimiento': specific ? '2026-12-01T18:00:00' : null,
  'rolDestino': specific ? 'ESTUDIANTE' : null,
  'seccionDestino': specific
      ? {'id': 1, 'nombre': 'A', 'grado': 'Primero', 'nivel': 'SECUNDARIA'}
      : null,
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
      body: StudentNoticesScreen(
        apiFactory: () => client,
        onUnauthorized: expired ?? () {},
        onHome: () {},
      ),
    ),
  );
  Future<void> select(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
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
    'carga generales, seleccion explicita de seccion y detalle con remitente y fechas',
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
            expect(request.url.query, isEmpty);
            if (request.url.path.endsWith('/matriculas')) return pending.future;
            if (request.url.path.endsWith('/3')) {
              return json(noticeFixture(specific: true));
            }
            if (request.url.path.contains('/matriculas/')) {
              return json([noticeFixture(), noticeFixture(specific: true)]);
            }
            return json([noticeFixture()]);
          }),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(
        json([enrollmentFixture('2026'), enrollmentFixture('2025')]),
      );
      await tester.pumpAndSettle();
      expect(paths, [
        '/api/estudiante/matriculas',
        '/api/estudiante/comunicados',
      ]);
      expect(find.text('Comunicado general'), findsOneWidget);
      expect(find.text('General (sin sección)'), findsOneWidget);
      expect(find.text('Destinatarios: Todos los roles'), findsOneWidget);
      await select(tester, '2026 ·');
      expect(paths.last, '/api/estudiante/matriculas/2026/comunicados');
      expect(find.text('Sección: SECUNDARIA Primero A'), findsOneWidget);
      expect(find.text('Destinatarios: Estudiantes'), findsOneWidget);
      await tap(tester, 'Comunicado de sección');
      expect(paths.last, '/api/estudiante/matriculas/2026/comunicados/3');
      expect(find.text('Detalle del comunicado'), findsOneWidget);
      expect(find.text('Contenido íntegro del comunicado.'), findsOneWidget);
      expect(find.text('Remitente: Remitente Prueba'), findsOneWidget);
      expect(find.text('Publicación: 01/11/2026 09:00'), findsOneWidget);
      expect(find.text('Vencimiento: 01/12/2026 18:00'), findsOneWidget);
      expect(find.textContaining('Periodo:'), findsNothing);
      await tap(tester, 'Volver a comunicados');
      expect(paths.last, '/api/estudiante/matriculas/2026/comunicados');
      await select(tester, '2025 ·');
      expect(paths.last, '/api/estudiante/matriculas/2025/comunicados');
      await select(tester, 'Generales (sin sección)');
      expect(paths.last, '/api/estudiante/comunicados');
      expect(find.textContaining('isolated-test-token'), findsNothing);
    },
  );

  testWidgets('los generales estan disponibles sin perfil o matriculas', (
    tester,
  ) async {
    await tester.pumpWidget(
      screen(
        api((request) async {
          if (request.url.path.endsWith('/matriculas')) {
            return json({'codigo': 'SIN_PERFIL'}, 404);
          }
          return json([noticeFixture()]);
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Comunicado general'), findsOneWidget);
    expect(
      find.text('No tienes un perfil de estudiante registrado.'),
      findsNothing,
    );
    expect(find.text('Generales (sin sección)'), findsOneWidget);
  });

  testWidgets('lista vacia y sin vencimiento no crean estados ni fechas', (
    tester,
  ) async {
    var empty = true;
    await tester.pumpWidget(
      screen(
        api((request) async {
          if (request.url.path.endsWith('/matriculas')) return json([]);
          if (request.url.path.endsWith('/1')) return json(noticeFixture());
          return json(empty ? [] : [noticeFixture()]);
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No hay comunicados disponibles para esta selección.'),
      findsOneWidget,
    );
    empty = false;
    await select(tester, 'Generales (sin sección)');
    await tap(tester, 'Comunicado general');
    expect(find.textContaining('Vencimiento:'), findsNothing);
    expect(find.textContaining('Leído'), findsNothing);
  });

  testWidgets('errores de lista y detalle reintentan sin contenido anterior', (
    tester,
  ) async {
    var lists = 0;
    var details = 0;
    await tester.pumpWidget(
      screen(
        api((request) async {
          if (request.url.path.endsWith('/matriculas')) return json([]);
          if (request.url.path.endsWith('/1')) {
            if (++details == 1) return json({'codigo': 'NO_DISPONIBLE'}, 404);
            return json(noticeFixture());
          }
          if (++lists == 1) throw http.ClientException('private detail');
          return json([noticeFixture()]);
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudo conectar. Comprueba tu conexión.'),
      findsOneWidget,
    );
    await tap(tester, 'Reintentar');
    await tap(tester, 'Comunicado general');
    expect(
      find.text('La matrícula o el comunicado no está disponible.'),
      findsOneWidget,
    );
    expect(find.text('Comunicado general'), findsNothing);
    await tap(tester, 'Reintentar');
    expect(find.text('Contenido íntegro del comunicado.'), findsOneWidget);
    expect(find.textContaining('private detail'), findsNothing);
  });

  for (final status in [401, 403, 404, 500]) {
    testWidgets('gestiona HTTP $status sin exponer cuerpos internos', (
      tester,
    ) async {
      var expired = 0;
      await tester.pumpWidget(
        screen(
          api(
            (_) async => json({
              'codigo': 'NO_DISPONIBLE',
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

  testWidgets('descarta peticiones al salir', (tester) async {
    final pending = Completer<http.Response>();
    await tester.pumpWidget(screen(api((_) => pending.future)));
    await tester.pumpWidget(const SizedBox());
    pending.complete(json([]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('panel abre Comunicados funcional y vuelve al inicio', (
    tester,
  ) async {
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
      find.byKey(const ValueKey('student-bottom-comunicados')),
    );
    expect(find.text('Notificaciones'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('student-bottom-comunicados')));
    await tester.pumpAndSettle();
    expect(find.byType(StudentNoticesScreen), findsOneWidget);
    await tap(tester, 'Volver al inicio del panel');
    expect(find.text('Hola,'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets('comunicados y detalle con texto ampliado $size', (
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
        if (request.url.path.endsWith('/1')) return json(noticeFixture());
        return json([noticeFixture()]);
      });
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: StudentNoticesScreen(
              apiFactory: () => client,
              onUnauthorized: () {},
              onHome: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tap(tester, 'Comunicado general');
      expect(find.text('Detalle del comunicado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'cliente limita rutas y no admite filtros de usuarios o secciones',
    () async {
      final client = api((request) async {
        expect(request.headers['Authorization'], 'Bearer isolated-test-token');
        return json({'codigo': 'NO_DISPONIBLE'}, 404);
      });
      addTearDown(client.dispose);
      for (final route in [
        'comunicados',
        'comunicados/1',
        'matriculas/102/comunicados',
        'matriculas/102/comunicados/3',
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
        'comunicados?usuarioId=2',
        'comunicados/../2',
        'matriculas/0/comunicados',
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
      await expectLater(
        client.get('comunicados', query: {'seccionId': '2'}),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            StudentFailureKind.validation,
          ),
        ),
      );
    },
  );
}
