import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/widgets/h_pattern_shifter_widget.dart';

void main() {
  group('HPatternShifterWidget Tests', () {
    testWidgets('renders H-Pattern shifter with active gear indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: HPatternShifterWidget(
                activeGear: 'N',
                onGearChanged: (gear, vjoy) {},
              ),
            ),
          ),
        ),
      );

      // Verify Neutral knob indicator
      expect(find.text('N'), findsOneWidget);
    });

    testWidgets('tapping gear slot triggers onGearChanged with corresponding vJoy button', (WidgetTester tester) async {
      String selectedGear = 'N';
      int? selectedVJoy;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: HPatternShifterWidget(
                activeGear: selectedGear,
                onGearChanged: (gear, vjoy) {
                  selectedGear = gear;
                  selectedVJoy = vjoy;
                },
              ),
            ),
          ),
        ),
      );

      // Tap slot '1' (Gears 1-6 map to vJoy Buttons 12-17)
      final slot1Finder = find.text('1');
      expect(slot1Finder, findsOneWidget);

      await tester.tap(slot1Finder);
      await tester.pumpAndSettle();

      expect(selectedGear, equals('1'));
      expect(selectedVJoy, equals(12));
    });
  });
}
