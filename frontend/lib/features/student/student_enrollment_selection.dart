import 'student_profile.dart';

/// A remembered choice must still belong to the current authenticated response.
/// Never choose an arbitrary first enrollment when the academic context is ambiguous.
int? resolveStudentEnrollment(
  List<StudentEnrollment> enrollments,
  int? remembered,
) {
  if (enrollments.any((m) => m.id == remembered)) return remembered;
  if (enrollments.length == 1) return enrollments.single.id;
  final active = enrollments
      .where((m) => m.estado == 'ACTIVA' && m.periodoActivo)
      .toList();
  return active.length == 1 ? active.single.id : null;
}
