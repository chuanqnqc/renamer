import 'package:filerenamer/core/engine/rule_engine.dart';
import 'package:filerenamer/core/models/rename_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = RuleEngine();
  final now = DateTime(2026, 11, 6, 15, 30);

  test('chains enabled rules in order and skips disabled', () {
    final rules = <RenameRule>[
      PrefixRule(id: '1', prefix: 'A_'),
      SuffixRule(id: '2', suffix: '_Z', enabled: false),
      NameCaseRule(id: '3', mode: NameCaseMode.lower),
      FindReplaceRule(id: '4', find: 'photo', replace: 'img'),
    ];

    final out = engine.apply(
      originalName: 'Photo_001.JPG',
      rules: rules,
      index: 0,
      total: 1,
    );

    // Prefix → A_Photo_001.JPG; suffix skipped; lower stem → a_photo_001.JPG;
    // then replace photo → img.
    expect(out, 'a_img_001.JPG');
  });

  test('remove chars from start and end of stem', () {
    final start = engine.apply(
      originalName: 'abcdef.txt',
      rules: [RemoveCharsRule(id: '1', count: 2, from: CharRemoveFrom.start)],
      index: 0,
      total: 1,
    );
    final end = engine.apply(
      originalName: 'abcdef.txt',
      rules: [RemoveCharsRule(id: '1', count: 3, from: CharRemoveFrom.end)],
      index: 0,
      total: 1,
    );
    expect(start, 'cdef.txt');
    expect(end, 'abc.txt');
  });

  test('numbering pads and positions correctly', () {
    final names = engine.applyAll(
      originalNames: ['a.txt', 'b.txt', 'c.txt'],
      rules: [
        NumberingRule(
          id: '1',
          start: 5,
          step: 2,
          pad: 3,
          position: InsertPosition.start,
          separator: '-',
        ),
      ],
    );
    expect(names, ['005-a.txt', '007-b.txt', '009-c.txt']);
  });

  test('insert date and extension case', () {
    final out = engine.apply(
      originalName: 'Report.PDF',
      rules: [
        InsertDateRule(
          id: '1',
          pattern: 'yyyyMMdd',
          position: InsertPosition.start,
          separator: '_',
        ),
        ExtensionCaseRule(id: '2', mode: ExtensionCaseMode.lower),
      ],
      index: 0,
      total: 1,
      now: now,
    );
    expect(out, '20261106_Report.pdf');
  });

  test('find replace can be case-insensitive', () {
    final out = engine.apply(
      originalName: 'MyPhoto.JPG',
      rules: [
        FindReplaceRule(
          id: '1',
          find: 'photo',
          replace: 'pic',
          caseSensitive: false,
        ),
      ],
      index: 0,
      total: 1,
    );
    expect(out, 'Mypic.JPG');
  });
}
