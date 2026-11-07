import 'package:filerenamer/core/models/rename_rule.dart';
import 'package:filerenamer/state/rename_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('addPaths skips duplicates and builds identity preview', () {
    final session = RenameSession();

    session.addPaths([
      r'E:\photos\a.jpg',
      r'E:\photos\b.jpg',
      r'E:\photos\a.jpg',
    ]);

    expect(session.fileCount, 2);
    expect(session.preview.map((r) => r.file.originalName), ['a.jpg', 'b.jpg']);
    expect(session.preview.map((r) => r.newName), ['a.jpg', 'b.jpg']);
    expect(session.preview.every((r) => !r.willChange), isTrue);
  });

  test('rules update live preview and disabled rules are skipped', () {
    final session = RenameSession()
      ..addPaths([r'E:\photos\Photo.JPG'])
      ..addRule(PrefixRule(id: '1', prefix: 'new_'))
      ..addRule(NameCaseRule(id: '2', mode: NameCaseMode.lower));

    expect(session.preview.single.newName, 'new_photo.JPG');

    session.setRuleEnabled(0, false);
    expect(session.preview.single.newName, 'photo.JPG');
  });

  test('canApply is false when preview has duplicate targets', () {
    final session = RenameSession()
      ..addPaths([r'E:\photos\a.jpg', r'E:\photos\b.jpg'])
      ..addRule(FindReplaceRule(id: '1', find: 'a.jpg', replace: 'same.jpg'))
      ..addRule(FindReplaceRule(id: '2', find: 'b.jpg', replace: 'same.jpg'));

    expect(session.hasPreviewErrors, isTrue);
    expect(session.canApply, isFalse);
  });

  test('clearFiles empties the session', () {
    final session = RenameSession()..addPaths([r'E:\x\one.txt']);
    session.clearFiles();
    expect(session.isEmpty, isTrue);
    expect(session.preview, isEmpty);
  });

  test('removeAt removes a single file', () {
    final session = RenameSession()
      ..addPaths([r'E:\x\one.txt', r'E:\x\two.txt']);
    session.removeAt(0);
    expect(session.files.single.originalName, 'two.txt');
  });
}
