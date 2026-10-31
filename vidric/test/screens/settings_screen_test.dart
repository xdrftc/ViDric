import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/screens/settings_screen.dart';
import 'package:vidric/services/settings_service.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    setUp(() {
      SettingsService.instance.resetToDefaults();
    });

    testWidgets('renders landscape master-detail layout with all tabs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Header checks
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('KEMBALI'), findsOneWidget);
      expect(find.text('RESET DEFAULT'), findsOneWidget);

      // Master navigation items
      expect(find.text('SELECT MODE'), findsOneWidget);
      expect(find.text('CONNECTION'), findsOneWidget);
      expect(find.text('CUSTOMIZATION'), findsOneWidget);
      expect(find.text('STEERING'), findsOneWidget);
      expect(find.text('PEDALS'), findsOneWidget);
      expect(find.text('SOUND AND HAPTICS'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);

      // Default active detail: SELECT MODE cards
      expect(find.text('TILT MODE'), findsWidgets);
      expect(find.text('STEER MODE'), findsWidgets);
      expect(find.text('MODE AKTIF'), findsOneWidget);
    });

    testWidgets('switches cockpit mode by tapping mode card', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(SettingsService.instance.current.cockpitMode, equals('steeringWheel'));

      // Tap on TILT MODE card
      await tester.tap(find.text('TILT MODE').first);
      await tester.pumpAndSettle();

      expect(SettingsService.instance.current.cockpitMode, equals('tilt'));
    });

    testWidgets('navigates to CONNECTION tab and shows dedicated IP and UDP controls', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap CONNECTION in master sidebar
      await tester.tap(find.text('CONNECTION'));
      await tester.pumpAndSettle();

      expect(find.text('PENGATURAN KONEKSI WI-FI UDP'), findsOneWidget);
      expect(find.text('ALAMAT IP SERVER PC:'), findsOneWidget);
      expect(find.text('PORT UDP:'), findsOneWidget);
      expect(find.text('SCAN QR'), findsOneWidget);
      expect(find.text('TEST PING'), findsOneWidget);
      expect(find.text('METRIK TRANSMISI REAL-TIME'), findsOneWidget);
    });

    testWidgets('navigates to CUSTOMIZATION tab and shows live sensor tester', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap CUSTOMIZATION in master sidebar
      await tester.tap(find.text('CUSTOMIZATION'));
      await tester.pumpAndSettle();

      expect(find.text('KUSTOMISASI LAYOUT & BUTTON BOX'), findsOneWidget);
      expect(find.text('LIVE HARDWARE SENSOR TESTER'), findsOneWidget);
      expect(find.text('STREAM 20 HZ'), findsOneWidget);
      expect(find.text('PANDUAN PEMETAAN VJOY (IN-GAME BINDING)'), findsOneWidget);
    });

    testWidgets('navigates to STEERING tab and updates rotation degree', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap STEERING tab
      await tester.tap(find.text('STEERING'));
      await tester.pumpAndSettle();

      expect(find.text('STEERING & TILT SETTINGS'), findsOneWidget);
      expect(find.text('TILT SENSOR TYPE'), findsOneWidget);
      expect(find.text('BATAS DERAJAT PUTARAN (ROTATION LOCK)'), findsOneWidget);

      // Tap 540° degree chip
      await tester.tap(find.text('540°'));
      await tester.pumpAndSettle();

      expect(SettingsService.instance.current.steeringDegrees, equals(540));

      // Test Tilt Sensitivity chip: SPORT (30°)
      expect(find.text('SENSITIVITAS KEMIRINGAN (TILT SENSITIVITY)'), findsOneWidget);
      await tester.tap(find.text('SPORT (30°)'));
      await tester.pumpAndSettle();

      expect(SettingsService.instance.current.tiltSensitivity, equals('sport'));
      expect(SettingsService.instance.current.tiltMaxAngle, equals(30.0));
    });

    testWidgets('navigates to ABOUT tab and displays system information', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap ABOUT tab
      await tester.tap(find.text('ABOUT'));
      await tester.pumpAndSettle();

      expect(find.text('TENTANG VIDRIC'), findsOneWidget);
      expect(find.text('ViDric (Virtual Driving Controller)'), findsOneWidget);
      expect(find.text('Versi Aplikasi: v1.0.0-rc1 (Build 2026.10)'), findsOneWidget);
    });
  });
}

