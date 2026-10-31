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

