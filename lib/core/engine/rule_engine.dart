import '../models/rename_rule.dart';
import 'rename_context.dart';

/// Applies enabled rules in order to a filename.
class RuleEngine {
  const RuleEngine();

  String apply({
    required String originalName,
    required List<RenameRule> rules,
    required int index,
    required int total,
    DateTime? now,
  }) {
    final ctx = RenameContext(
      index: index,
      total: total,
      originalName: originalName,
      now: now,
    );
    var name = originalName;
    for (final rule in rules) {
      if (!rule.enabled) continue;
      name = rule.apply(name, ctx);
    }
    return name;
  }

  List<String> applyAll({
    required List<String> originalNames,
    required List<RenameRule> rules,
    DateTime? now,
  }) {
    final total = originalNames.length;
    return [
      for (var i = 0; i < total; i++)
        apply(
          originalName: originalNames[i],
          rules: rules,
          index: i,
          total: total,
          now: now,
        ),
    ];
  }
}
