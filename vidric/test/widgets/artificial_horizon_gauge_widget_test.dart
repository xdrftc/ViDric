import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/widgets/artificial_horizon_gauge_widget.dart';

void main() {
  group('ArtificialHorizonGaugeWidget Tests', () {
    testWidgets('renders gauge with 0.0° and CENTER label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ArtificialHorizonGaugeWidget(
                angleDeg: 0.0,
                maxAngleDeg: 45.0,
                isCalibrated: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0.0°'), findsOneWidget);
      expect(find.text('CENTER'), findsOneWidget);
      expect(find.text('TILT HORIZON : ACTIVE'), findsOneWidget);
    });

    testWidgets('renders left tilt direction and degrees', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ArtificialHorizonGaugeWidget(
                angleDeg: -16.4,
                maxAngleDeg: 45.0,
                isCalibrated: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('16.4°'), findsOneWidget);
      expect(find.text('LEFT'), findsOneWidget);
    });

    testWidgets('renders right tilt direction and degrees', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ArtificialHorizonGaugeWidget(
                angleDeg: 28.7,
                maxAngleDeg: 45.0,
                isCalibrated: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('28.7°'), findsOneWidget);
      expect(find.text('RIGHT'), findsOneWidget);
    });

    testWidgets('shows uncalibrated status when isCalibrated is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ArtificialHorizonGaugeWidget(
                angleDeg: 5.0,
                maxAngleDeg: 45.0,
                isCalibrated: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('UNCALIBRATED'), findsOneWidget);
    });
  });
}

