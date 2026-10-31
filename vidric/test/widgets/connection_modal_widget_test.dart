import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidric/services/udp_service.dart';
import 'package:vidric/widgets/connection_modal_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectionModalWidget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await UdpService.instance.init();
    });

    testWidgets('renders connection modal with IP, Port, and control buttons', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ConnectionModalWidget(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('KONEKSI PC COMPANION (WI-FI UDP)'), findsOneWidget);
      expect(find.text('ALAMAT IP SERVER PC:'), findsOneWidget);
      expect(find.text('PORT UDP:'), findsOneWidget);
      expect(find.text('SCAN QR'), findsOneWidget);
      expect(find.text('TEST PING'), findsOneWidget);
      expect(find.text('STATUS KONEKSI'), findsOneWidget);
      expect(find.text('TX RATE (HZ)'), findsOneWidget);
      expect(find.text('HUBUNGKAN KE PC (50 HZ)'), findsOneWidget);
    });

    testWidgets('allows editing IP address field', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ConnectionModalWidget(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ipField = find.byType(TextField).first;
      await tester.enterText(ipField, '192.168.1.188');
      await tester.pumpAndSettle();

      expect(find.text('192.168.1.188'), findsOneWidget);
    });
  });
}
