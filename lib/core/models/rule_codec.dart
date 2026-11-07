import 'rename_rule.dart';

/// JSON encode/decode for [RenameRule] stacks (presets import/export).
abstract final class RuleCodec {
  static Map<String, dynamic> encode(RenameRule rule) => switch (rule) {
        final PrefixRule r => {
            'type': 'prefix',
            'id': r.id,
            'enabled': r.enabled,
            'prefix': r.prefix,
          },
        final SuffixRule r => {
            'type': 'suffix',
            'id': r.id,
            'enabled': r.enabled,
            'suffix': r.suffix,
          },
        final FindReplaceRule r => {
            'type': 'findReplace',
            'id': r.id,
            'enabled': r.enabled,
            'find': r.find,
            'replace': r.replace,
            'caseSensitive': r.caseSensitive,
          },
        final RemoveCharsRule r => {
            'type': 'removeChars',
            'id': r.id,
            'enabled': r.enabled,
            'count': r.count,
            'from': r.from.name,
          },
        final InsertAtPositionRule r => {
            'type': 'insertAtPosition',
            'id': r.id,
            'enabled': r.enabled,
            'text': r.text,
            'position': r.position,
            'from': r.from.name,
          },
        final NameCaseRule r => {
            'type': 'nameCase',
            'id': r.id,
            'enabled': r.enabled,
            'mode': r.mode.name,
          },
        final NumberingRule r => {
            'type': 'numbering',
            'id': r.id,
            'enabled': r.enabled,
            'start': r.start,
            'step': r.step,
            'pad': r.pad,
            'position': r.position.name,
            'separator': r.separator,
          },
        final InsertDateRule r => {
            'type': 'insertDate',
            'id': r.id,
            'enabled': r.enabled,
            'pattern': r.pattern,
            'position': r.position.name,
            'separator': r.separator,
          },
        final ExtensionCaseRule r => {
            'type': 'extensionCase',
            'id': r.id,
            'enabled': r.enabled,
            'mode': r.mode.name,
          },
        final ClearNameRule r => {
            'type': 'clearName',
            'id': r.id,
            'enabled': r.enabled,
          },
      };

  static RenameRule decode(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final id = json['id'] as String? ?? RenameRuleFactory.newId();
    final enabled = json['enabled'] as bool? ?? true;

    return switch (type) {
      'prefix' => PrefixRule(
          id: id,
          enabled: enabled,
          prefix: json['prefix'] as String? ?? '',
        ),
      'suffix' => SuffixRule(
          id: id,
          enabled: enabled,
          suffix: json['suffix'] as String? ?? '',
        ),
      'findReplace' => FindReplaceRule(
          id: id,
          enabled: enabled,
          find: json['find'] as String? ?? '',
          replace: json['replace'] as String? ?? '',
          caseSensitive: json['caseSensitive'] as bool? ?? true,
        ),
      'removeChars' => RemoveCharsRule(
          id: id,
          enabled: enabled,
          count: (json['count'] as num?)?.toInt() ?? 1,
          from: _charFrom(json['from']),
        ),
      'insertAtPosition' => InsertAtPositionRule(
          id: id,
          enabled: enabled,
          text: json['text'] as String? ?? '',
          position: (json['position'] as num?)?.toInt() ?? 0,
          from: _charFrom(json['from']),
        ),
      'nameCase' => NameCaseRule(
          id: id,
          enabled: enabled,
          mode: _nameCase(json['mode']),
        ),
      'numbering' => NumberingRule(
          id: id,
          enabled: enabled,
          start: (json['start'] as num?)?.toInt() ?? 1,
          step: (json['step'] as num?)?.toInt() ?? 1,
          pad: (json['pad'] as num?)?.toInt() ?? 0,
          position: _insertPos(json['position']),
          separator: json['separator'] as String? ?? '_',
        ),
      'insertDate' => InsertDateRule(
          id: id,
          enabled: enabled,
          pattern: json['pattern'] as String? ?? 'yyyy-MM-dd',
          position: _insertPos(json['position']),
          separator: json['separator'] as String? ?? '_',
        ),
      'extensionCase' => ExtensionCaseRule(
          id: id,
          enabled: enabled,
          mode: _extCase(json['mode']),
        ),
      'clearName' => ClearNameRule(id: id, enabled: enabled),
      _ => throw FormatException('Unknown rule type: $type'),
    };
  }

  static List<Map<String, dynamic>> encodeAll(List<RenameRule> rules) =>
      [for (final rule in rules) encode(rule)];

  static List<RenameRule> decodeAll(List<dynamic> list) => [
        for (final item in list)
          decode(Map<String, dynamic>.from(item as Map)),
      ];

  static CharRemoveFrom _charFrom(Object? raw) =>
      raw == 'end' ? CharRemoveFrom.end : CharRemoveFrom.start;

  static InsertPosition _insertPos(Object? raw) =>
      raw == 'end' ? InsertPosition.end : InsertPosition.start;

  static NameCaseMode _nameCase(Object? raw) => switch (raw) {
        'upper' => NameCaseMode.upper,
        'title' => NameCaseMode.title,
        'camel' => NameCaseMode.camel,
        _ => NameCaseMode.lower,
      };

  static ExtensionCaseMode _extCase(Object? raw) =>
      raw == 'upper' ? ExtensionCaseMode.upper : ExtensionCaseMode.lower;
}
