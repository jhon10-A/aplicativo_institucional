class StudentCourse {
  StudentCourse.fromJson(Map<String, dynamic> json)
    : asignacionId = json['asignacionId'] as int,
      cursoId = json['cursoId'] as int,
      nombre = json['nombre'] as String,
      descripcion = json['descripcion'] as String?,
      activo = json['activo'] as bool,
      docente = json['docente'] as String,
      periodo = json['periodo'] as String,
      nivel = json['nivel'] as String,
      grado = json['grado'] as String,
      seccion = json['seccion'] as String;

  final int asignacionId;
  final int cursoId;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final String docente;
  final String periodo;
  final String nivel;
  final String grado;
  final String seccion;
}
