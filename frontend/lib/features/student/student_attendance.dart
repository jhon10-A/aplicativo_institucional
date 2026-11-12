class StudentAttendance {
  StudentAttendance.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      curso = json['curso'] as String,
      docente = json['docente'] as String,
      periodo = json['periodo'] as String,
      nivel = json['nivel'] as String,
      grado = json['grado'] as String,
      seccion = json['seccion'] as String,
      fecha = DateTime.parse(json['fecha'] as String),
      estado = json['estado'] as String,
      observacion = json['observacion'] as String?,
      registradoEn = DateTime.parse(json['registradoEn'] as String);
  final int id;
  final String curso, docente, periodo, nivel, grado, seccion, estado;
  final DateTime fecha, registradoEn;
  final String? observacion;
  String get estadoLabel => switch (estado) {
    'PRESENTE' => 'Presente',
    'FALTA' => 'Falta',
    'TARDANZA' => 'Tardanza',
    'JUSTIFICADA' => 'Justificada',
    _ => 'No disponible',
  };
}

class AttendancePage {
  AttendancePage.fromJson(Map<String, dynamic> json)
    : registros = (json['registros'] as List)
          .map(
            (item) => StudentAttendance.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      total = json['resumen']['total'] as int,
      presente = json['resumen']['presente'] as int,
      falta = json['resumen']['falta'] as int,
      tardanza = json['resumen']['tardanza'] as int,
      justificada = json['resumen']['justificada'] as int;
  final List<StudentAttendance> registros;
  final int total, presente, falta, tardanza, justificada;
}

bool validAttendanceDate(String value) {
  if (!RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$').hasMatch(value)) return false;
  final date = DateTime.tryParse(value);
  return date != null &&
      date.year >= 1000 &&
      date.toIso8601String().substring(0, 10) == value;
}
