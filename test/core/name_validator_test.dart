import 'dart:io';

import 'package:filerenamer/core/models/rename_file.dart';
import 'package:filerenamer/core/validation/name_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final validator = NameValidator();

  test('flags empty, illegal, and trailing-dot names', () {
    final files = [
      RenameFileItem(path: r'E:\x\a.txt'),
      RenameFileItem(path: r'E:\x\b.txt'),
      RenameFileItem(path: r'E:\x\c.txt'),
    ];
    final errors = validator.validate(
      files: files,
      newNames: ['', 'bad:name.txt', 'ok.'],
      checkDisk: false,
    );
    expect(errors[0], 'Name is empty');
    expect(errors[1], 'Contains illegal characters');
    expect(errors[2], 'Cannot end with space or period');
  });

  test('flags duplicate targets in the same folder', () {
    final files = [
      RenameFileItem(path: r'E:\x\a.txt'),
      RenameFileItem(path: r'E:\x\b.txt'),
    ];
    final errors = validator.validate(
      files: files,
      newNames: ['same.txt', 'same.txt'],
      checkDisk: false,
    );
    expect(errors[0], 'Duplicate target name');
    expect(errors[1], 'Duplicate target name');
  });

  test('flags existing on-disk collision when occupant is not leaving', () {
    final dir = Directory.systemTemp.createTempSync('filerenamer_val_');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    final existing = File(p.join(dir.path, 'taken.txt'))..writeAsStringSync('x');
    final source = File(p.join(dir.path, 'source.txt'))..writeAsStringSync('y');

    final files = [
      RenameFileItem(path: source.path),
    ];
    final errors = validator.validate(
      files: files,
      newNames: [p.basename(existing.path)],
      checkDisk: true,
    );
    expect(errors.single, 'File already exists');
  });

  test('allows swap when both files are in the batch', () {
    final dir = Directory.systemTemp.createTempSync('filerenamer_swap_');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    final a = File(p.join(dir.path, 'a.txt'))..writeAsStringSync('a');
    final b = File(p.join(dir.path, 'b.txt'))..writeAsStringSync('b');

    final files = [
      RenameFileItem(path: a.path),
      RenameFileItem(path: b.path),
    ];
    final errors = validator.validate(
      files: files,
      newNames: ['b.txt', 'a.txt'],
      checkDisk: true,
    );
    expect(errors, [null, null]);
  });
}
