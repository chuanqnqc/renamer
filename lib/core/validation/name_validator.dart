import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/preview_row.dart';
import '../models/rename_file.dart';

/// Validates preview names for emptiness, illegal characters, and collisions.
class NameValidator {
  static final RegExp _illegal = RegExp(r'[<>:"/\\|?*\x00-\x1F]');

  /// Returns a parallel list of error messages (null when valid).
  List<String?> validate({
    required List<RenameFileItem> files,
    required List<String> newNames,
    bool checkDisk = true,
  }) {
    assert(files.length == newNames.length);

    final errors = List<String?>.filled(files.length, null);
    final targetBuckets = <String, List<int>>{};

    for (var i = 0; i < files.length; i++) {
      final name = newNames[i];
      final intrinsic = _intrinsicError(name);
      if (intrinsic != null) {
        errors[i] = intrinsic;
        continue;
      }

      final dir = p.normalize(files[i].directory);
      final key = p.join(dir, name).toLowerCase();
      (targetBuckets[key] ??= []).add(i);
    }

    for (final indexes in targetBuckets.values) {
      if (indexes.length < 2) continue;
      for (final i in indexes) {
        errors[i] ??= 'Duplicate target name';
      }
    }

    if (checkDisk) {
      for (var i = 0; i < files.length; i++) {
        if (errors[i] != null) continue;
        final file = files[i];
        final newName = newNames[i];
        if (newName == file.originalName) continue;

        final target = p.normalize(p.join(file.directory, newName));
        final targetKey = target.toLowerCase();
        if (targetKey == p.normalize(file.path).toLowerCase()) continue;

        final exists =
            File(target).existsSync() || Directory(target).existsSync();
        if (!exists) continue;

        if (!_occupantLeaving(
          files: files,
          newNames: newNames,
          targetKey: targetKey,
        )) {
          errors[i] = 'File already exists';
        }
      }
    }

    return errors;
  }

  bool _occupantLeaving({
    required List<RenameFileItem> files,
    required List<String> newNames,
    required String targetKey,
  }) {
    for (var i = 0; i < files.length; i++) {
      if (p.normalize(files[i].path).toLowerCase() != targetKey) continue;
      return newNames[i] != files[i].originalName;
    }
    return false;
  }

  String? _intrinsicError(String name) {
    if (name.isEmpty) return 'Name is empty';
    if (name == '.' || name == '..') return 'Invalid name';
    if (_illegal.hasMatch(name)) return 'Contains illegal characters';
    if (name.endsWith(' ') || name.endsWith('.')) {
      return 'Cannot end with space or period';
    }
    return null;
  }

  List<PreviewRow> annotate(List<PreviewRow> rows, {bool checkDisk = true}) {
    final errors = validate(
      files: rows.map((r) => r.file).toList(growable: false),
      newNames: rows.map((r) => r.newName).toList(growable: false),
      checkDisk: checkDisk,
    );
    return [
      for (var i = 0; i < rows.length; i++)
        PreviewRow(
          file: rows[i].file,
          newName: rows[i].newName,
          error: errors[i],
        ),
    ];
  }
}
