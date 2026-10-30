import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/main.dart';
import 'package:vidric/screens/controller_screen.dart';

void main() {
  testWidgets('ViDric App smoke test mounts ControllerScreen in landscape', (WidgetTester tester) async {
    // Set test surface to standard Android landscape resolution (1280x720)
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(const ViDricApp());
    await tester.pumpAndSettle();

    // Verify that the Cockpit ControllerScreen is mounted
    expect(find.byType(ControllerScreen), findsOneWidget);

    // Verify key cockpit labels exist
    expect(find.text('STEERING MODE'), findsOneWidget);
    expect(find.text('COCKPIT READY'), findsOneWidget);
  });
}
