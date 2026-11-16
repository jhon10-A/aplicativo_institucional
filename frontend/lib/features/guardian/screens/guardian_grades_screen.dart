import 'package:flutter/material.dart';

import '../guardian_api.dart';
import '../guardian_child.dart';
import '../guardian_grade.dart';
import '../guardian_section.dart';
import '../guardian_theme.dart';
import '../widgets/guardian_child_picker.dart';
import '../widgets/guardian_message.dart';

const _courseColors = <Color>[
  Color(0xFF1565C0),
  guardianWine,
  Color(0xFF1E8E3E),
  Color(0xFF7B3FA0),
  Color(0xFFC76A00),
];

const _courseIcons = <IconData>[
  Icons.calculate_outlined,
  Icons.menu_book_outlined,
  Icons.science_outlined,
  Icons.public_outlined,
  Icons.sports_soccer_outlined,
];

/// Verde desde 14, azul desde 11 y rojo por debajo (el número siempre se muestra).
Color _noteColor(double nota) => nota >= 14
    ? const Color(0xFF1E8E3E)
    : nota >= 11
    ? const Color(0xFF1565C0)
    : const Color(0xFFC62828);

class GuardianGradesScreen extends StatelessWidget {
  const GuardianGradesScreen({super.key, required this.api});
  final GuardianApi api;

  @override
  Widget build(BuildContext context) => GuardianChildPicker(
    api: api,
    section: GuardianSection.calificaciones,
    builder: (context, child) => _GradesView(api: api, child: child),
  );
}

class _GradesView extends StatefulWidget {
  const _GradesView({required this.api, required this.child});
  final GuardianApi api;
  final GuardianChild child;

  @override
  State<_GradesView> createState() => _GradesViewState();
}

class _GradesViewState extends State<_GradesView> {
  late Future<List<GuardianGrade>> _future = widget.api.grades(
    widget.child.id,
  );

  void _retry() {
    setState(() {
      _future = widget.api.grades(widget.child.id);
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<GuardianGrade>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        return GuardianMessage(
          icon: Icons.error_outline,
          text: error is GuardianFailure
              ? error.message
              : 'Ocurrió un error inesperado.',
          onRetry: _retry,
        );
      }
      final grades = snapshot.data!;
      if (grades.isEmpty) {
        return GuardianMessage(
          icon: Icons.grade_outlined,
          text:
              'Aún no hay calificaciones registradas para ${widget.child.nombres}.',
        );
      }
      // Agrupa por curso y periodo conservando el orden que envía el backend.
      final groups = <String, List<GuardianGrade>>{};
      for (final grade in grades) {
        groups
            .putIfAbsent('${grade.curso} · Periodo ${grade.periodo}', () => [])
            .add(grade);
      }
      final entries = groups.entries.toList();
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < entries.length; i++)
            _CourseCard(
              index: i,
              title: entries[i].key,
              grades: entries[i].value,
            ),
        ],
      );
    },
  );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.index,
    required this.title,
    required this.grades,
  });
  final int index;
  final String title;
  final List<GuardianGrade> grades;

  @override
  Widget build(BuildContext context) {
    final color = _courseColors[index % _courseColors.length];
    final average =
        grades.fold<double>(0, (sum, g) => sum + g.nota) / grades.length;
    final averageColor = _noteColor(average);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _courseIcons[index % _courseIcons.length],
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Docente: ${grades.first.docente}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: averageColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Promedio: ${average.toStringAsFixed(2)}',
                style: TextStyle(
                  color: averageColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Divider(),
            for (var i = 0; i < grades.length; i++) ...[
              if (i > 0) const Divider(height: 16),
              _GradeRow(grade: grades[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.grade});
  final GuardianGrade grade;

  @override
  Widget build(BuildContext context) {
    final color = _noteColor(grade.nota);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${grade.etapa} · ${grade.concepto}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (grade.observacion != null && grade.observacion!.isNotEmpty)
                Text(
                  grade.observacion!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              Text(grade.fecha, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            grade.nota.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
