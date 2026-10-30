import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/widgets/nav_cluster_widget.dart';

void main() {
  group('NavClusterWidget Tests', () {
    testWidgets('renders navigation buttons and triggers tap callbacks', (WidgetTester tester) async {
      bool enterPressed = false;
      bool btn1Pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NavClusterWidget(
                onEnterPressed: () {
                  enterPressed = true;
                },
                onBtn1Pressed: () {
                  btn1Pressed = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify ENTER and numeric keys exist
      expect(find.text('ENTER'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('ENTER'));
      await tester.pump();
      expect(enterPressed, isTrue);

      await tester.tap(find.text('1'));
      await tester.pump();
      expect(btn1Pressed, isTrue);
    });
  });
}

