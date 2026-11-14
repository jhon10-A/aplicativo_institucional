import 'package:flutter_test/flutter_test.dart';
import 'package:aplicativo_institucional/features/student/student_home_summary.dart';
import 'package:aplicativo_institucional/features/student/student_profile.dart';
import 'package:aplicativo_institucional/features/student/student_schedule.dart';

import 'student_profile_test.dart' show enrollmentFixture;
import 'student_schedule_test.dart' show scheduleFixture;

void main() {
  final enrollment = StudentEnrollment.fromJson(enrollmentFixture('2026'));
  StudentSchedule session(int id, int day, String start, String end) =>
      StudentSchedule.fromJson(
        scheduleFixture(id: id, weekday: day, start: start, end: end),
      );
  final sessions = [
    session(3, 5, '10:15', '11:10'),
    session(1, 5, '08:00', '08:55'),
    session(5, 1, '08:00', '08:55'),
    session(2, 5, '08:55', '09:50'),
    session(4, 5, '11:10', '12:05'),
  ];

  test('resumen distingue carga, ausencia, error e intervalo recibido', () {
    expect(
      const StudentHomeScheduleSummary.selectionRequired().label,
      'Horario: selecciona una matrícula',
    );
    expect(
      const StudentHomeScheduleSummary.loading().label,
      'Horario: Cargando…',
    );
    expect(
      const StudentHomeScheduleSummary.empty().label,
      'Horario: sin registrar',
    );
    expect(
      const StudentHomeScheduleSummary.unavailable().label,
      'Horario: no disponible',
    );
    expect(
      StudentHomeScheduleSummary.loaded(sessions).label,
      'Horario: 08:00–12:05',
    );
  });

  test(
    'clase actual primero, sin clases ya terminadas ni alterar el original',
    () {
      final result = studentSchedulePreview(
        sessions,
        instant: DateTime.utc(2026, 11, 13, 14, 0),
        enrollment: enrollment,
      );
      expect(result.heading, 'Hoy · Viernes 13/11');
      expect(result.sessions.map((s) => s.id), [2, 3, 4]);
      expect(result.remaining, 0);
      expect(sessions.first.id, 3);
    },
  );

  test('antes de clases limita a tres y cuenta el resto del día', () {
    final result = studentSchedulePreview(
      sessions,
      instant: DateTime.utc(2026, 11, 13, 12),
      enrollment: enrollment,
    );
    expect(result.sessions.map((s) => s.id), [1, 2, 3]);
    expect(result.remaining, 1);
  });

  test('el fin de una clase no la mantiene como actual; respeta recreo', () {
    final result = studentSchedulePreview(
      sessions,
      instant: DateTime.utc(2026, 11, 13, 14, 50),
      enrollment: enrollment,
    );
    expect(result.sessions.map((s) => s.id), [3, 4]);
  });

  test('viernes finalizado y fin de semana avanzan al lunes', () {
    for (final instant in [
      DateTime.utc(2026, 11, 13, 18),
      DateTime.utc(2026, 11, 15, 15),
    ]) {
      final result = studentSchedulePreview(
        sessions,
        instant: instant,
        enrollment: enrollment,
      );
      expect(result.heading, 'Próxima jornada · Lunes 16/11');
      expect(result.sessions.single.id, 5);
    }
  });

  test('medianoche UTC sigue siendo viernes en Lima', () {
    final lima = studentLimaTime(DateTime.utc(2026, 11, 14, 2));
    expect([lima.day, lima.weekday, lima.hour], [13, 5, 21]);
  });

  test('no promete clases fuera del periodo ni después de su fin', () {
    final past = studentSchedulePreview(
      sessions,
      instant: DateTime.utc(2027, 1, 1, 15),
      enrollment: enrollment,
    );
    expect(past.heading, 'Horario del periodo');
    final lastDay = studentSchedulePreview(
      [session(6, 1, '08:00', '09:00')],
      instant: DateTime.utc(2026, 12, 31, 20),
      enrollment: enrollment,
    );
    expect(lastDay.sessions, isEmpty);
    expect(lastDay.heading, 'Sin próximas clases en este periodo.');
  });

  test('filtro de inicio reconoce únicamente el prefijo literal TEST_EST_', () {
    expect(
      showStudentHomeNotice({'titulo': 'TEST_EST_a144bf99 General'}),
      isFalse,
    );
    expect(showStudentHomeNotice({'titulo': 'Aviso sobre TEST_EST_'}), isTrue);
    expect(showStudentHomeNotice({'titulo': 'TEST_ESTUDIANTE'}), isTrue);
    expect(showStudentHomeNotice({'titulo': 'Jornada deportiva'}), isTrue);
  });
}
