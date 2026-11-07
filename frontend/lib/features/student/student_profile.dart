class StudentProfile {
  StudentProfile.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      usuarioId = json['usuarioId'] as int,
      nombreUsuario = json['nombreUsuario'] as String,
      nombres = json['nombres'] as String,
      apellidos = json['apellidos'] as String,
      codigoEstudiante = json['codigoEstudiante'] as String,
      correo = json['correo'] as String?,
      telefono = json['telefono'] as String?,
      documentoIdentidad = json['documentoIdentidad'] as String?,
      fechaNacimiento = json['fechaNacimiento'] == null
          ? null
          : DateTime.parse(json['fechaNacimiento'] as String);

  final int id;
  final int usuarioId;
  final String nombreUsuario;
  final String nombres;
  final String apellidos;
  final String codigoEstudiante;
  final String? correo;
  final String? telefono;
  final String? documentoIdentidad;
  final DateTime? fechaNacimiento;
}

class StudentEnrollment {
  StudentEnrollment.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      estado = json['estado'] as String,
      fechaMatricula = DateTime.parse(json['fechaMatricula'] as String),
      periodo = json['periodo']['nombre'] as String,
      inicio = DateTime.parse(json['periodo']['fechaInicio'] as String),
      fin = DateTime.parse(json['periodo']['fechaFin'] as String),
      periodoActivo = json['periodo']['activo'] as bool,
      seccion = json['seccion']['nombre'] as String,
      grado = json['seccion']['grado']['nombre'] as String,
      nivel = json['seccion']['grado']['nivel'] as String;

  final int id;
  final String estado;
  final DateTime fechaMatricula;
  final String periodo;
  final DateTime inicio;
  final DateTime fin;
  final bool periodoActivo;
  final String seccion;
  final String grado;
  final String nivel;
}
