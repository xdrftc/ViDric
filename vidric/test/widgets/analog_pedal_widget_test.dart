import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/widgets/analog_pedal_widget.dart';

void main() {
  group('AnalogPedalWidget Tests', () {
    testWidgets('renders pedal label and percentage readout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnalogPedalWidget(
                label: 'THROTTLE',
                assetPath: 'assets/images/pedal_gas_tight.png',
                activeColor: const Color(0xFF00E676),
                value: 0.75,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('THROTTLE'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('vertical drag updates pedal value and release auto-springs to 0.0', (WidgetTester tester) async {
      double pedalValue = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnalogPedalWidget(
                label: 'BRAKE',
                assetPath: 'assets/images/pedal_rem_tight.png',
                activeColor: const Color(0xFFFF1744),
                value: pedalValue,
                onChanged: (val) {
                  pedalValue = val;
                },
              ),
            ),
          ),
        ),
      );

      final pedalCenter = tester.getCenter(find.byType(AnalogPedalWidget));
      final gesture = await tester.startGesture(Offset(pedalCenter.dx, pedalCenter.dy + 40));
      await tester.pump();

      // Drag upward
      await gesture.moveTo(Offset(pedalCenter.dx, pedalCenter.dy - 40));
      await tester.pump();
      expect(pedalValue, greaterThan(0.0));

      // Release finger
      await gesture.up();
      await tester.pump();
      expect(pedalValue, equals(0.0)); // Auto-spring returned
    });
  });
}

