import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'submission_attachment.dart';
import 'student_attendance.dart';

enum StudentFailureKind {
  unauthorized,
  forbidden,
  missingProfile,
  unavailable,
  network,
  invalid,
  cancelled,
  duplicate,
  closed,
  validation,
  tooLarge,
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

  Uri _submissionUri(int enrollment, int task, {bool download = false}) {
    final base = Uri.tryParse(baseUrl);
    if (_closed) throw const StudentFailure(StudentFailureKind.cancelled);
    if (enrollment < 1 ||
        task < 1 ||
        base == null ||
        !['http', 'https'].contains(base.scheme) ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw const StudentFailure(StudentFailureKind.invalid);
    }
    return base.replace(
      path:
          '/api/estudiante/matriculas/$enrollment/tareas/$task/entrega${download ? '/archivo' : ''}',
    );
  }

  void _submissionStatus(http.Response response) {
    if (_closed) throw const StudentFailure(StudentFailureKind.cancelled);
    switch (response.statusCode) {
      case 200:
      case 201:
        return;
      case 401:
        throw const StudentFailure(StudentFailureKind.unauthorized);
      case 403:
        throw const StudentFailure(StudentFailureKind.forbidden);
      case 404:
        throw const StudentFailure(StudentFailureKind.unavailable);
      case 413:
        throw const StudentFailure(StudentFailureKind.tooLarge);
      case 400:
      case 415:
        throw const StudentFailure(StudentFailureKind.validation);
      case 409:
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        throw StudentFailure(
          body is Map && body['codigo'] == 'ENTREGA_DUPLICADA'
              ? StudentFailureKind.duplicate
              : StudentFailureKind.closed,
        );
      default:
        throw const StudentFailure(StudentFailureKind.invalid);
    }
  }

  Future<http.Response> _submissionRequest(http.BaseRequest request) async {
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    try {
      final response = await (() async => http.Response.fromStream(
        await _client.send(request),
      ))().timeout(timeout);
      _submissionStatus(response);
      return response;
    } on TimeoutException {
      throw const StudentFailure(StudentFailureKind.network);
    } on http.ClientException {
      throw const StudentFailure(StudentFailureKind.network);
    } on FormatException {
      throw const StudentFailure(StudentFailureKind.invalid);
    }
  }

  Future<Map<String, dynamic>> submitTask(
    int enrollment,
    int task,
    String comment, {
    SubmissionAttachment? attachment,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _submissionUri(enrollment, task),
    );
    if (comment.trim().isEmpty && attachment == null ||
        comment.runes.length > 10000 ||
        (attachment != null && !attachment.valid)) {
      throw const StudentFailure(StudentFailureKind.validation);
    }
    request.fields['comentario'] = comment;
    if (attachment != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'archivo',
          attachment.bytes,
          filename: 'entrega.${attachment.extension}',
          contentType: MediaType.parse(attachment.mimeType!),
        ),
      );
    }
    final response = await _submissionRequest(request);
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw const StudentFailure(StudentFailureKind.invalid);
    }
  }

  Future<Map<String, dynamic>> submission(int enrollment, int task) async {
    final response = await _submissionRequest(
      http.Request('GET', _submissionUri(enrollment, task)),
    );
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw const StudentFailure(StudentFailureKind.invalid);
    }
  }

  Future<SubmissionAttachment> submissionFile(int enrollment, int task) async {
    final response = await _submissionRequest(
      http.Request('GET', _submissionUri(enrollment, task, download: true)),
    );
    final type = response.headers['content-type']?.split(';').first.trim();
    final extension = submissionTypes.entries
        .where((e) => e.value == type)
        .firstOrNull
        ?.key;
    if (extension == null || response.bodyBytes.length > submissionMaxBytes) {
      throw const StudentFailure(StudentFailureKind.invalid);
    }
    return SubmissionAttachment(
      'entrega.$extension',
      Uint8List.fromList(response.bodyBytes),
    );
  }

  void dispose() {
    _closed = true;
    _client.close();
  }

  Future<Object?> get(
    String resource, {
    Map<String, String> query = const {},
  }) async {
    if (_closed) throw const StudentFailure(StudentFailureKind.cancelled);
    final base = Uri.tryParse(baseUrl);
    if ((!['perfil', 'matriculas'].contains(resource) &&
            !RegExp(r'^matriculas/[1-9][0-9]*/cursos(?:/[1-9][0-9]*)?$')
                .hasMatch(resource) &&
            !RegExp(
              r'^matriculas/[1-9][0-9]*/(?:(?:tareas|calificaciones|asistencias)(?:/[1-9][0-9]*)?|cursos/[1-9][0-9]*/(?:tareas|calificaciones|asistencias))$',
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
    if (query.isNotEmpty &&
        (!RegExp(
              r'^matriculas/[1-9][0-9]*/(?:cursos/[1-9][0-9]*/)?asistencias$',
            ).hasMatch(resource) ||
            query.entries.any(
              (entry) =>
                  !['desde', 'hasta'].contains(entry.key) ||
                  !validAttendanceDate(entry.value),
            ) ||
            (query.containsKey('desde') &&
                query.containsKey('hasta') &&
                query['desde']!.compareTo(query['hasta']!) > 0))) {
      throw const StudentFailure(StudentFailureKind.validation);
    }
    try {
      final response = await _client
          .get(
            base.replace(
              path: '/api/estudiante/$resource',
              queryParameters: query.isEmpty ? null : query,
            ),
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
          if (resource.contains('/cursos') ||
              resource.contains('/tareas') ||
              resource.contains('/calificaciones') ||
              resource.contains('/asistencias')) {
            final body = jsonDecode(utf8.decode(response.bodyBytes));
            if (body is Map && body['codigo'] == 'SIN_PERFIL') {
              throw const StudentFailure(StudentFailureKind.missingProfile);
            }
            throw const StudentFailure(StudentFailureKind.unavailable);
          }
          throw const StudentFailure(StudentFailureKind.missingProfile);
        case 200:
          return jsonDecode(utf8.decode(response.bodyBytes));
        case 400:
          if (resource.contains('/asistencias')) {
            throw const StudentFailure(StudentFailureKind.validation);
          }
          throw const StudentFailure(StudentFailureKind.invalid);
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
