import 'student_profile.dart';
import 'student_schedule.dart';

enum StudentScheduleLoad { loading, ready, unavailable, selectionRequired }

/// State from the existing overview request, not a second API request.
class StudentHomeScheduleSummary {
  const StudentHomeScheduleSummary.loading()
    : state = StudentScheduleLoad.loading,
      sessions = const [];
  const StudentHomeScheduleSummary.unavailable()
    : state = StudentScheduleLoad.unavailable,
      sessions = const [];
  const StudentHomeScheduleSummary.empty()
    : state = StudentScheduleLoad.ready,
      sessions = const [];
  const StudentHomeScheduleSummary.selectionRequired()
    : state = StudentScheduleLoad.selectionRequired,
      sessions = const [];
  StudentHomeScheduleSummary.loaded(List<StudentSchedule> value)
    : state = StudentScheduleLoad.ready,
      sessions = List.unmodifiable(value);

  final StudentScheduleLoad state;
  final List<StudentSchedule> sessions;

  String get label {
    if (state == StudentScheduleLoad.selectionRequired) {
      return 'Horario: selecciona una matrícula';
    }
    if (state == StudentScheduleLoad.loading) return 'Horario: Cargando…';
    if (state == StudentScheduleLoad.unavailable) {
      return 'Horario: no disponible';
    }
    if (sessions.isEmpty) return 'Horario: sin registrar';
    final starts = sessions.map((s) => s.horaInicio).toList()..sort();
    final ends = sessions.map((s) => s.horaFin).toList()..sort();
    return 'Horario: ${starts.first}–${ends.last}';
  }
}

/// Calendar fields in Lima (UTC-05), independent of the device's time zone.
DateTime studentLimaTime(DateTime instant) =>
    instant.toUtc().subtract(const Duration(hours: 5));

bool showStudentHomeNotice(Map<String, dynamic> notice) =>
    !(notice['titulo'] as String).startsWith('TEST_EST_');

class StudentSchedulePreview {
  const StudentSchedulePreview(this.heading, this.sessions, this.remaining);
  final String heading;
  final List<StudentSchedule> sessions;
  final int remaining;
}

int _minutes(String time) =>
    int.parse(time.substring(0, 2)) * 60 + int.parse(time.substring(3, 5));

StudentSchedulePreview studentSchedulePreview(
  List<StudentSchedule> schedule, {
  required DateTime instant,
  StudentEnrollment? enrollment,
}) {
  final ordered = [...schedule]
    ..sort((a, b) {
      final day = a.diaSemana.compareTo(b.diaSemana);
      if (day != 0) return day;
      final time = a.horaInicio.compareTo(b.horaInicio);
      return time != 0 ? time : a.id.compareTo(b.id);
    });
  final lima = studentLimaTime(instant);
  final today = DateTime.utc(lima.year, lima.month, lima.day);
  DateTime dateOnly(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
  if (enrollment != null &&
      (enrollment.estado != 'ACTIVA' ||
          !enrollment.periodoActivo ||
          today.isBefore(dateOnly(enrollment.inicio)) ||
          today.isAfter(dateOnly(enrollment.fin)))) {
    return StudentSchedulePreview(
      'Horario del periodo',
      ordered.take(3).toList(),
      (ordered.length - 3).clamp(0, ordered.length),
    );
  }
  for (var offset = 0; offset <= 7; offset++) {
    final day = today.add(Duration(days: offset));
    if (enrollment != null && day.isAfter(dateOnly(enrollment.fin))) break;
    final sessions = ordered.where((s) {
      return s.diaSemana == day.weekday &&
          (offset != 0 || _minutes(s.horaFin) > lima.hour * 60 + lima.minute);
    }).toList();
    if (sessions.isEmpty) continue;
    final date =
        '${day.day.toString().padLeft(2, '0')}/'
        '${day.month.toString().padLeft(2, '0')}';
    return StudentSchedulePreview(
      '${offset == 0 ? 'Hoy' : 'Próxima jornada'} · ${sessions.first.dia} $date',
      sessions.take(3).toList(),
      (sessions.length - 3).clamp(0, sessions.length),
    );
  }
  return const StudentSchedulePreview(
    'Sin próximas clases en este periodo.',
    [],
    0,
  );
}
