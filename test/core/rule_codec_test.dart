import 'package:filerenamer/core/models/rename_rule.dart';
import 'package:filerenamer/core/models/rule_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips all rule types', () {
    final rules = <RenameRule>[
      PrefixRule(id: '1', prefix: 'pre_', enabled: false),
      SuffixRule(id: '2', suffix: '_x'),
      FindReplaceRule(
        id: '3',
        find: 'a',
        replace: 'b',
        caseSensitive: false,
      ),
      RemoveCharsRule(id: '4', count: 2, from: CharRemoveFrom.end),
      InsertAtPositionRule(
        id: '5',
        text: 'Z',
        position: 1,
        from: CharRemoveFrom.start,
      ),
      NameCaseRule(id: '6', mode: NameCaseMode.title),
      NumberingRule(
        id: '7',
        start: 3,
        step: 2,
        pad: 2,
        position: InsertPosition.end,
        separator: '-',
      ),
      InsertDateRule(
        id: '8',
        pattern: 'yyyy',
        position: InsertPosition.end,
        separator: '',
      ),
      ExtensionCaseRule(id: '9', mode: ExtensionCaseMode.upper),
      ClearNameRule(id: '10'),
    ];

    final encoded = RuleCodec.encodeAll(rules);
    final decoded = RuleCodec.decodeAll(encoded);

    expect(decoded.length, rules.length);
    for (var i = 0; i < rules.length; i++) {
      expect(RuleCodec.encode(decoded[i]), RuleCodec.encode(rules[i]));
    }
  });
}
