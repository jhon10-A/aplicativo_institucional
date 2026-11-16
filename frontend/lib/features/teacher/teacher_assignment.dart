class TeacherAssignment {
  TeacherAssignment.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        cursoId = json['cursoId'] as int,
        cursoNombre = json['cursoNombre'] as String? ?? '',
        cursoDescripcion = json['cursoDescripcion'] as String?,
        periodoId = json['periodoId'] as int,
        periodoNombre = json['periodoNombre'] as String? ?? '',
        periodoActivo = json['periodoActivo'] as bool? ?? true,
        seccionId = json['seccionId'] as int,
        seccionNombre = json['seccionNombre'] as String? ?? '',
        gradoNombre = json['gradoNombre'] as String? ?? '',
        nivel = json['nivel'] as String? ?? '';

  final int id;
  final int cursoId;
  final String cursoNombre;
  final String? cursoDescripcion;
  final int periodoId;
  final String periodoNombre;
  final bool periodoActivo;
  final int seccionId;
  final String seccionNombre;
  final String gradoNombre;
  final String nivel;

  String get aulaLabel => '$gradoNombre "$seccionNombre" • $nivel';
}

class SectionStudent {
  SectionStudent.fromJson(Map<String, dynamic> json)
      : matriculaId = json['matriculaId'] as int,
        estudianteId = json['estudianteId'] as int,
        codigoEstudiante = json['codigoEstudiante'] as String? ?? '',
        nombres = json['nombres'] as String? ?? '',
        apellidos = json['apellidos'] as String? ?? '',
        estadoMatricula = json['estadoMatricula'] as String? ?? 'ACTIVA';

  final int matriculaId;
  final int estudianteId;
  final String codigoEstudiante;
  final String nombres;
  final String apellidos;
  final String estadoMatricula;

  String get nombreCompleto => '$apellidos, $nombres'.trim();
}