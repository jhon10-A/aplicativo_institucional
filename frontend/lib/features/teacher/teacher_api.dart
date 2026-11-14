import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'teacher_assignment.dart';
import 'teacher_profile.dart';

enum TeacherFailureKind { unauthorized, forbidden, notFound, validation, network, invalid, cancelled }

class TeacherFailure implements Exception {
  const TeacherFailure(this.kind);
  final TeacherFailureKind kind;
  @override
  String toString() => 'TeacherFailure(${kind.name})';
}

class TeacherApi {
  TeacherApi({
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

  Uri _uri(String path) {
    if (_closed) throw const TeacherFailure(TeacherFailureKind.cancelled);
    final base = Uri.tryParse(baseUrl);
    if (base == null || base.host.isEmpty) {
      throw const TeacherFailure(TeacherFailureKind.invalid);
    }
    return base.replace(path: '/api/docentes$path');
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  void _checkStatus(http.Response response) {
    if (_closed) throw const TeacherFailure(TeacherFailureKind.cancelled);
    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        return;
      case 400:
        throw const TeacherFailure(TeacherFailureKind.validation);
      case 401:
        throw const TeacherFailure(TeacherFailureKind.unauthorized);
      case 403:
        throw const TeacherFailure(TeacherFailureKind.forbidden);
      case 404:
        throw const TeacherFailure(TeacherFailureKind.notFound);
      default:
        throw const TeacherFailure(TeacherFailureKind.invalid);
    }
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on TimeoutException {
      throw TeacherFailure(_closed ? TeacherFailureKind.cancelled : TeacherFailureKind.network);
    } on http.ClientException {
      throw TeacherFailure(_closed ? TeacherFailureKind.cancelled : TeacherFailureKind.network);
    } on FormatException {
      throw const TeacherFailure(TeacherFailureKind.invalid);
    }
  }

  Future<TeacherProfile> getPerfil() => _run(() async {
        final response = await _client.get(_uri('/perfil'), headers: _headers).timeout(timeout);
        _checkStatus(response);
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return TeacherProfile.fromJson(data);
      });

  Future<List<TeacherAssignment>> getAsignaciones() => _run(() async {
        final response = await _client.get(_uri('/asignaciones'), headers: _headers).timeout(timeout);
        _checkStatus(response);
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return list.map((e) => TeacherAssignment.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<List<SectionStudent>> getEstudiantes(int asignacionId) => _run(() async {
        final response = await _client
            .get(_uri('/asignaciones/$asignacionId/estudiantes'), headers: _headers)
            .timeout(timeout);
        _checkStatus(response);
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return list.map((e) => SectionStudent.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<void> registrarAsistencia({
    required int asignacionId,
    required int matriculaId,
    required DateTime fecha,
    required String estado,
    String? observacion,
  }) =>
      _run(() async {
        final isoDate = '${fecha.year.toString().padLeft(4, '0')}-'
            '${fecha.month.toString().padLeft(2, '0')}-'
            '${fecha.day.toString().padLeft(2, '0')}';
        final response = await _client
            .post(
              _uri('/asignaciones/$asignacionId/asistencias'),
              headers: _headers,
              body: jsonEncode({
                'matriculaId': matriculaId,
                'fecha': isoDate,
                'estado': estado,
                if (observacion != null && observacion.trim().isNotEmpty) 'observacion': observacion.trim(),
              }),
            )
            .timeout(timeout);
        _checkStatus(response);
      });

  Future<void> registrarCalificacion({
    required int asignacionId,
    required int matriculaId,
    required String etapa,
    required String concepto,
    required double nota,
    String? observacion,
  }) =>
      _run(() async {
        final response = await _client
            .post(
              _uri('/asignaciones/$asignacionId/calificaciones'),
              headers: _headers,
              body: jsonEncode({
                'matriculaId': matriculaId,
                'etapa': etapa.trim(),
                'concepto': concepto.trim(),
                'nota': nota,
                if (observacion != null && observacion.trim().isNotEmpty) 'observacion': observacion.trim(),
              }),
            )
            .timeout(timeout);
        _checkStatus(response);
      });

  void dispose() {
    _closed = true;
    _client.close();
  }
}