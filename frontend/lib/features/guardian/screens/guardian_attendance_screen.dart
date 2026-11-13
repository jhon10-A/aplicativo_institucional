import 'package:flutter/material.dart';

import '../guardian_api.dart';
import '../guardian_attendance.dart';
import '../guardian_child.dart';
import '../widgets/guardian_child_picker.dart';
import '../widgets/guardian_message.dart';

const _states = <String, (String, IconData)>{
  'PRESENTE': ('Presente', Icons.check_circle_outline),
  'TARDANZA': ('Tardanza', Icons.schedule),
  'FALTA': ('Falta', Icons.cancel_outlined),
  'JUSTIFICADA': ('Justificada', Icons.description_outlined),
};

class GuardianAttendanceScreen extends StatelessWidget {
  const GuardianAttendanceScreen({super.key, required this.api});
  final GuardianApi api;

  @override
  Widget build(BuildContext context) => GuardianChildPicker(
    api: api,
    title: 'Asistencia',
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
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.child.nombreCompleto,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in _states.entries)
                _CountBox(
                  stateKey: entry.key,
                  label: entry.value.$1,
                  icon: entry.value.$2,
                  value: records.where((r) => r.estado == entry.key).length,
                ),
            ],
          ),
          const SizedBox(height: 8),
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

class _CountBox extends StatelessWidget {
  const _CountBox({
    required this.stateKey,
    required this.label,
    required this.icon,
    required this.value,
  });
  final String stateKey;
  final String label;
  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(
              '$value',
              key: ValueKey('attendance-count-$stateKey'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final GuardianAttendance record;

  @override
  Widget build(BuildContext context) {
    final state = _states[record.estado];
    return Card(
      child: ListTile(
        leading: Icon(state?.$2 ?? Icons.help_outline),
        title: Text('${record.fecha} · ${record.curso}'),
        subtitle:
            record.observacion == null || record.observacion!.isEmpty
            ? null
            : Text(record.observacion!),
        trailing: Text(state?.$1 ?? record.estado),
      ),
    );
  }
}
