class StudentSubmission {
  StudentSubmission.fromJson(Map<String, dynamic> json)
    : comentario = json['comentario'] as String?,
      archivoUrl = json['archivoUrl'] as String?,
      fechaEntrega = DateTime.parse(json['fechaEntrega'] as String),
      puntaje = (json['puntaje'] as num?)?.toDouble(),
      retroalimentacion = json['retroalimentacion'] as String?,
      fechaRevision = json['fechaRevision'] == null
          ? null
          : DateTime.parse(json['fechaRevision'] as String);
  final String? comentario;
  final String? archivoUrl;
  final DateTime fechaEntrega;
  final double? puntaje;
  final String? retroalimentacion;
  final DateTime? fechaRevision;
}

class StudentTask {
  StudentTask.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      asignacionId = json['asignacionId'] as int,
      curso = json['curso'] as String,
      docente = json['docente'] as String,
      titulo = json['titulo'] as String,
      descripcion = json['descripcion'] as String?,
      archivoUrl = json['archivoUrl'] as String?,
      fechaPublicacion = DateTime.parse(json['fechaPublicacion'] as String),
      fechaLimite = DateTime.parse(json['fechaLimite'] as String),
      puntajeMaximo = (json['puntajeMaximo'] as num).toDouble(),
      estadoEntrega = json['estadoEntrega'] as String,
      entrega = json['entrega'] == null
          ? null
          : StudentSubmission.fromJson(json['entrega'] as Map<String, dynamic>);
  final int id;
  final int asignacionId;
  final String curso;
  final String docente;
  final String titulo;
  final String? descripcion;
  final String? archivoUrl;
  final DateTime fechaPublicacion;
  final DateTime fechaLimite;
  final double puntajeMaximo;
  final String estadoEntrega;
  final StudentSubmission? entrega;

  String get estado => switch (estadoEntrega) {
    'PENDIENTE' =>
      DateTime.now().isAfter(fechaLimite) ? 'Vencida' : 'Pendiente',
    'ENTREGADA' => 'Entregada',
    'REVISADA' => 'Revisada',
    _ => 'No disponible',
  };
}
