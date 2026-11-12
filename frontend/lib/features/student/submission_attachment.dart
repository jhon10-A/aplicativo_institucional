import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

const submissionMaxBytes = 5 * 1024 * 1024;
const submissionTypes = {
  'pdf': 'application/pdf',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'txt': 'text/plain',
};

class SubmissionAttachment {
  const SubmissionAttachment(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
  String get extension => name.split('.').last.toLowerCase();
  String? get mimeType => submissionTypes[extension];
  bool get valid =>
      name.contains('.') &&
      !name.contains('/') &&
      !name.contains('\\') &&
      !RegExp(r'[\x00-\x1f\x7f]').hasMatch(name) &&
      name.length <= 180 &&
      mimeType != null &&
      bytes.isNotEmpty &&
      bytes.length <= submissionMaxBytes;
}

Future<SubmissionAttachment?> pickSubmissionAttachment() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: submissionTypes.keys.toList(),
  );
  if (file == null) return null;
  final length = await file.length();
  if (length == null || length == 0 || length > submissionMaxBytes) {
    throw const FormatException('Invalid attachment');
  }
  final attachment = SubmissionAttachment(file.name, await file.readAsBytes());
  if (!attachment.valid) throw const FormatException('Invalid attachment');
  return attachment;
}

Future<bool> saveSubmissionAttachment(SubmissionAttachment file) async {
  return await FilePicker.saveFile(
        fileName: file.name,
        bytes: file.bytes,
        mimeType: file.mimeType!,
      ) !=
      null;
}
