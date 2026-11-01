import 'dart:typed_data';

/// Immutable Control Packet DTO sent from ViDric mobile client to PC Companion.
class ControlPacket {
  final String mode;
  final double steering; // -1.0 (Full Left) to +1.0 (Full Right)
  final double gas; // 0.0 (Idle) to 1.0 (Full Throttle)
  final double brake; // 0.0 (Idle) to 1.0 (Full Brake)
  final double clutch; // 0.0 (Released) to 1.0 (Full Clutch)
  final List<int> buttons; // Active vJoy button IDs, e.g. [3, 7]
  final int seq; // Sequence counter

  const ControlPacket({
    required this.mode,
    required this.steering,
    required this.gas,
    required this.brake,
    this.clutch = 0.0,
    required this.buttons,
    required this.seq,
  });

  /// Factory creating an idle / neutral packet.
  factory ControlPacket.neutral({String mode = 'guiWheel', int seq = 0}) {
    return ControlPacket(
      mode: mode,
      steering: 0.0,
      gas: 0.0,
      brake: 0.0,
      clutch: 0.0,
      buttons: const <int>[],
      seq: seq,
    );
  }

  /// Serializes telemetry frame into JSON Map with 3-decimal float precision.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mode': mode,
      'steering': double.parse(steering.clamp(-1.0, 1.0).toStringAsFixed(3)),
      'gas': double.parse(gas.clamp(0.0, 1.0).toStringAsFixed(3)),
      'brake': double.parse(brake.clamp(0.0, 1.0).toStringAsFixed(3)),
      'clutch': double.parse(clutch.clamp(0.0, 1.0).toStringAsFixed(3)),
      'buttons': List<int>.from(buttons)..sort(),
      'seq': seq,
    };
  }

  /// Serializes telemetry frame into ultra-compact 17-byte binary packet.
  ///
  /// Binary Layout (17 bytes, Little-Endian):
  /// - [0..1]  : Magic ASCII Header `0x56, 0x44` ('V', 'D') [2B]
  /// - [2..3]  : Sequence Number uint16 [2B]
  /// - [4..5]  : Steering int16 (-32768 s/d 32767) [2B]
  /// - [6..7]  : Gas uint16 (0 s/d 65535) [2B]
  /// - [8..9]  : Brake uint16 (0 s/d 65535) [2B]
  /// - [10..11]: Clutch uint16 (0 s/d 65535) [2B]
  /// - [12]    : Mode flag uint8 (0: steeringWheel, 1: tilt, 2: failsafe) [1B]
  /// - [13..16]: Buttons bitmask uint32 (Bit 0..31 -> Button 1..32) [4B]
  Uint8List toBinaryPacket() {
    final byteData = ByteData(17);

    // Magic Header 'VD'
    byteData.setUint8(0, 0x56);
    byteData.setUint8(1, 0x44);

    // Sequence
    byteData.setUint16(2, seq % 65536, Endian.little);

    // Axes
    final clampedSteer = steering.clamp(-1.0, 1.0);
    final int steerInt = (clampedSteer * 32767.0).round().clamp(-32768, 32767);
    byteData.setInt16(4, steerInt, Endian.little);

    final int gasInt = (gas.clamp(0.0, 1.0) * 65535.0).round().clamp(0, 65535);
    byteData.setUint16(6, gasInt, Endian.little);

    final int brakeInt = (brake.clamp(0.0, 1.0) * 65535.0).round().clamp(0, 65535);
    byteData.setUint16(8, brakeInt, Endian.little);

    final int clutchInt = (clutch.clamp(0.0, 1.0) * 65535.0).round().clamp(0, 65535);
    byteData.setUint16(10, clutchInt, Endian.little);

    // Mode flag
    int modeByte = 0;
    if (mode == 'tilt') {
      modeByte = 1;
    } else if (mode == 'failsafe') {
      modeByte = 2;
    }
    byteData.setUint8(12, modeByte);

    // Buttons bitmask (Buttons 1..32)
    int mask = 0;
    for (final b in buttons) {
      if (b >= 1 && b <= 32) {
        mask |= (1 << (b - 1));
      }
    }
    byteData.setUint32(13, mask, Endian.little);

    return byteData.buffer.asUint8List();
  }

  /// Deserializes 17-byte binary packet back into ControlPacket.
  factory ControlPacket.fromBinaryPacket(Uint8List bytes) {
    if (bytes.length < 17) {
      throw const FormatException('Panjang paket biner minimal 17 byte');
    }
    final byteData = ByteData.sublistView(bytes);
    if (byteData.getUint8(0) != 0x56 || byteData.getUint8(1) != 0x44) {
      throw const FormatException('Magic header biner tidak valid (harus 0x56 0x44)');
    }

    final int seq = byteData.getUint16(2, Endian.little);
    final int rawSteer = byteData.getInt16(4, Endian.little);
    final int rawGas = byteData.getUint16(6, Endian.little);
    final int rawBrake = byteData.getUint16(8, Endian.little);
    final int rawClutch = byteData.getUint16(10, Endian.little);
    final int modeFlag = byteData.getUint8(12);
    final int buttonsMask = byteData.getUint32(13, Endian.little);

    final buttons = <int>[];
    for (int i = 0; i < 32; i++) {
      if ((buttonsMask & (1 << i)) != 0) {
        buttons.add(i + 1);
      }
    }

    String modeStr = 'guiWheel';
    if (modeFlag == 1) {
      modeStr = 'tilt';
    } else if (modeFlag == 2) {
      modeStr = 'failsafe';
    }

    return ControlPacket(
      mode: modeStr,
      steering: (rawSteer / 32767.0).clamp(-1.0, 1.0),
      gas: (rawGas / 65535.0).clamp(0.0, 1.0),
      brake: (rawBrake / 65535.0).clamp(0.0, 1.0),
      clutch: (rawClutch / 65535.0).clamp(0.0, 1.0),
      buttons: buttons,
      seq: seq,
    );
  }

  ControlPacket copyWith({
    String? mode,
    double? steering,
    double? gas,
    double? brake,
    double? clutch,
    List<int>? buttons,
    int? seq,
  }) {
    return ControlPacket(
      mode: mode ?? this.mode,
      steering: steering ?? this.steering,
      gas: gas ?? this.gas,
      brake: brake ?? this.brake,
      clutch: clutch ?? this.clutch,
      buttons: buttons ?? this.buttons,
      seq: seq ?? this.seq,
    );
  }

  @override
  String toString() {
    return 'ControlPacket(mode: $mode, steer: $steering, gas: $gas, brake: $brake, clutch: $clutch, btns: $buttons, seq: $seq)';
  }
}


