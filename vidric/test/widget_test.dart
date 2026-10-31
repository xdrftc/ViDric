import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/main.dart';
import 'package:vidric/screens/controller_screen.dart';

void main() {
  testWidgets('ViDric App smoke test mounts ControllerScreen with wireframe elements', (WidgetTester tester) async {
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

    // Verify key wireframe action buttons exist
    expect(find.text('MENU'), findsOneWidget);
    expect(find.text('MAP'), findsOneWidget);
    expect(find.text('CAMERA'), findsOneWidget);
    expect(find.text('GYRO CAM : ACTIVE'), findsOneWidget);
    expect(find.text('STEER MODE'), findsOneWidget);

    // Verify pedals and nav cluster exist
    expect(find.text('BRAKE'), findsOneWidget);
    expect(find.text('THROTTLE'), findsOneWidget);
    expect(find.text('ENTER'), findsOneWidget);

    // Toggle to TILT MODE
    await tester.tap(find.text('STEER MODE'));
    await tester.pumpAndSettle();

    // In Tilt Mode, RECENTER button and Horizon readout (0.0°) should appear
    expect(find.text('TILT MODE'), findsOneWidget);
    expect(find.text('RECENTER'), findsOneWidget);
    expect(find.text('0.0°'), findsOneWidget);
    expect(find.text('UNCALIBRATED'), findsOneWidget);

    // Tap RECENTER button to calibrate zero
    await tester.tap(find.text('RECENTER'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Recenter Zero'), findsOneWidget);
    expect(find.text('TILT HORIZON : ACTIVE'), findsOneWidget);

    // Tap Settings Gear Icon to open SettingsScreen
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Verify SettingsScreen opens
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('SELECT MODE'), findsOneWidget);
    expect(find.text('CUSTOMIZATION'), findsOneWidget);

    // Tap KEMBALI to return to ControllerScreen
    await tester.tap(find.text('KEMBALI'));
    await tester.pumpAndSettle();

    expect(find.byType(ControllerScreen), findsOneWidget);
  });
}
