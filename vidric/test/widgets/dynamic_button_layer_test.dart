import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidric/services/custom_button_service.dart';
import 'package:vidric/widgets/dynamic_button_layer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CustomButtonService.resetInstance();
    await CustomButtonService.instance.init();
  });

  group('DynamicButtonLayer Widget Tests', () {
    testWidgets('renders preset buttons and triggers toggle callback', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? triggeredVjoy;
      bool? isPressedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicButtonLayer(
              onButtonStateChanged: (vjoy, isPressed) {
                triggeredVjoy = vjoy;
                isPressedState = isPressed;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify preset buttons exist
      expect(find.text('LIGHTS'), findsOneWidget);
      expect(find.text('HAZARD'), findsOneWidget);
      expect(find.text('WIPER'), findsOneWidget);

      // Tap LIGHTS toggle button (vJoy 1)
      await tester.tap(find.text('LIGHTS'));
      await tester.pumpAndSettle();

      expect(triggeredVjoy, 1);
      expect(isPressedState, true);
      expect(CustomButtonService.instance.isButtonToggled(1), true);

      // Tap LIGHTS again to turn off
      await tester.tap(find.text('LIGHTS'));
      await tester.pumpAndSettle();

      expect(triggeredVjoy, 1);
      expect(isPressedState, false);
      expect(CustomButtonService.instance.isButtonToggled(1), false);
    });

    testWidgets('shows edit toolbar and enables dragging when edit mode is active', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      CustomButtonService.instance.toggleEditMode(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicButtonLayer(
              onButtonStateChanged: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Edit Toolbar
      expect(find.text('EDIT MODE: DRAG & DROP'), findsOneWidget);
      expect(find.text('TAMBAH (+)'), findsOneWidget);
      expect(find.text('GRID: ON'), findsOneWidget);
      expect(find.text('SELESAI'), findsOneWidget);

      // Tap SELESAI to exit Edit Mode
      await tester.tap(find.text('SELESAI'));
      await tester.pumpAndSettle();

      expect(CustomButtonService.instance.editMode, false);
    });
  });
}
