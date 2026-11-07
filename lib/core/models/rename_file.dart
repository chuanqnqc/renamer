import 'package:path/path.dart' as p;

/// A file selected for renaming.
class RenameFileItem {
  RenameFileItem({
    required this.path,
    String? originalName,
  }) : originalName = originalName ?? p.basename(path);

  /// Absolute path to the file on disk.
  final String path;

  /// Basename at the time the file was added (or last applied rename).
  final String originalName;

  String get directory => p.dirname(path);

  RenameFileItem copyWith({String? path, String? originalName}) {
    return RenameFileItem(
      path: path ?? this.path,
      originalName: originalName ?? this.originalName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenameFileItem &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          originalName == other.originalName;

  @override
  int get hashCode => Object.hash(path, originalName);
}
