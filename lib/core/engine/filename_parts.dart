import 'package:path/path.dart' as p;

/// Splits a basename into stem + extension (extension includes the dot).
class FilenameParts {
  const FilenameParts({required this.stem, required this.extension});

  final String stem;

  /// Includes the leading `.` when present; empty when none.
  final String extension;

  String get fullName => '$stem$extension';

  static FilenameParts parse(String basename) {
    // After ClearName (and similar), a name can be extension-only: ".jpg".
    // package:path treats that as a dotfile with *no* extension, which would
    // make later "insert/number at end" rules append after ".jpg".
    if (_isExtensionOnly(basename)) {
      return FilenameParts(stem: '', extension: basename);
    }

    final ext = p.extension(basename);
    if (ext.isEmpty) {
      return FilenameParts(stem: basename, extension: '');
    }
    final stem = basename.substring(0, basename.length - ext.length);
    return FilenameParts(stem: stem, extension: ext);
  }

  /// ".jpg", ".PNG" — starts with a dot, no further dots.
  static bool _isExtensionOnly(String basename) {
    if (basename.length < 2 || !basename.startsWith('.')) return false;
    if (basename == '.' || basename == '..') return false;
    return !basename.substring(1).contains('.');
  }

  FilenameParts copyWith({String? stem, String? extension}) {
    return FilenameParts(
      stem: stem ?? this.stem,
      extension: extension ?? this.extension,
    );
  }
}
