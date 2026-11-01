import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/models/control_packet.dart';

void main() {
  group('ControlPacket Unit Tests', () {
    test('neutral() factory creates idle packet', () {
      final packet = ControlPacket.neutral(seq: 1);
      expect(packet.mode, equals('guiWheel'));
      expect(packet.steering, equals(0.0));
      expect(packet.gas, equals(0.0));
      expect(packet.brake, equals(0.0));
      expect(packet.clutch, equals(0.0));
      expect(packet.buttons, isEmpty);
      expect(packet.seq, equals(1));
    });

    test('toJson() formats values with 3-decimal float precision and sorted buttons', () {
      const packet = ControlPacket(
        mode: 'guiWheel',
        steering: -0.425123,
        gas: 0.6509,
        brake: 0.0,
        clutch: 0.8256,
        buttons: [7, 3, 9],
        seq: 42,
      );

      final json = packet.toJson();
      expect(json['mode'], equals('guiWheel'));
      expect(json['steering'], equals(-0.425));
      expect(json['gas'], equals(0.651));
      expect(json['brake'], equals(0.0));
      expect(json['clutch'], equals(0.826));
      expect(json['buttons'], equals([3, 7, 9]));
      expect(json['seq'], equals(42));
    });

    test('copyWith() overrides specified fields while keeping others', () {
      final original = ControlPacket.neutral(seq: 5);
      final updated = original.copyWith(
        steering: 0.5,
        gas: 1.0,
        clutch: 0.75,
        buttons: [3],
      );

      expect(updated.steering, equals(0.5));
      expect(updated.gas, equals(1.0));
      expect(updated.brake, equals(0.0));
      expect(updated.clutch, equals(0.75));
      expect(updated.buttons, equals([3]));
      expect(updated.seq, equals(5));
    });

    test('toBinaryPacket() creates exactly 17 bytes and fromBinaryPacket() restores values', () {
      const packet = ControlPacket(
        mode: 'tilt',
        steering: -0.5,
        gas: 1.0,
        brake: 0.25,
        clutch: 0.75,
        buttons: [1, 5, 16],
        seq: 1024,
      );

      final bytes = packet.toBinaryPacket();
      expect(bytes.length, equals(17));
      expect(bytes[0], equals(0x56)); // 'V'
      expect(bytes[1], equals(0x44)); // 'D'
      expect(bytes[12], equals(1));   // 'tilt' mode flag

      final restored = ControlPacket.fromBinaryPacket(bytes);
      expect(restored.mode, equals('tilt'));
      expect(restored.seq, equals(1024));
      expect(restored.steering, closeTo(-0.5, 0.001));
      expect(restored.gas, closeTo(1.0, 0.001));
      expect(restored.brake, closeTo(0.25, 0.001));
      expect(restored.clutch, closeTo(0.75, 0.001));
      expect(restored.buttons, equals([1, 5, 16]));
    });

    test('fromBinaryPacket() throws FormatException on invalid payload or length', () {
      expect(() => ControlPacket.fromBinaryPacket(Uint8List(16)), throwsFormatException);
      expect(() => ControlPacket.fromBinaryPacket(Uint8List(17)), throwsFormatException);
    });
  });
}

