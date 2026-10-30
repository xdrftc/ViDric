/// Model data konfigurasi dan setelan aplikasi ViDric.
///
/// Menyimpan preferensi kendali, kemudi, pedal, sensor, dan haptik.
class AppSettings {
  // Mode Kendali
  final String cockpitMode; // 'steeringWheel' atau 'tilt'

  // Setelan Kemudi (Steering)
  final String tiltSensorType; // 'gyro' atau 'accelerometer'
  final int steeringDegrees; // 180, 360, 540, 900, 1080
  final double springDamping; // 0.1 s/d 1.0
  final double centerDeadzone; // 0.0 s/d 15.0 derajat

  // Setelan Pedal & Transmisi
  final bool nonLinearBrake;
  final String handbrakeMode; // 'toggle' atau 'momentary'
  final String transmissionMode; // 'hPattern' atau 'sequential'
  final bool invertPedals;

  // Setelan Suara & Haptik
  final String hapticIntensity; // 'off', 'low', 'medium', 'high'
  final bool mechanicalAudioClicks;
  final bool lockBumpHaptic;

  // Kustomisasi Tampilan
  final double buttonOpacity; // 0.3 s/d 1.0
  final double buttonScale; // 0.8 s/d 1.2

  const AppSettings({
    this.cockpitMode = 'steeringWheel',
    this.tiltSensorType = 'gyro',
    this.steeringDegrees = 900,
    this.springDamping = 0.6,
    this.centerDeadzone = 2.0,
    this.nonLinearBrake = true,
    this.handbrakeMode = 'toggle',
    this.transmissionMode = 'hPattern',
    this.invertPedals = false,
    this.hapticIntensity = 'medium',
    this.mechanicalAudioClicks = true,
    this.lockBumpHaptic = true,
    this.buttonOpacity = 0.9,
    this.buttonScale = 1.0,
  });

  AppSettings copyWith({
    String? cockpitMode,
    String? tiltSensorType,
    int? steeringDegrees,
    double? springDamping,
    double? centerDeadzone,
    bool? nonLinearBrake,
    String? handbrakeMode,
    String? transmissionMode,
    bool? invertPedals,
    String? hapticIntensity,
    bool? mechanicalAudioClicks,
    bool? lockBumpHaptic,
    double? buttonOpacity,
    double? buttonScale,
  }) {
    return AppSettings(
      cockpitMode: cockpitMode ?? this.cockpitMode,
      tiltSensorType: tiltSensorType ?? this.tiltSensorType,
      steeringDegrees: steeringDegrees ?? this.steeringDegrees,
      springDamping: springDamping ?? this.springDamping,
      centerDeadzone: centerDeadzone ?? this.centerDeadzone,
      nonLinearBrake: nonLinearBrake ?? this.nonLinearBrake,
      handbrakeMode: handbrakeMode ?? this.handbrakeMode,
      transmissionMode: transmissionMode ?? this.transmissionMode,
      invertPedals: invertPedals ?? this.invertPedals,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
      mechanicalAudioClicks: mechanicalAudioClicks ?? this.mechanicalAudioClicks,
      lockBumpHaptic: lockBumpHaptic ?? this.lockBumpHaptic,
      buttonOpacity: buttonOpacity ?? this.buttonOpacity,
      buttonScale: buttonScale ?? this.buttonScale,
    );
  }
}
