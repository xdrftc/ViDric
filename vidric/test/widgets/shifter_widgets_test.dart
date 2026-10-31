import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/widgets/sequential_shifter_widget.dart';
import 'package:vidric/widgets/h_pattern_shifter_widget.dart';

void main() {
  group('SequentialShifterWidget Tests', () {
    testWidgets('renders active gear and triggers shift up and shift down pulses', (WidgetTester tester) async {
      String activeGear = 'N';
      int? triggeredVjoy;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SequentialShifterWidget(
                  activeGear: activeGear,
                  onShift: (newGear, vjoyBtn) {
                    setState(() {
                      activeGear = newGear;
                      triggeredVjoy = vjoyBtn;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial gear should be N
      expect(find.text('N'), findsOneWidget);
      expect(find.text('SEQUENTIAL'), findsOneWidget);
      expect(find.text('SHIFT UP'), findsOneWidget);
      expect(find.text('SHIFT DOWN'), findsOneWidget);

      // Tap SHIFT UP -> Should go to 1 and trigger vJoy Button 10
      await tester.tap(find.text('SHIFT UP'));
      await tester.pumpAndSettle();

      expect(activeGear, '1');
      expect(triggeredVjoy, 10);
      expect(find.text('1'), findsOneWidget);

      // Tap SHIFT UP again -> Should go to 2
      await tester.tap(find.text('SHIFT UP'));
      await tester.pumpAndSettle();

      expect(activeGear, '2');
      expect(triggeredVjoy, 10);

      // Tap SHIFT DOWN -> Should go back to 1 and trigger vJoy Button 11
      await tester.tap(find.text('SHIFT DOWN'));
      await tester.pumpAndSettle();

      expect(activeGear, '1');
      expect(triggeredVjoy, 11);

      // Tap SHIFT DOWN -> Should go to N
      await tester.tap(find.text('SHIFT DOWN'));
      await tester.pumpAndSettle();

      expect(activeGear, 'N');
      expect(triggeredVjoy, 11);

      // Tap SHIFT DOWN -> Should go to R
      await tester.tap(find.text('SHIFT DOWN'));
      await tester.pumpAndSettle();

      expect(activeGear, 'R');
      expect(triggeredVjoy, 11);
    });
  });

  group('HPatternShifterWidget Tests', () {
    testWidgets('renders H-pattern gate and maps gear slots to vJoy buttons 12-18', (WidgetTester tester) async {
      String currentGear = 'N';
      int? currentVjoy;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return HPatternShifterWidget(
                  activeGear: currentGear,
                  onGearChanged: (gear, vjoy) {
                    setState(() {
                      currentGear = gear;
                      currentVjoy = vjoy;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Gear Slot 1
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();

      expect(currentGear, '1');
      expect(currentVjoy, 12); // Gear 1 -> vJoy Button 12

      // Tap Gear Slot 6
      await tester.tap(find.text('6').first);
      await tester.pumpAndSettle();

      expect(currentGear, '6');
      expect(currentVjoy, 17); // Gear 6 -> vJoy Button 17

      // Tap Gear Slot R
      await tester.tap(find.text('R').first);
      await tester.pumpAndSettle();

      expect(currentGear, 'R');
      expect(currentVjoy, 18); // Gear R -> vJoy Button 18
    });
  });
}
