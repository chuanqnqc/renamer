import 'rename_file.dart';

/// One row in the live preview table.
class PreviewRow {
  const PreviewRow({
    required this.file,
    required this.newName,
    this.error,
  });

  final RenameFileItem file;
  final String newName;
  final String? error;

  bool get hasError => error != null;
  bool get willChange => newName != file.originalName;
}
