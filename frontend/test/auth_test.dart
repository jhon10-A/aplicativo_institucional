import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplicativo_institucional/auth.dart';

Map<String, Object> responseFixture() => {
  'accessToken': 'isolated-test-token',
  'tokenType': 'Bearer',
  'expiresAt': DateTime.now()
      .add(const Duration(hours: 1))
      .toUtc()
      .toIso8601String(),
  'usuario': {
    'id': 7,
    'nombreUsuario': 'prueba',
    'nombres': 'Nombre de prueba',
    'apellidos': 'Apellido de prueba',
    'roles': ['ESTUDIANTE'],
  },
};

void main() {
  test('envía el contrato JSON y lee la sesión real de la respuesta', () async {
    final api = AuthApi(
      baseUrl: 'http://localhost:8080/',
      clientFactory: () => MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://localhost:8080/api/auth/login');
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), {
          'nombreUsuario': 'prueba',
          'password': 'solo-test',
        });
        return http.Response(jsonEncode(responseFixture()), 200);
      }),
    );
    final session = await api.login('prueba', 'solo-test');
    expect(session.id, 7);
    expect(session.nombres, 'Nombre de prueba');
    expect(session.roles, ['ESTUDIANTE']);
    expect(session.accessToken.isNotEmpty, isTrue);
  });

  for (final status in [400, 401, 500]) {
    test('maneja HTTP $status sin mostrar el cuerpo del servidor', () async {
      final api = AuthApi(
        baseUrl: 'http://localhost:8080',
        clientFactory: () => MockClient(
          (_) async => http.Response('sensitive-server-body', status),
        ),
      );
      await expectLater(
        api.login('prueba', 'solo-test'),
        throwsA(
          isA<LoginFailure>().having(
            (error) => error.message.contains('sensitive-server-body'),
            'cuerpo no expuesto',
            false,
          ),
        ),
      );
    });
  }

  test('error de conexión', () async {
    final api = AuthApi(
      baseUrl: 'http://localhost:8080',
      clientFactory: () => MockClient(
        (_) async => throw http.ClientException('internal detail'),
      ),
    );
    await expectLater(
      api.login('prueba', 'solo-test'),
      throwsA(
        isA<LoginFailure>().having(
          (error) => error.message,
          'mensaje',
          contains('No se pudo conectar'),
        ),
      ),
    );
  });

  test('tiempo de espera', () async {
    final api = AuthApi(
      baseUrl: 'http://localhost:8080',
      timeout: const Duration(milliseconds: 1),
      clientFactory: () => MockClient((_) => Completer<http.Response>().future),
    );
    await expectLater(
      api.login('prueba', 'solo-test'),
      throwsA(
        isA<LoginFailure>().having(
          (error) => error.message,
          'mensaje',
          contains('tardó demasiado'),
        ),
      ),
    );
  });

  test('no usa un servidor predeterminado si falta la configuración', () async {
    final api = AuthApi(baseUrl: '');
    await expectLater(
      api.login('prueba', 'solo-test'),
      throwsA(isA<LoginFailure>()),
    );
  });

  test('rechaza respuesta malformada o vencida', () async {
    final expired = responseFixture();
    expired['expiresAt'] = DateTime.now()
        .subtract(const Duration(hours: 1))
        .toUtc()
        .toIso8601String();
    for (final body in ['not-json', '{}', jsonEncode(expired)]) {
      final api = AuthApi(
        baseUrl: 'http://localhost:8080',
        clientFactory: () => MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        api.login('prueba', 'solo-test'),
        throwsA(isA<LoginFailure>()),
      );
    }
  });
}
