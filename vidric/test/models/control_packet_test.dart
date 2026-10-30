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
      expect(packet.buttons, isEmpty);
      expect(packet.seq, equals(1));
    });

    test('toJson() formats values with 3-decimal float precision and sorted buttons', () {
      const packet = ControlPacket(
        mode: 'guiWheel',
        steering: -0.425123,
        gas: 0.6509,
        brake: 0.0,
        buttons: [7, 3, 9],
        seq: 42,
      );

      final json = packet.toJson();
      expect(json['mode'], equals('guiWheel'));
      expect(json['steering'], equals(-0.425));
      expect(json['gas'], equals(0.651));
      expect(json['brake'], equals(0.0));
      expect(json['buttons'], equals([3, 7, 9]));
      expect(json['seq'], equals(42));
    });

    test('copyWith() overrides specified fields while keeping others', () {
      final original = ControlPacket.neutral(seq: 5);
      final updated = original.copyWith(
        steering: 0.5,
        gas: 1.0,
        buttons: [3],
      );

      expect(updated.steering, equals(0.5));
      expect(updated.gas, equals(1.0));
      expect(updated.brake, equals(0.0));
      expect(updated.buttons, equals([3]));
      expect(updated.seq, equals(5));
    });
  });
}

