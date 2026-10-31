import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class LoginFailure implements Exception {
  const LoginFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class Session {
  Session(
    this.accessToken,
    this.expiresAt,
    this.id,
    this.nombreUsuario,
    this.nombres,
    this.apellidos,
    this.roles,
  );
  final String accessToken;
  final DateTime expiresAt;
  final int id;
  final String nombreUsuario;
  final String nombres;
  final String apellidos;
  final List<String> roles;

  factory Session.fromJson(Map<String, dynamic> json) {
    final user = json['usuario'] as Map<String, dynamic>;
    final token = json['accessToken'] as String;
    final expiration = DateTime.parse(json['expiresAt'] as String);
    if (token.isEmpty ||
        json['tokenType'] != 'Bearer' ||
        !expiration.isAfter(DateTime.now())) {
      throw const FormatException('Invalid session');
    }
    return Session(
      token,
      expiration,
      user['id'] as int,
      user['nombreUsuario'] as String,
      user['nombres'] as String,
      user['apellidos'] as String,
      List<String>.unmodifiable(user['roles'] as List),
    );
  }
}

class AuthApi {
  AuthApi({
    String? baseUrl,
    http.Client Function()? clientFactory,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL'),
       _clientFactory = clientFactory ?? http.Client.new;

  final String baseUrl;
  final Duration timeout;
  final http.Client Function() _clientFactory;

  Uri _loginUri() {
    final base = Uri.tryParse(baseUrl);
    if (base == null ||
        !['http', 'https'].contains(base.scheme) ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw const LoginFailure(
        'Configura API_BASE_URL con la URL del backend.',
      );
    }
    return base.replace(path: '/api/auth/login');
  }

  Future<Session> login(String username, String password) async {
    final uri = _loginUri();
    final client = _clientFactory();
    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'nombreUsuario': username, 'password': password}),
          )
          .timeout(timeout);
      if (response.statusCode == 401) {
        throw const LoginFailure(
          'Credenciales incorrectas o usuario inactivo.',
        );
      }
      if (response.statusCode == 400) {
        throw const LoginFailure(
          'Datos inválidos. Revisa el usuario y la contraseña.',
        );
      }
      if (response.statusCode != 200) {
        throw const LoginFailure(
          'No se pudo iniciar sesión. Inténtalo más tarde.',
        );
      }
      try {
        return Session.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
      } catch (_) {
        throw const LoginFailure(
          'El servidor devolvió una respuesta no válida.',
        );
      }
    } on TimeoutException {
      throw const LoginFailure(
        'El servidor tardó demasiado. Inténtalo nuevamente.',
      );
    } on http.ClientException {
      throw const LoginFailure(
        'No se pudo conectar. Revisa la red, la URL y CORS si usas Chrome.',
      );
    } finally {
      client.close();
    }
  }
}
