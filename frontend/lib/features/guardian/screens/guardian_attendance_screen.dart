import 'package:flutter/material.dart';

import '../guardian_api.dart';
import '../guardian_attendance.dart';
import '../guardian_child.dart';
import '../guardian_section.dart';
import '../widgets/guardian_child_picker.dart';
import '../widgets/guardian_message.dart';

/// Etiqueta, icono y color de cada estado (el texto siempre acompaña al color).
const _states = <String, (String, IconData, Color)>{
  'PRESENTE': ('Presente', Icons.check_circle_outline, Color(0xFF1E8E3E)),
  'TARDANZA': ('Tardanza', Icons.schedule, Color(0xFFC76A00)),
  'FALTA': ('Falta', Icons.cancel_outlined, Color(0xFFC62828)),
  'JUSTIFICADA': (
    'Justificada',
    Icons.description_outlined,
    Color(0xFF1565C0),
  ),
};

class GuardianAttendanceScreen extends StatelessWidget {
  const GuardianAttendanceScreen({super.key, required this.api});
  final GuardianApi api;

  @override
  Widget build(BuildContext context) => GuardianChildPicker(
    api: api,
    section: GuardianSection.asistencia,
    builder: (context, child) => _AttendanceView(api: api, child: child),
  );
}

class _AttendanceView extends StatefulWidget {
  const _AttendanceView({required this.api, required this.child});
  final GuardianApi api;
  final GuardianChild child;

  @override
  State<_AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<_AttendanceView> {
  late Future<List<GuardianAttendance>> _future = widget.api.attendance(
    widget.child.id,
  );

  void _retry() {
    setState(() {
      _future = widget.api.attendance(widget.child.id);
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<GuardianAttendance>>(
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
      final records = snapshot.data!;
      if (records.isEmpty) {
        return GuardianMessage(
          icon: Icons.fact_check_outlined,
          text:
              'Aún no hay asistencias registradas para ${widget.child.nombres}.',
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 560 ? 4 : 2;
              final width =
                  (constraints.maxWidth - 12 * (columns - 1)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final entry in _states.entries)
                    SizedBox(
                      width: width,
                      child: _CountTile(
                        stateKey: entry.key,
                        label: entry.value.$1,
                        icon: entry.value.$2,
                        color: entry.value.$3,
                        value: records
                            .where((r) => r.estado == entry.key)
                            .length,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text('Total de registros: ${records.length}'),
          const SizedBox(height: 16),
          Text(
            'Registros recientes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final r in records) _RecordTile(record: r),
        ],
      );
    },
  );
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.stateKey,
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
  });
  final String stateKey;
  final String label;
  final IconData icon;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          '$value',
          key: ValueKey('attendance-count-$stateKey'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final GuardianAttendance record;

  @override
  Widget build(BuildContext context) {
    final state = _states[record.estado];
    final color = state?.$3 ?? const Color(0xFF5B6B7F);
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(state?.$2 ?? Icons.help_outline, color: color),
        ),
        title: Text('${record.fecha} · ${record.curso}'),
        subtitle: record.observacion == null || record.observacion!.isEmpty
            ? null
            : Text(record.observacion!),
        trailing: Text(
          state?.$1 ?? record.estado,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
