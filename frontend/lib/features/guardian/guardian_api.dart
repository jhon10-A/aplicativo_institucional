import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'guardian_child.dart';

enum GuardianFailureKind {
  unauthorized,
  forbidden,
  unavailable,
  network,
  invalid,
}

class GuardianFailure implements Exception {
  const GuardianFailure(this.kind);
  final GuardianFailureKind kind;

  /// Mensaje listo para mostrar al usuario.
  String get message => switch (kind) {
    GuardianFailureKind.unauthorized =>
      'Tu sesión venció. Cierra sesión e ingresa de nuevo.',
    GuardianFailureKind.forbidden =>
      'Tu cuenta no tiene un perfil de apoderado registrado.',
    GuardianFailureKind.unavailable => 'La información no está disponible.',
    GuardianFailureKind.network =>
      'No se pudo conectar con el servidor. Revisa que el backend esté activo.',
    GuardianFailureKind.invalid =>
      'El servidor devolvió una respuesta no válida.',
  };

  @override
  String toString() => 'GuardianFailure(${kind.name})';
}

/// Una instancia por sesión del panel. Todas las rutas son /api/apoderado/...
class GuardianApi {
  GuardianApi({
    required this.baseUrl,
    required this.token,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String token;
  final Duration timeout;
  final http.Client _client;

  Uri _uri(String path) {
    final base = Uri.tryParse(baseUrl);
    if (base == null ||
        !['http', 'https'].contains(base.scheme) ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw const GuardianFailure(GuardianFailureKind.invalid);
    }
    return base.replace(path: path);
  }

  Future<dynamic> _get(String path) async {
    final uri = _uri(path);
    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
      switch (response.statusCode) {
        case 200:
          return jsonDecode(utf8.decode(response.bodyBytes));
        case 401:
          throw const GuardianFailure(GuardianFailureKind.unauthorized);
        case 403:
          throw const GuardianFailure(GuardianFailureKind.forbidden);
        case 404:
          throw const GuardianFailure(GuardianFailureKind.unavailable);
        default:
          throw const GuardianFailure(GuardianFailureKind.invalid);
      }
    } on TimeoutException {
      throw const GuardianFailure(GuardianFailureKind.network);
    } on http.ClientException {
      throw const GuardianFailure(GuardianFailureKind.network);
    } on FormatException {
      throw const GuardianFailure(GuardianFailureKind.invalid);
    }
  }

  Future<List<GuardianChild>> children() async {
    final body = await _get('/api/apoderado/hijos');
    if (body is! List) throw const GuardianFailure(GuardianFailureKind.invalid);
    try {
      return body
          .map((e) => GuardianChild.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on TypeError {
      throw const GuardianFailure(GuardianFailureKind.invalid);
    }
  }

  void close() => _client.close();
}
