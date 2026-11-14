import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';
import 'package:aplicativo_institucional/features/student/student_task.dart';
import 'package:aplicativo_institucional/features/student/submission_attachment.dart';
import 'package:aplicativo_institucional/features/student/screens/student_submission_screen.dart';
import 'package:aplicativo_institucional/features/student/screens/student_tasks_screen.dart';

import 'student_tasks_test.dart' show taskFixture;
import 'student_profile_test.dart' show enrollmentFixture;
import 'student_courses_test.dart' show courseFixture;

Map<String, Object?> deliveryFixture({bool file = false}) => {
  'id': 801,
  'comentario': 'Mi respuesta',
  'archivoUrl': file
      ? '/api/estudiante/matriculas/102/tareas/701/entrega/archivo'
      : null,
  'fechaEntrega': '2026-11-08T10:00:00',
  'estadoEntrega': 'ENTREGADA',
  'puntaje': null,
  'retroalimentacion': null,
  'fechaRevision': null,
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
  Widget screen(
    StudentApi client, {
    bool existing = false,
    Future<SubmissionAttachment?> Function()? pick,
    Future<bool> Function(SubmissionAttachment)? save,
    VoidCallback? expired,
  }) => MaterialApp(
    home: StudentSubmissionScreen(
      api: client,
      enrollment: 102,
      task: StudentTask.fromJson(taskFixture(submitted: existing)),
      onUnauthorized: expired ?? () {},
      pickFile: pick ?? () async => null,
      saveFile: save ?? (_) async => true,
    ),
  );
  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('Enviar entrega'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Confirmar envío'));
    await tester.pump();
  }

  testWidgets(
    'valida respuesta, confirma y bloquea pulsaciones repetidas hasta el exito',
    (tester) async {
      var posts = 0;
      final pending = Completer<http.Response>();
      final client = api((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer isolated-test-token');
        expect(
          request.url.path,
          '/api/estudiante/matriculas/102/tareas/701/entrega',
        );
        expect(
          request.headers['content-type'],
          contains('multipart/form-data'),
        );
        expect(request.body, contains('Mi respuesta'));
        posts++;
        return pending.future;
      });
      addTearDown(client.dispose);
      await tester.pumpWidget(screen(client));
      await tester.tap(find.text('Enviar entrega'));
      await tester.pump();
      expect(
        find.text('Escribe una respuesta o adjunta un archivo.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'Mi respuesta');
      final sendAction = tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Enviar entrega'),
          )
          .onPressed!;
      await tester.tap(find.text('Enviar entrega'));
      sendAction();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Confirmar envío'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(posts, 1);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final send = find.widgetWithText(FilledButton, 'Enviar entrega');
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      pending.complete(json(deliveryFixture(), 201));
      await tester.pumpAndSettle();
      expect(find.text('Entrega registrada correctamente.'), findsOneWidget);
      expect(find.text('Estado: Entregada'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(posts, 1);
    },
  );

  testWidgets('cancelar confirmacion no envia ni borra la respuesta', (
    tester,
  ) async {
    var calls = 0;
    final client = api((_) async {
      calls++;
      return json(deliveryFixture(), 201);
    });
    addTearDown(client.dispose);
    await tester.pumpWidget(screen(client));
    await tester.enterText(find.byType(TextField), 'Mi respuesta');
    await tester.tap(find.text('Enviar entrega'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Mi respuesta'), findsOneWidget);
  });

  testWidgets('selecciona un archivo y consulta su descarga autenticada', (
    tester,
  ) async {
    var posts = 0;
    var saves = 0;
    final bytes = Uint8List.fromList(utf8.encode('Respuesta de archivo'));
    final client = api((request) async {
      expect(request.headers['Authorization'], 'Bearer isolated-test-token');
      if (request.method == 'POST') {
        posts++;
        expect(request.body, contains('filename="entrega.txt"'));
        expect(
          request.body.toLowerCase(),
          contains('content-type: text/plain'),
        );
        return json(deliveryFixture(file: true), 201);
      }
      expect(request.url.path, endsWith('/entrega/archivo'));
      return http.Response.bytes(
        bytes,
        200,
        headers: {'content-type': 'text/plain'},
      );
    });
    addTearDown(client.dispose);
    await tester.pumpWidget(
      screen(
        client,
        pick: () async => SubmissionAttachment('respuesta.txt', bytes),
        save: (file) async {
          saves++;
          expect(file.bytes, bytes);
          expect(file.name, 'entrega.txt');
          return true;
        },
      ),
    );
    await tester.tap(find.text('Seleccionar archivo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Adjunto: respuesta.txt'), findsOneWidget);
    await confirm(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar mi archivo'));
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(saves, 1);
    expect(find.text('Archivo guardado.'), findsOneWidget);
  });

  for (final entry in {
    409: 'ENTREGA_DUPLICADA',
    400: 'ARCHIVO_INVALIDO',
    413: 'ARCHIVO_GRANDE',
    401: 'TOKEN',
    500: 'ERROR',
  }.entries) {
    testWidgets(
      'maneja HTTP ${entry.key} sin exponer el cuerpo y conserva respuesta',
      (tester) async {
        var expired = 0;
        final client = api(
          (_) async => json({
            'codigo': entry.value,
            'private': 'do not show',
          }, entry.key),
        );
        addTearDown(client.dispose);
        await tester.pumpWidget(screen(client, expired: () => expired++));
        await tester.enterText(find.byType(TextField), 'Mi respuesta');
        await confirm(tester);
        await tester.pumpAndSettle();
        expect(find.text('Entrega registrada correctamente.'), findsNothing);
        expect(find.textContaining('do not show'), findsNothing);
        expect(find.text('Mi respuesta'), findsOneWidget);
        expect(expired, entry.key == 401 ? 1 : 0);
      },
    );
  }

  testWidgets('plazo vencido y archivo invalido muestran validacion clara', (
    tester,
  ) async {
    final client = api((_) async => json({'codigo': 'FUERA_DE_PLAZO'}, 409));
    addTearDown(client.dispose);
    await tester.pumpWidget(
      screen(
        client,
        pick: () async => SubmissionAttachment('bad.exe', Uint8List(1)),
      ),
    );
    await tester.tap(find.text('Seleccionar archivo'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Comprueba la respuesta y el archivo'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'Mi respuesta');
    await confirm(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('El plazo o el estado de la tarea no permite entregas.'),
      findsOneWidget,
    );
  });

  testWidgets('consulta recibo existente y reintenta errores de red', (
    tester,
  ) async {
    var calls = 0;
    final client = api((request) async {
      expect(request.method, 'GET');
      if (++calls == 1) throw http.ClientException('private error');
      return json(deliveryFixture());
    });
    addTearDown(client.dispose);
    await tester.pumpWidget(screen(client, existing: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar consulta'));
    await tester.pumpAndSettle();
    expect(find.text('Respuesta: Mi respuesta'), findsOneWidget);
    expect(find.text('Enviar entrega'), findsNothing);
    expect(find.textContaining('private error'), findsNothing);
  });

  testWidgets('detalle de Tareas abre el formulario de entrega', (
    tester,
  ) async {
    final client = api((request) async {
      if (request.url.path.endsWith('/matriculas')) {
        return json([enrollmentFixture('2026')]);
      }
      if (request.url.path.endsWith('/cursos')) return json([courseFixture()]);
      if (request.url.path.endsWith('/701')) return json(taskFixture());
      return json([taskFixture()]);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentTasksScreen(
            apiFactory: () => client,
            onUnauthorized: () {},
            onHome: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The sole enrollment is selected automatically, so the task is ready.
    expect(find.text('Selecciona una matrícula'), findsNothing);
    await tester.tap(find.text('Álgebra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entregar tarea'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentSubmissionScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets(
      'formulario y recibo sin desbordamientos con texto ampliado $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = api((_) async => json(deliveryFixture(file: true)));
        addTearDown(client.dispose);
        Widget responsive({bool existing = false}) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: StudentSubmissionScreen(
            api: client,
            enrollment: 102,
            task: StudentTask.fromJson(taskFixture(submitted: existing)),
            onUnauthorized: () {},
          ),
        );
        await tester.pumpWidget(responsive());
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Enviar entrega'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(responsive(existing: true));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Guardar mi archivo'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('valida tamano y rutas de adjuntos antes de enviar', () async {
    expect(SubmissionAttachment('../.env', Uint8List(1)).valid, isFalse);
    expect(
      SubmissionAttachment(
        'large.txt',
        Uint8List(submissionMaxBytes + 1),
      ).valid,
      isFalse,
    );
    expect(SubmissionAttachment('empty.txt', Uint8List(0)).valid, isFalse);
    final client = api((_) async => throw StateError('No debe enviar'));
    addTearDown(client.dispose);
    await expectLater(
      client.submitTask(1, 1, ''),
      throwsA(isA<StudentFailure>()),
    );
    await expectLater(
      client.submitTask(0, 1, 'Respuesta'),
      throwsA(isA<StudentFailure>()),
    );
  });
}
