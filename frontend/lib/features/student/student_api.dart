import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum StudentFailureKind {
  unauthorized,
  forbidden,
  missingProfile,
  unavailable,
  network,
  invalid,
  cancelled,
}

class StudentFailure implements Exception {
  const StudentFailure(this.kind);
  final StudentFailureKind kind;
  @override
  String toString() => 'StudentFailure(${kind.name})';
}

/// One instance per screen/session. Disposing discards outstanding responses.
class StudentApi {
  StudentApi({
    required this.baseUrl,
    required this.token,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String token;
  final http.Client _client;
  final Duration timeout;
  bool _closed = false;

  void dispose() {
    _closed = true;
    _client.close();
  }

  Future<Object?> get(String resource) async {
    if (_closed) throw const StudentFailure(StudentFailureKind.cancelled);
    final base = Uri.tryParse(baseUrl);
    if ((!['perfil', 'matriculas'].contains(resource) &&
            !RegExp(r'^matriculas/[1-9][0-9]*/cursos(?:/[1-9][0-9]*)?$')
                .hasMatch(resource) &&
            !RegExp(
              r'^matriculas/[1-9][0-9]*/(?:tareas(?:/[1-9][0-9]*)?|cursos/[1-9][0-9]*/tareas)$',
            ).hasMatch(resource)) ||
        base == null ||
        !['http', 'https'].contains(base.scheme) ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw const StudentFailure(StudentFailureKind.invalid);
    }
    try {
      final response = await _client
          .get(
            base.replace(path: '/api/estudiante/$resource'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
      if (_closed) throw const StudentFailure(StudentFailureKind.cancelled);
      switch (response.statusCode) {
        case 401:
          throw const StudentFailure(StudentFailureKind.unauthorized);
        case 403:
          throw const StudentFailure(StudentFailureKind.forbidden);
        case 404:
          if (resource.contains('/cursos') || resource.contains('/tareas')) {
            final body = jsonDecode(utf8.decode(response.bodyBytes));
            if (body is Map && body['codigo'] == 'SIN_PERFIL') {
              throw const StudentFailure(StudentFailureKind.missingProfile);
            }
            throw const StudentFailure(StudentFailureKind.unavailable);
          }
          throw const StudentFailure(StudentFailureKind.missingProfile);
        case 200:
          return jsonDecode(utf8.decode(response.bodyBytes));
        default:
          throw const StudentFailure(StudentFailureKind.invalid);
      }
    } on TimeoutException {
      throw StudentFailure(
        _closed ? StudentFailureKind.cancelled : StudentFailureKind.network,
      );
    } on http.ClientException {
      throw StudentFailure(
        _closed ? StudentFailureKind.cancelled : StudentFailureKind.network,
      );
    } on FormatException {
      throw const StudentFailure(StudentFailureKind.invalid);
    }
  }
}
