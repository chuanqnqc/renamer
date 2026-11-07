import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/models/preset.dart';

class PresetStore {
  Directory? _dir;

  Future<Directory> _ensureDir() async {
    if (_dir != null) return _dir!;
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'filerenamer', 'presets'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  Future<List<RulePreset>> list() async {
    final dir = await _ensureDir();
    final presets = <RulePreset>[];
    for (final entity in dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final json =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        presets.add(RulePreset.fromJson(json));
      } catch (_) {
        // Skip corrupt files.
      }
    }
    presets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return presets;
  }

  Future<void> save(RulePreset preset) async {
    final dir = await _ensureDir();
    final file = File(p.join(dir.path, '${preset.id}.json'));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(preset.toJson()),
    );
  }

  Future<void> delete(String id) async {
    final dir = await _ensureDir();
    final file = File(p.join(dir.path, '$id.json'));
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<RulePreset> importFile(String path) async {
    final raw = await File(path).readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final preset = RulePreset.fromJson(json);
    // New id so import never overwrites an existing preset silently.
    final imported = RulePreset(
      id: 'preset_${DateTime.now().microsecondsSinceEpoch}',
      name: preset.name,
      rules: [for (final r in preset.rules) r.copy()],
    );
    await save(imported);
    return imported;
  }

  Future<void> exportFile(RulePreset preset, String path) async {
    final file = File(path);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(preset.toJson()),
    );
  }
}
