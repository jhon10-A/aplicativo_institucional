import 'package:flutter/material.dart';

import '../guardian_api.dart';
import '../guardian_child.dart';
import '../guardian_grade.dart';
import '../widgets/guardian_child_picker.dart';
import '../widgets/guardian_message.dart';

class GuardianGradesScreen extends StatelessWidget {
  const GuardianGradesScreen({super.key, required this.api});
  final GuardianApi api;

  @override
  Widget build(BuildContext context) => GuardianChildPicker(
    api: api,
    title: 'Calificaciones',
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
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.child.nombreCompleto,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final entry in groups.entries)
            _CourseCard(title: entry.key, grades: entry.value),
        ],
      );
    },
  );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.title, required this.grades});
  final String title;
  final List<GuardianGrade> grades;

  @override
  Widget build(BuildContext context) {
    final average =
        grades.fold<double>(0, (sum, g) => sum + g.nota) / grades.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Docente: ${grades.first.docente}'),
            const SizedBox(height: 4),
            Text(
              'Promedio: ${average.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            for (final g in grades)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${g.etapa} · ${g.concepto}'),
                          if (g.observacion != null &&
                              g.observacion!.isNotEmpty)
                            Text(
                              g.observacion!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          Text(
                            g.fecha,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      g.nota.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
