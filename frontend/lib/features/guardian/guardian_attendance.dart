/// Registro de asistencia de un hijo en un curso y fecha.
class GuardianAttendance {
  const GuardianAttendance({
    required this.id,
    required this.fecha,
    required this.periodo,
    required this.curso,
    required this.estado,
    this.observacion,
  });

  final int id;

  /// Fecha en formato aaaa-mm-dd.
  final String fecha;
  final String periodo;
  final String curso;

  /// PRESENTE, FALTA, TARDANZA o JUSTIFICADA.
  final String estado;
  final String? observacion;

  factory GuardianAttendance.fromJson(Map<String, dynamic> json) =>
      GuardianAttendance(
        id: json['id'] as int,
        fecha: json['fecha'] as String,
        periodo: json['periodo'] as String,
        curso: json['curso'] as String,
        estado: json['estado'] as String,
        observacion: json['observacion'] as String?,
      );
}
