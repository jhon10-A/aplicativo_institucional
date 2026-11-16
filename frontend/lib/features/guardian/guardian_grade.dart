/// Nota registrada por un docente para un hijo.
class GuardianGrade {
  const GuardianGrade({
    required this.id,
    required this.periodo,
    required this.curso,
    required this.docente,
    required this.etapa,
    required this.concepto,
    required this.nota,
    required this.fecha,
    this.observacion,
  });

  final int id;
  final String periodo;
  final String curso;
  final String docente;
  final String etapa;
  final String concepto;
  final double nota;
  final String? observacion;

  /// Fecha de registro en formato aaaa-mm-dd.
  final String fecha;

  factory GuardianGrade.fromJson(Map<String, dynamic> json) => GuardianGrade(
    id: json['id'] as int,
    periodo: json['periodo'] as String,
    curso: json['curso'] as String,
    docente: json['docente'] as String,
    etapa: json['etapa'] as String,
    concepto: json['concepto'] as String,
    nota: (json['nota'] as num).toDouble(),
    observacion: json['observacion'] as String?,
    fecha: json['fecha'] as String,
  );
}
