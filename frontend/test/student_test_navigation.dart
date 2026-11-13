import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplicativo_institucional/features/student/widgets/student_quick_view.dart';

/// Full screens remain reachable even when a quick view has no enrollment.
Future<void> openCompleteStudentSection(
  WidgetTester tester,
  String section,
) async {
  expect(find.byType(StudentQuickView), findsOneWidget);
  await tester.tap(find.byTooltip('Cerrar vista rápida').first);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Abrir navegación'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('student-nav-$section')));
  await tester.pumpAndSettle();
}
