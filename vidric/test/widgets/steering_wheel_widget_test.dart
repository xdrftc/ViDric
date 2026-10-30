import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/widgets/steering_wheel_widget.dart';

void main() {
  group('SteeringWheelWidget Tests', () {
    testWidgets('renders steering wheel and degree badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SteeringWheelWidget(
                size: 200,
                maxAngleDegrees: 90.0,
              ),
            ),
          ),
        ),
      );

      // Verify the 0° CENTER badge is initially displayed
      expect(find.text('0° CENTER'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('horn tap invokes onHornPressed and onHornReleased callbacks', (WidgetTester tester) async {
      bool hornPressed = false;
      bool hornReleased = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SteeringWheelWidget(
                size: 200,
                onHornPressed: () {
                  hornPressed = true;
                },
                onHornReleased: () {
                  hornReleased = true;
                },
              ),
            ),
          ),
        ),
      );

      final hornFinder = find.byIcon(Icons.volume_up_rounded);
      expect(hornFinder, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(hornFinder));
      await tester.pump();
      expect(hornPressed, isTrue);
      expect(hornReleased, isFalse);

      await gesture.up();
      await tester.pump();
      expect(hornReleased, isTrue);
    });

    testWidgets('rotational drag updates steering angle and triggers callback', (WidgetTester tester) async {
      double lastNormalizedAngle = 0.0;
      double lastDegree = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SteeringWheelWidget(
                size: 200,
                maxAngleDegrees: 90.0,
                autoSpringReturn: false,
                onAngleChanged: (val) {
                  lastNormalizedAngle = val;
                },
                onRawDegreeChanged: (deg) {
                  lastDegree = deg;
                },
              ),
            ),
          ),
        ),
      );

      // Wheel center is at center of widget box
      final wheelCenter = tester.getCenter(find.byType(SteeringWheelWidget));
      
      // Drag along right rim downward (clockwise rotation = turning right)
      final startPos = Offset(wheelCenter.dx + 80, wheelCenter.dy);
      final dragGesture = await tester.startGesture(startPos);
      await tester.pump();

      await dragGesture.moveTo(Offset(wheelCenter.dx + 50, wheelCenter.dy + 60));
      await tester.pump();
      await dragGesture.up();
      await tester.pump();

      // Steering angle should have updated to positive (right)
      expect(lastNormalizedAngle, greaterThan(0.0));
      expect(lastDegree, greaterThan(0.0));
    });

    testWidgets('spring-return smoothly returns wheel angle to zero on release', (WidgetTester tester) async {
      double currentNormalized = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SteeringWheelWidget(
                size: 200,
                maxAngleDegrees: 90.0,
                autoSpringReturn: true,
                springDuration: const Duration(milliseconds: 200),
                onAngleChanged: (val) {
                  currentNormalized = val;
                },
              ),
            ),
          ),
        ),
      );

      final wheelCenter = tester.getCenter(find.byType(SteeringWheelWidget));
      final startPos = Offset(wheelCenter.dx + 80, wheelCenter.dy);
      final dragGesture = await tester.startGesture(startPos);
      await tester.pump();

      // Drag clockwise
      await dragGesture.moveTo(Offset(wheelCenter.dx + 50, wheelCenter.dy + 60));
      await tester.pump();
      expect(currentNormalized, greaterThan(0.0));

      // Release finger
      await dragGesture.up();
      await tester.pump(); // Start spring animation

      // Advance clock past spring animation duration
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Should be returned to 0.0 center
      expect(currentNormalized.abs(), lessThan(0.01));
      expect(find.text('0° CENTER'), findsOneWidget);
    });
  });
}

