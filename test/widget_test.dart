import 'package:filerenamer/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FileRenamer shell shows panels and actions', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FileRenamerApp());

    expect(find.text('FileRenamer'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });
}
