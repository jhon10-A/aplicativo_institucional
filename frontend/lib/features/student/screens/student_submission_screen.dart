import 'dart:async';

import 'package:flutter/material.dart';

import '../student_api.dart';
import '../student_task.dart';
import '../submission_attachment.dart';

class StudentSubmissionScreen extends StatefulWidget {
  const StudentSubmissionScreen({
    super.key,
    required this.api,
    required this.enrollment,
    required this.task,
    required this.onUnauthorized,
    this.pickFile = pickSubmissionAttachment,
    this.saveFile = saveSubmissionAttachment,
  });
  final StudentApi api;
  final int enrollment;
  final StudentTask task;
  final VoidCallback onUnauthorized;
  final Future<SubmissionAttachment?> Function() pickFile;
  final Future<bool> Function(SubmissionAttachment) saveFile;
  @override
  State<StudentSubmissionScreen> createState() =>
      _StudentSubmissionScreenState();
}

class _StudentSubmissionScreenState extends State<StudentSubmissionScreen> {
  final _comment = TextEditingController();
  SubmissionAttachment? _attachment;
  StudentSubmission? _receipt;
  String? _message;
  bool _busy = false;
  bool _sent = false;
  bool _view = false;

  @override
  void initState() {
    super.initState();
    _view = widget.task.entrega != null;
    if (_view) unawaited(_load());
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _failure(Object error) {
    if (!mounted) return;
    final kind = error is StudentFailure
        ? error.kind
        : error is FormatException
        ? StudentFailureKind.validation
        : StudentFailureKind.invalid;
    setState(
      () => _message = switch (kind) {
        StudentFailureKind.unauthorized =>
          'Tu sesión ha vencido. Vuelve a iniciar sesión.',
        StudentFailureKind.forbidden => 'No tienes permiso para esta entrega.',
        StudentFailureKind.unavailable =>
          'La tarea o entrega no está disponible.',
        StudentFailureKind.duplicate => 'Esta tarea ya tiene una entrega. Consulta tu entrega antes de continuar.',
        StudentFailureKind.closed =>
          'El plazo o el estado de la tarea no permite entregas.',
        StudentFailureKind.tooLarge => 'El archivo supera el límite de 5 MiB.',
        StudentFailureKind.validation => 'Comprueba la respuesta y el archivo: PDF, PNG, JPG o TXT, hasta 5 MiB.',
        StudentFailureKind.network => 'No se pudo confirmar la operación. Consulta tu entrega antes de volver a enviar.',
        _ => 'No se pudo completar la operación. Inténtalo nuevamente.',
      },
    );
    if (kind == StudentFailureKind.unauthorized) widget.onUnauthorized();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final receipt = StudentSubmission.fromJson(
        await widget.api.submission(widget.enrollment, widget.task.id),
      );
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _view = true;
      });
    } catch (e) {
      _failure(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final attachment = await widget.pickFile();
      if (attachment != null && !attachment.valid) {
        throw const StudentFailure(StudentFailureKind.validation);
      }
      if (mounted && attachment != null) {
        setState(() => _attachment = attachment);
      }
    } catch (e) {
      _failure(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || _receipt != null) return;
    if (_comment.text.trim().isEmpty && _attachment == null) {
      setState(() => _message = 'Escribe una respuesta o adjunta un archivo.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar entrega'),
          content: const Text(
            'Se registrará una sola entrega. Después del envío no podrás editarla ni reemplazar el archivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar envío'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final receipt = StudentSubmission.fromJson(
        await widget.api.submitTask(
          widget.enrollment,
          widget.task.id,
          _comment.text,
          attachment: _attachment,
        ),
      );
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _view = true;
        _sent = true;
        _attachment = null;
        _comment.clear();
        _message = 'Entrega registrada correctamente.';
      });
    } catch (e) {
      _failure(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final file = await widget.api.submissionFile(
        widget.enrollment,
        widget.task.id,
      );
      if (!mounted) return;
      final saved = await widget.saveFile(file);
      if (mounted) {
        setState(
          () => _message = saved ? 'Archivo guardado.' : 'Guardado cancelado.',
        );
      }
    } catch (e) {
      _failure(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: Text(_view ? 'Mi entrega' : 'Entregar tarea')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.task.titulo,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('Curso: ${widget.task.curso}'),
                Text('Fecha límite: ${_date(widget.task.fechaLimite)}'),
                const SizedBox(height: 16),
                if (_message != null)
                  Semantics(liveRegion: true, child: Text(_message!)),
                if (_busy) ...[
                  const LinearProgressIndicator(),
                  const Text('Procesando…'),
                ],
                if (_receipt case final receipt?) ...[
                  Text(
                    'Estado: ${receipt.fechaRevision == null ? 'Entregada' : 'Revisada'}',
                  ),
                  Text('Fecha de entrega: ${_date(receipt.fechaEntrega)}'),
                  Text(
                    'Respuesta: ${receipt.comentario ?? 'Sin respuesta escrita'}',
                  ),
                  Text(
                    'Puntaje: ${receipt.puntaje?.toString() ?? 'Sin calificar'}',
                  ),
                  Text(
                    'Retroalimentación: ${receipt.retroalimentacion ?? 'Sin revisión registrada'}',
                  ),
                  if (receipt.archivoUrl != null)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _download,
                      icon: const Icon(Icons.download),
                      label: const Text('Guardar mi archivo'),
                    ),
                ] else if (!_view) ...[
                  TextField(
                    controller: _comment,
                    enabled: !_busy,
                    maxLength: 10000,
                    minLines: 4,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      labelText: 'Respuesta',
                      hintText: 'Escribe tu respuesta a la tarea',
                    ),
                  ),
                  const Text('Un archivo PDF, PNG, JPG o TXT, hasta 5 MiB.'),
                  if (_attachment case final file?) ...[
                    Text('Adjunto: ${file.name} (${file.bytes.length} bytes)'),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _attachment = null),
                      child: const Text('Quitar adjunto'),
                    ),
                  ],
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Seleccionar archivo'),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: const Text('Enviar entrega'),
                  ),
                ],
                if (_receipt == null)
                  OutlinedButton(
                    onPressed: _busy ? null : _load,
                    child: Text(
                      _view ? 'Reintentar consulta' : 'Consultar mi entrega',
                    ),
                  ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.pop(context, _sent),
                  child: const Text('Volver al detalle'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
