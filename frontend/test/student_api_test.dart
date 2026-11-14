import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/features/student/student_api.dart';

void main() {
  StudentApi api(MockClient client, {Duration? timeout}) => StudentApi(
    baseUrl: 'http://localhost:8080',
    token: 'isolated-test-token',
    client: client,
    timeout: timeout ?? const Duration(seconds: 15),
  );
  Matcher failure(StudentFailureKind kind) =>
      isA<StudentFailure>().having((e) => e.kind, 'kind', kind);

  test('envia Bearer y no acepta identificadores de otros usuarios', () async {
    final client = api(
      MockClient((request) async {
        expect(request.url.path, '/api/estudiante/perfil');
        expect(request.url.query, isEmpty);
        expect(request.headers['Authorization'], 'Bearer isolated-test-token');
        return http.Response('{"id":1}', 200);
      }),
    );
    addTearDown(client.dispose);
    expect(await client.get('perfil'), {'id': 1});
    await expectLater(
      client.get('perfil/2'),
      throwsA(failure(StudentFailureKind.invalid)),
    );
  });
  for (final entry in {
    401: StudentFailureKind.unauthorized,
    403: StudentFailureKind.forbidden,
    404: StudentFailureKind.missingProfile,
    500: StudentFailureKind.invalid,
  }.entries) {
    test('clasifica HTTP ${entry.key} sin exponer el cuerpo', () async {
      final client = api(
        MockClient((_) async => http.Response('private body', entry.key)),
      );
      addTearDown(client.dispose);
      await expectLater(client.get('perfil'), throwsA(failure(entry.value)));
    });
  }
  test('maneja conexion y JSON invalido', () async {
    final disconnected = api(
      MockClient((_) async => throw http.ClientException('private detail')),
    );
    final invalid = api(MockClient((_) async => http.Response('{', 200)));
    addTearDown(disconnected.dispose);
    addTearDown(invalid.dispose);
    await expectLater(
      disconnected.get('perfil'),
      throwsA(failure(StudentFailureKind.network)),
    );
    await expectLater(
      invalid.get('perfil'),
      throwsA(failure(StudentFailureKind.invalid)),
    );
  });
  test('descarta respuestas al cerrar la pantalla', () async {
    final pending = Completer<http.Response>();
    final client = api(MockClient((_) => pending.future));
    final request = client.get('perfil');
    client.dispose();
    final assertion = expectLater(
      request,
      throwsA(failure(StudentFailureKind.cancelled)),
    );
    pending.complete(http.Response('{}', 200));
    await assertion;
  });
  test('descarta respuestas fuera del tiempo limite', () async {
    final pending = Completer<http.Response>();
    final client = api(
      MockClient((_) => pending.future),
      timeout: const Duration(milliseconds: 5),
    );
    addTearDown(client.dispose);
    await expectLater(
      client.get('perfil'),
      throwsA(failure(StudentFailureKind.network)),
    );
    pending.complete(http.Response('{}', 200));
  });
}
