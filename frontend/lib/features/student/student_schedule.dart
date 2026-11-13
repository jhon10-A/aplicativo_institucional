class StudentSchedule {
  StudentSchedule.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      matriculaId = json['matriculaId'] as int,
      asignacionId = json['asignacionId'] as int,
      cursoId = json['cursoId'] as int,
      curso = json['curso'] as String,
      docente = json['docente'] as String,
      periodoId = json['periodoId'] as int,
      periodo = json['periodo'] as String,
      nivel = json['nivel'] as String,
      grado = json['grado'] as String,
      seccion = json['seccion'] as String,
      diaSemana = _weekday(json['diaSemana'] as int),
      horaInicio = _formatTime(json['horaInicio']),
      horaFin = _formatTime(json['horaFin']),
      aula = json['aula'] as String?;

  final int id;
  final int matriculaId;
  final int asignacionId;
  final int cursoId;
  final String curso;
  final String docente;
  final int periodoId;
  final String periodo;
  final String nivel;
  final String grado;
  final String seccion;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final String? aula;

  String get dia => const [
    '',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ][diaSemana];

  String get diaCorto => dia.substring(0, 3);

  String? get aulaDisponible =>
      aula?.trim().isNotEmpty == true ? aula!.trim() : null;

  static int _weekday(int value) {
    if (value < 1 || value > 5) {
      throw const FormatException('Día de horario fuera de rango.');
    }
    return value;
  }

  static String _formatTime(Object? value) {
    if (value is! String ||
        !RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9](\.[0-9]+)?)?$')
            .hasMatch(value)) {
      throw const FormatException('Hora de horario inválida.');
    }
    return value.substring(0, 5);
  }
}
