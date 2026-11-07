import 'package:filerenamer/core/models/rename_rule.dart';
import 'package:filerenamer/state/rename_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reorderRules changes pipeline order and preview', () {
    final session = RenameSession()
      ..addPaths([r'E:\x\name.txt'])
      ..addRule(PrefixRule(id: '1', prefix: 'PRE_'))
      ..addRule(FindReplaceRule(id: '2', find: 'PRE_', replace: 'GONE_'));

    // Prefix then replace: name → PRE_name → GONE_name
    expect(session.preview.single.newName, 'GONE_name.txt');
    expect(session.rules.map((r) => r.id), ['1', '2']);

    // Move replace before prefix: name → name → PRE_name
    session.reorderRules(1, 0);
    expect(session.rules.map((r) => r.id), ['2', '1']);
    expect(session.preview.single.newName, 'PRE_name.txt');
  });

  test('replaceRules replaces the rule stack', () {
    final session = RenameSession()
      ..addRule(PrefixRule(id: 'old', prefix: 'old_'));

    session.replaceRules([
      SuffixRule(id: 'new', suffix: '_new'),
      NameCaseRule(id: 'case', mode: NameCaseMode.upper),
    ]);

    expect(session.rules.map((r) => r.typeLabel), ['Suffix', 'Name case']);
  });
}
