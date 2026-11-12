class StudentNotice {
  StudentNotice.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      titulo = json['titulo'] as String,
      contenido = json['contenido'] as String,
      remitente = json['remitente'] as String,
      publicadoEn = DateTime.parse(json['publicadoEn'] as String),
      fechaVencimiento = json['fechaVencimiento'] == null
          ? null
          : DateTime.parse(json['fechaVencimiento'] as String),
      rolDestino = json['rolDestino'] as String?,
      seccion = json['seccionDestino'] == null
          ? null
          : '${json['seccionDestino']['nivel']} ${json['seccionDestino']['grado']} ${json['seccionDestino']['nombre']}';
  final int id;
  final String titulo, contenido, remitente;
  final String? rolDestino, seccion;
  final DateTime publicadoEn;
  final DateTime? fechaVencimiento;
  String get alcance =>
      seccion == null ? 'General (sin sección)' : 'Sección: $seccion';
  String get destinatarios =>
      rolDestino == null ? 'Todos los roles' : 'Estudiantes';
}
