class TeacherProfile {
  TeacherProfile.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        usuarioId = json['usuarioId'] as int?,
        nombreUsuario = json['nombreUsuario'] as String? ?? '',
        nombres = json['nombres'] as String? ?? '',
        apellidos = json['apellidos'] as String? ?? '',
        documentoIdentidad = json['documentoIdentidad'] as String? ?? '',
        especialidad = json['especialidad'] as String? ?? '',
        activo = json['activo'] as bool? ?? true;

  final int id;
  final int? usuarioId;
  final String nombreUsuario;
  final String nombres;
  final String apellidos;
  final String documentoIdentidad;
  final String especialidad;
  final bool activo;

  String get nombreCompleto => '$nombres $apellidos'.trim();
}