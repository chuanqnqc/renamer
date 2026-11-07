import 'rule_codec.dart';
import 'rename_rule.dart';

class RulePreset {
  RulePreset({
    required this.id,
    required this.name,
    required this.rules,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  List<RenameRule> rules;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'version': 1,
        'id': id,
        'name': name,
        'updatedAt': updatedAt.toIso8601String(),
        'rules': RuleCodec.encodeAll(rules),
      };

  static RulePreset fromJson(Map<String, dynamic> json) {
    final rulesRaw = json['rules'];
    if (rulesRaw is! List) {
      throw const FormatException('Preset is missing rules');
    }
    return RulePreset(
      id: json['id'] as String? ??
          'preset_${DateTime.now().microsecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Untitled',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      rules: RuleCodec.decodeAll(rulesRaw),
    );
  }

  RulePreset copyWithRules(List<RenameRule> nextRules) {
    return RulePreset(
      id: id,
      name: name,
      rules: [for (final r in nextRules) r.copy()],
      updatedAt: DateTime.now(),
    );
  }
}
