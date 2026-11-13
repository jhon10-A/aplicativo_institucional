/// Hijo vinculado al apoderado, con su matrícula más reciente (puede faltar).
class GuardianChild {
  const GuardianChild({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.codigoEstudiante,
    required this.parentesco,
    required this.contactoPrincipal,
    this.matriculaId,
    this.estado,
    this.periodo,
    this.nivel,
    this.grado,
    this.seccion,
  });

  final int id;
  final String nombres;
  final String apellidos;
  final String codigoEstudiante;
  final String parentesco;
  final bool contactoPrincipal;
  final int? matriculaId;
  final String? estado;
  final String? periodo;
  final String? nivel;
  final String? grado;
  final String? seccion;

  String get nombreCompleto => '$nombres $apellidos';

  /// Ejemplo: "Primaria · 3° · Sección A". Vacío si no tiene matrícula.
  String get aula {
    final parts = [nivel, grado, seccion].whereType<String>().toList();
    return parts.isEmpty ? '' : parts.join(' · ');
  }

  factory GuardianChild.fromJson(Map<String, dynamic> json) => GuardianChild(
    id: json['id'] as int,
    nombres: json['nombres'] as String,
    apellidos: json['apellidos'] as String,
    codigoEstudiante: json['codigoEstudiante'] as String,
    parentesco: json['parentesco'] as String,
    contactoPrincipal: json['contactoPrincipal'] as bool,
    matriculaId: json['matriculaId'] as int?,
    estado: json['estado'] as String?,
    periodo: json['periodo'] as String?,
    nivel: json['nivel'] as String?,
    grado: json['grado'] as String?,
    seccion: json['seccion'] as String?,
  );
}
