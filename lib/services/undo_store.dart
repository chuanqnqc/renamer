import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/models/undo_batch.dart';

class UndoStore {
  File? _file;

  Future<File> _ensureFile() async {
    if (_file != null) return _file!;
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'filerenamer', 'undo'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _file = File(p.join(dir.path, 'last.json'));
    return _file!;
  }

  Future<UndoBatch?> load() async {
    final file = await _ensureFile();
    if (!file.existsSync()) return null;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return UndoBatch.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(UndoBatch batch) async {
    final file = await _ensureFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(batch.toJson()),
    );
  }

  Future<void> clear() async {
    final file = await _ensureFile();
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
