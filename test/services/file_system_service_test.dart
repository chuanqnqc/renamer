import 'dart:io';

import 'package:filerenamer/services/file_system_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final service = FileSystemService();

  test('renames files and supports swaps via two-phase', () async {
    final dir = Directory.systemTemp.createTempSync('filerenamer_fs_');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    final a = File(p.join(dir.path, 'a.txt'))..writeAsStringSync('A');
    final b = File(p.join(dir.path, 'b.txt'))..writeAsStringSync('B');
    final c = File(p.join(dir.path, 'c.txt'))..writeAsStringSync('C');

    final result = await service.renameAll(
      fromPaths: [a.path, b.path, c.path],
      newNames: ['b.txt', 'a.txt', 'c_renamed.txt'],
    );

    expect(result.ok, isTrue);
    expect(File(p.join(dir.path, 'a.txt')).readAsStringSync(), 'B');
    expect(File(p.join(dir.path, 'b.txt')).readAsStringSync(), 'A');
    expect(File(p.join(dir.path, 'c_renamed.txt')).readAsStringSync(), 'C');
    expect(File(p.join(dir.path, 'c.txt')).existsSync(), isFalse);
  });
}
