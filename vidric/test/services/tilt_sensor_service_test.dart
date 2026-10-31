import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/services/settings_service.dart';
import 'package:vidric/services/tilt_sensor_service.dart';

void main() {
  group('TiltSensorService Unit Tests', () {
    late TiltSensorService service;

    setUp(() {
      service = TiltSensorService.instance;
      SettingsService.instance.resetToDefaults();
      service.resetCalibration();
    });

    test('initial state has zero angles and neutral steering', () {
      final t = service.current;
      expect(t.rawAngleDeg, equals(0.0));
      expect(t.filteredAngleDeg, equals(0.0));
      expect(t.zeroOffsetDeg, equals(0.0));
      expect(t.normalizedSteering, equals(0.0));
      expect(t.isCalibrated, isFalse);
    });

    test('applies low-pass filter (alpha = 0.28) progressively on sensor input', () {
      // Feed first reading: 20.0 degrees
      service.feedMockSensorData(rollDeg: 20.0);
      final t1 = service.current;
      // Filter calculation: 0 * (1 - 0.28) + 20 * 0.28 = 5.6
      expect(t1.filteredAngleDeg, closeTo(5.6, 0.1));

      // Feed second reading: 20.0 degrees
      service.feedMockSensorData(rollDeg: 20.0);
      final t2 = service.current;
      // Filter calculation: 5.6 * 0.72 + 20 * 0.28 = 4.032 + 5.6 = 9.632
      expect(t2.filteredAngleDeg, closeTo(9.63, 0.1));
    });

    test('respects center deadzone', () {
      // Default deadzone is 2.0 degrees
      SettingsService.instance.setCenterDeadzone(3.0);

      // Feed small noise within deadzone repeatedly to settle filter
      for (int i = 0; i < 20; i++) {
        service.feedMockSensorData(rollDeg: 2.0);
      }

      // Filtered angle is ~2.0, which is <= deadzone (3.0), so steering should be 0.0
      expect(service.current.normalizedSteering, equals(0.0));

      // Feed large angle outside deadzone
      for (int i = 0; i < 30; i++) {
        service.feedMockSensorData(rollDeg: 25.0);
      }

      expect(service.current.normalizedSteering, greaterThan(0.3));
    });

    test('recenterZero establishes current angle as neutral 0.0', () {
      // User is holding phone tilted at 18.5 degrees
      for (int i = 0; i < 30; i++) {
        service.feedMockSensorData(rollDeg: 18.5);
      }
      expect(service.current.filteredAngleDeg, closeTo(18.5, 0.5));

      // User presses RECENTER ZERO button
      service.recenterZero();

      expect(service.current.isCalibrated, isTrue);
      expect(service.current.zeroOffsetDeg, closeTo(18.5, 0.1));
      expect(service.current.filteredAngleDeg, equals(0.0));
      expect(service.current.normalizedSteering, equals(0.0));

      // Tilting further to 28.5 degrees represents +10 degrees from calibrated zero
      for (int i = 0; i < 30; i++) {
        service.feedMockSensorData(rollDeg: 28.5);
      }
      expect(service.current.filteredAngleDeg, closeTo(10.0, 0.5));
    });

    test('adjusts sensitivity (Sport 30°, Normal 45°, Truck 60°)', () {
      // Set to SPORT (30° max angle)
      SettingsService.instance.setTiltSensitivity('sport');
      expect(SettingsService.instance.current.tiltMaxAngle, equals(30.0));

      // Feed 30 degrees (should reach near 1.0 full right)
      for (int i = 0; i < 35; i++) {
        service.feedMockSensorData(rollDeg: 30.0);
      }
      expect(service.current.normalizedSteering, closeTo(1.0, 0.05));

      // Reset and set to TRUCK (60° max angle)
      service.resetCalibration();
      SettingsService.instance.setTiltSensitivity('truck');
      expect(SettingsService.instance.current.tiltMaxAngle, equals(60.0));

      // Feed 30 degrees (should only reach ~0.5 half steering in truck mode)
      for (int i = 0; i < 35; i++) {
        service.feedMockSensorData(rollDeg: 30.0);
      }
      expect(service.current.normalizedSteering, closeTo(0.48, 0.05));
    });
  });
}
