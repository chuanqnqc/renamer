import 'package:path/path.dart' as p;

/// Splits a basename into stem + extension (extension includes the dot).
class FilenameParts {
  const FilenameParts({required this.stem, required this.extension});

  final String stem;

  /// Includes the leading `.` when present; empty when none.
  final String extension;

  String get fullName => '$stem$extension';

  static FilenameParts parse(String basename) {
    final ext = p.extension(basename);
    if (ext.isEmpty) {
      return FilenameParts(stem: basename, extension: '');
    }
    final stem = basename.substring(0, basename.length - ext.length);
    return FilenameParts(stem: stem, extension: ext);
  }

  FilenameParts copyWith({String? stem, String? extension}) {
    return FilenameParts(
      stem: stem ?? this.stem,
      extension: extension ?? this.extension,
    );
  }
}
