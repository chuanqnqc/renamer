import '../../services/file_system_service.dart';

/// Last successful rename batch, used for single-level undo.
class UndoBatch {
  const UndoBatch({
    required this.mappings,
    required this.createdAt,
  });

  final List<RenameMapping> mappings;
  final DateTime createdAt;

  bool get isEmpty => mappings.isEmpty;

  Map<String, dynamic> toJson() => {
        'createdAt': createdAt.toIso8601String(),
        'mappings': [
          for (final m in mappings)
            {'fromPath': m.fromPath, 'toPath': m.toPath},
        ],
      };

  static UndoBatch? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final raw = json['mappings'];
    if (raw is! List || raw.isEmpty) return null;
    final mappings = <RenameMapping>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final from = item['fromPath'] as String?;
      final to = item['toPath'] as String?;
      if (from == null || to == null) continue;
      mappings.add(RenameMapping(fromPath: from, toPath: to));
    }
    if (mappings.isEmpty) return null;
    return UndoBatch(
      mappings: mappings,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
