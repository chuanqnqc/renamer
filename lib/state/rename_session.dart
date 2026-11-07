import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../core/engine/rule_engine.dart';
import '../core/models/preset.dart';
import '../core/models/preview_row.dart';
import '../core/models/rename_file.dart';
import '../core/models/rename_rule.dart';
import '../core/models/undo_batch.dart';
import '../core/validation/name_validator.dart';
import '../services/file_system_service.dart';
import '../services/preset_store.dart';
import '../services/undo_store.dart';

/// Holds files + ordered rules and computes a validated live preview.
class RenameSession extends ChangeNotifier {
  RenameSession({
    RuleEngine? engine,
    NameValidator? validator,
    FileSystemService? fileSystem,
    PresetStore? presetStore,
    UndoStore? undoStore,
  })  : _engine = engine ?? const RuleEngine(),
        _validator = validator ?? NameValidator(),
        _fileSystem = fileSystem ?? FileSystemService(),
        _presetStore = presetStore ?? PresetStore(),
        _undoStore = undoStore ?? UndoStore();

  final RuleEngine _engine;
  final NameValidator _validator;
  final FileSystemService _fileSystem;
  final PresetStore _presetStore;
  final UndoStore _undoStore;

  final List<RenameFileItem> _files = [];
  final List<RenameRule> _rules = [];
  List<RulePreset> _presets = [];
  UndoBatch? _lastUndo;

  bool _applying = false;
  bool _ready = false;
  String? _statusMessage;

  List<RenameFileItem> get files => List.unmodifiable(_files);
  List<RenameRule> get rules => List.unmodifiable(_rules);
  List<RulePreset> get presets => List.unmodifiable(_presets);

  int get fileCount => _files.length;
  bool get isEmpty => _files.isEmpty;
  bool get isApplying => _applying;
  bool get isReady => _ready;
  String? get statusMessage => _statusMessage;
  bool get canUndo => !_applying && _lastUndo != null && !_lastUndo!.isEmpty;
  int get undoCount => _lastUndo?.mappings.length ?? 0;

  PresetStore get presetStore => _presetStore;

  List<PreviewRow> get preview {
    final raw = <PreviewRow>[
      for (var i = 0; i < _files.length; i++)
        PreviewRow(
          file: _files[i],
          newName: _engine.apply(
            originalName: _files[i].originalName,
            rules: _rules,
            index: i,
            total: _files.length,
          ),
        ),
    ];
    return _validator.annotate(raw, checkDisk: true);
  }

  bool get hasPreviewErrors => preview.any((r) => r.hasError);

  bool get canApply {
    if (_applying || _files.isEmpty) return false;
    final rows = preview;
    if (rows.any((r) => r.hasError)) return false;
    return rows.any((r) => r.willChange);
  }

  int get changeCount => preview.where((r) => r.willChange).length;

  Future<void> initialize() async {
    try {
      _presets = await _presetStore.list();
      _lastUndo = await _undoStore.load();
    } catch (_) {
      // Stores may be unavailable in tests or before platform channels bind.
      _presets = [];
      _lastUndo = null;
    }
    _ready = true;
    notifyListeners();
  }

  void addPaths(Iterable<String> paths) {
    var changed = false;
    final existing = _files.map((f) => p.normalize(f.path)).toSet();

    for (final raw in paths) {
      final normalized = p.normalize(raw);
      if (existing.contains(normalized)) continue;
      final name = p.basename(normalized);
      if (name.isEmpty || name == '.' || name == '..') continue;

      _files.add(RenameFileItem(path: normalized));
      existing.add(normalized);
      changed = true;
    }

    if (changed) {
      _statusMessage = null;
      notifyListeners();
    }
  }

  void removeAt(int index) {
    if (index < 0 || index >= _files.length) return;
    _files.removeAt(index);
    _statusMessage = null;
    notifyListeners();
  }

  void clearFiles() {
    if (_files.isEmpty) return;
    _files.clear();
    _statusMessage = null;
    notifyListeners();
  }

  void addRule(RenameRule rule) {
    _rules.add(rule);
    _statusMessage = null;
    notifyListeners();
  }

  void removeRuleAt(int index) {
    if (index < 0 || index >= _rules.length) return;
    _rules.removeAt(index);
    _statusMessage = null;
    notifyListeners();
  }

  void setRuleEnabled(int index, bool enabled) {
    if (index < 0 || index >= _rules.length) return;
    if (_rules[index].enabled == enabled) return;
    _rules[index].enabled = enabled;
    _statusMessage = null;
    notifyListeners();
  }

  /// Reorders rules. [newIndex] is the final destination after removal
  /// (as provided by [ReorderableListView.onReorderItem]).
  void reorderRules(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _rules.length ||
        newIndex < 0 ||
        newIndex >= _rules.length ||
        oldIndex == newIndex) {
      return;
    }
    final rule = _rules.removeAt(oldIndex);
    _rules.insert(newIndex, rule);
    _statusMessage = null;
    notifyListeners();
  }

  void replaceRules(List<RenameRule> rules) {
    _rules
      ..clear()
      ..addAll(rules.map((r) => r.copy()));
    _statusMessage = null;
    notifyListeners();
  }

  /// Notify after in-place edits to a rule's fields.
  void touchRules() {
    _statusMessage = null;
    notifyListeners();
  }

  void clearStatus() {
    if (_statusMessage == null) return;
    _statusMessage = null;
    notifyListeners();
  }

  Future<void> refreshPresets() async {
    _presets = await _presetStore.list();
    notifyListeners();
  }

  Future<RulePreset> savePreset(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Preset name is required');
    }
    String? existingId;
    for (final preset in _presets) {
      if (preset.name.toLowerCase() == trimmed.toLowerCase()) {
        existingId = preset.id;
        break;
      }
    }
    final preset = RulePreset(
      id: existingId ?? 'preset_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
      rules: [for (final r in _rules) r.copy()],
    );
    await _presetStore.save(preset);
    await refreshPresets();
    _statusMessage = 'Saved preset "$trimmed".';
    notifyListeners();
    return preset;
  }

  void loadPreset(RulePreset preset) {
    replaceRules(preset.rules);
    _statusMessage = 'Loaded preset "${preset.name}".';
    notifyListeners();
  }

  Future<void> deletePreset(String id) async {
    await _presetStore.delete(id);
    await refreshPresets();
  }

  Future<RulePreset> importPreset(String path) async {
    final preset = await _presetStore.importFile(path);
    await refreshPresets();
    _statusMessage = 'Imported preset "${preset.name}".';
    notifyListeners();
    return preset;
  }

  Future<void> exportPreset(RulePreset preset, String path) async {
    await _presetStore.exportFile(preset, path);
    _statusMessage = 'Exported preset "${preset.name}".';
    notifyListeners();
  }

  Future<RenameBatchResult?> applyRenames() async {
    if (!canApply) return null;

    final rows = preview;
    _applying = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final result = await _fileSystem.renameAll(
        fromPaths: rows.map((r) => r.file.path).toList(growable: false),
        newNames: rows.map((r) => r.newName).toList(growable: false),
      );

      final byFrom = {
        for (final m in result.succeeded) p.normalize(m.fromPath): m,
      };
      for (var i = 0; i < _files.length; i++) {
        final mapping = byFrom[p.normalize(_files[i].path)];
        if (mapping == null) continue;
        _files[i] = RenameFileItem(
          path: mapping.toPath,
          originalName: p.basename(mapping.toPath),
        );
      }

      if (result.succeeded.isNotEmpty) {
        _lastUndo = UndoBatch(
          mappings: List.unmodifiable(result.succeeded),
          createdAt: DateTime.now(),
        );
        await _undoStore.save(_lastUndo!);
      }

      if (result.ok) {
        _statusMessage =
            'Renamed ${result.successCount} file${result.successCount == 1 ? '' : 's'}.';
      } else {
        _statusMessage =
            'Renamed ${result.successCount}, failed ${result.failureCount}.';
      }
      return result;
    } finally {
      _applying = false;
      notifyListeners();
    }
  }

  Future<RenameBatchResult?> undoLast() async {
    final batch = _lastUndo;
    if (batch == null || batch.isEmpty || _applying) return null;

    final fromPaths = [
      for (final m in batch.mappings) p.normalize(m.toPath),
    ];
    final newNames = [
      for (final m in batch.mappings) p.basename(m.fromPath),
    ];
    final files = [
      for (final path in fromPaths) RenameFileItem(path: path),
    ];
    final errors = _validator.validate(
      files: files,
      newNames: newNames,
      checkDisk: true,
    );
    if (errors.any((e) => e != null)) {
      _statusMessage = 'Cannot undo: ${errors.firstWhere((e) => e != null)}';
      notifyListeners();
      return null;
    }

    _applying = true;
    notifyListeners();

    try {
      final result = await _fileSystem.renameAll(
        fromPaths: fromPaths,
        newNames: newNames,
      );

      final byFrom = {
        for (final m in result.succeeded) p.normalize(m.fromPath): m,
      };
      for (var i = 0; i < _files.length; i++) {
        final mapping = byFrom[p.normalize(_files[i].path)];
        if (mapping == null) continue;
        _files[i] = RenameFileItem(
          path: mapping.toPath,
          originalName: p.basename(mapping.toPath),
        );
      }

      if (result.ok) {
        _lastUndo = null;
        await _undoStore.clear();
        _statusMessage =
            'Undid ${result.successCount} rename${result.successCount == 1 ? '' : 's'}.';
      } else {
        _statusMessage =
            'Undo partially failed (${result.failureCount} error${result.failureCount == 1 ? '' : 's'}).';
      }
      return result;
    } finally {
      _applying = false;
      notifyListeners();
    }
  }
}
