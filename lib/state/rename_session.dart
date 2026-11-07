import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../core/engine/rule_engine.dart';
import '../core/models/preview_row.dart';
import '../core/models/rename_file.dart';
import '../core/models/rename_rule.dart';
import '../core/validation/name_validator.dart';
import '../services/file_system_service.dart';

/// Holds files + ordered rules and computes a validated live preview.
class RenameSession extends ChangeNotifier {
  RenameSession({
    RuleEngine? engine,
    NameValidator? validator,
    FileSystemService? fileSystem,
  })  : _engine = engine ?? const RuleEngine(),
        _validator = validator ?? NameValidator(),
        _fileSystem = fileSystem ?? FileSystemService();

  final RuleEngine _engine;
  final NameValidator _validator;
  final FileSystemService _fileSystem;

  final List<RenameFileItem> _files = [];
  final List<RenameRule> _rules = [];

  bool _applying = false;
  String? _statusMessage;

  List<RenameFileItem> get files => List.unmodifiable(_files);
  List<RenameRule> get rules => List.unmodifiable(_rules);

  int get fileCount => _files.length;
  bool get isEmpty => _files.isEmpty;
  bool get isApplying => _applying;
  String? get statusMessage => _statusMessage;

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

      // Refresh session paths/names for successful renames.
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
}
