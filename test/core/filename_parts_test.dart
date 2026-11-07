import 'package:filerenamer/core/engine/filename_parts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses normal names', () {
    final parts = FilenameParts.parse('photo.jpg');
    expect(parts.stem, 'photo');
    expect(parts.extension, '.jpg');
  });

  test('treats extension-only names as empty stem', () {
    final parts = FilenameParts.parse('.jpg');
    expect(parts.stem, isEmpty);
    expect(parts.extension, '.jpg');
    expect(parts.fullName, '.jpg');
  });

  test('keeps multi-dot stems intact', () {
    final parts = FilenameParts.parse('archive.tar.gz');
    expect(parts.stem, 'archive.tar');
    expect(parts.extension, '.gz');
  });
}
