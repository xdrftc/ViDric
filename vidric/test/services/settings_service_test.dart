import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/services/settings_service.dart';

void main() {
  group('SettingsService & AppSettings Tests', () {
    late SettingsService service;

    setUp(() {
      service = SettingsService.instance;
      service.resetToDefaults();
    });

    test('default settings initialized properly', () {
      final s = service.current;
      expect(s.cockpitMode, equals('steeringWheel'));
      expect(s.tiltSensorType, equals('gyro'));
      expect(s.steeringDegrees, equals(900));
      expect(s.springDamping, equals(0.6));
      expect(s.centerDeadzone, equals(2.0));
      expect(s.nonLinearBrake, isTrue);
      expect(s.handbrakeMode, equals('toggle'));
      expect(s.transmissionMode, equals('hPattern'));
      expect(s.invertPedals, isFalse);
      expect(s.hapticIntensity, equals('medium'));
      expect(s.mechanicalAudioClicks, isTrue);
      expect(s.lockBumpHaptic, isTrue);
    });

    test('updates cockpit mode and notifies listeners', () {
      bool notified = false;
      service.settings.addListener(() {
        notified = true;
      });

      service.setCockpitMode('tilt');
      expect(service.current.cockpitMode, equals('tilt'));
      expect(notified, isTrue);
    });

    test('updates steering configurations', () {
      service.setSteeringDegrees(540);
      service.setSpringDamping(0.8);
      service.setCenterDeadzone(4.5);
      service.setTiltSensorType('accelerometer');
      service.setTiltSensitivity('sport');

      final s = service.current;
      expect(s.steeringDegrees, equals(540));
      expect(s.springDamping, closeTo(0.8, 0.01));
      expect(s.centerDeadzone, closeTo(4.5, 0.01));
      expect(s.tiltSensorType, equals('accelerometer'));
      expect(s.tiltSensitivity, equals('sport'));
      expect(s.tiltMaxAngle, equals(30.0));
    });

    test('updates pedals & sound haptics', () {
      service.setNonLinearBrake(false);
      service.setHandbrakeMode('momentary');
      service.setTransmissionMode('sequential');
      service.setInvertPedals(true);
      service.setHapticIntensity('high');
      service.setMechanicalAudioClicks(false);
      service.setLockBumpHaptic(false);

      final s = service.current;
      expect(s.nonLinearBrake, isFalse);
      expect(s.handbrakeMode, equals('momentary'));
      expect(s.transmissionMode, equals('sequential'));
      expect(s.invertPedals, isTrue);
      expect(s.hapticIntensity, equals('high'));
      expect(s.mechanicalAudioClicks, isFalse);
      expect(s.lockBumpHaptic, isFalse);
    });

    test('resetToDefaults restores initial configuration', () {
      service.setCockpitMode('tilt');
      service.setSteeringDegrees(180);
      expect(service.current.cockpitMode, equals('tilt'));

      service.resetToDefaults();
      expect(service.current.cockpitMode, equals('steeringWheel'));
      expect(service.current.steeringDegrees, equals(900));
    });
  });
}
