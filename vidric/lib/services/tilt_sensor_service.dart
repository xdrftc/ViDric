import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/app_settings.dart';
import 'settings_service.dart';

/// Data pembacaan sensor kemudi fisik (Tilt Telemetry).
class TiltTelemetry {
  final double rawAngleDeg;
  final double filteredAngleDeg;
  final double zeroOffsetDeg;
  final double normalizedSteering; // -1.0 (Full Left) s/d +1.0 (Full Right)
  final double pitchDeg;
  final double rollDeg;
  final bool isCalibrated;

  const TiltTelemetry({
    this.rawAngleDeg = 0.0,
    this.filteredAngleDeg = 0.0,
    this.zeroOffsetDeg = 0.0,
    this.normalizedSteering = 0.0,
    this.pitchDeg = 0.0,
    this.rollDeg = 0.0,
    this.isCalibrated = false,
  });
}

/// Layanan sensor gerak fisik (Akselerometer & Giroskop) untuk TILT MODE.
///
/// Fitur Utama (Issue #6):
/// 1. Integrasi sensor hardware via package:sensors_plus.
/// 2. Filter peredam getaran (Low-Pass Filter, alpha = 0.28).
/// 3. Kalibrasi posisi netral instan (Recenter Zero Calibration).
/// 4. Center Deadzone filtering (mencegah kemudi bergoyang saat lurus).
/// 5. Penyesuaian sensitivitas kemiringan (Normal 45°, Sport 30°, Truck 60°).
class TiltSensorService {
  TiltSensorService._internal();

  static final TiltSensorService instance = TiltSensorService._internal();

  // Stream Subscriptions
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  // Konfigurasi Filter
  static const double lowPassAlpha = 0.28; // Sesuai spesifikasi task

  // State Kalibrasi & Filter
  double _rawAngleDeg = 0.0;
  double _filteredAngleDeg = 0.0;
  double _zeroOffsetDeg = 0.0;
  double _pitchDeg = 0.0;
  double _rollDeg = 0.0;
  bool _isCalibrated = false;

  // Reaktif Notifier untuk UI Kokpit
  final ValueNotifier<TiltTelemetry> telemetry = ValueNotifier<TiltTelemetry>(
    const TiltTelemetry(),
  );

  TiltTelemetry get current => telemetry.value;

  /// Memulai langganan stream sensor fisik smartphone.
  void startListening() {
    stopListening();

    try {
      _accelSub = accelerometerEventStream().listen(
        _onAccelerometerData,
        onError: (err) {
          debugPrint('TiltSensorService Accel Error: $err');
        },
        cancelOnError: false,
      );

      _gyroSub = gyroscopeEventStream().listen(
        _onGyroscopeData,
        onError: (err) {
          debugPrint('TiltSensorService Gyro Error: $err');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('TiltSensorService: Hardware sensor tidak tersedia di platform ini: $e');
    }
  }

  /// Menghentikan langganan stream sensor.
  void stopListening() {
    _accelSub?.cancel();
    _accelSub = null;
    _gyroSub?.cancel();
    _gyroSub = null;
  }

  /// Memproses data akselerometer dalam mode lanskap.
  void _onAccelerometerData(AccelerometerEvent event) {
    // Menghitung sudut kemiringan rotasi smartphone (Roll & Pitch)
    // Dalam orientasi lanskap, pemutaran kemudi diproyeksikan pada rasio y dan x
    final double rawRoll = math.atan2(event.y, event.x) * (180.0 / math.pi);
    final double rawPitch = math.atan2(
      event.z,
      math.sqrt(event.x * event.x + event.y * event.y),
    ) * (180.0 / math.pi);

    _pitchDeg = rawPitch;
    _rollDeg = rawRoll;

    final AppSettings settings = SettingsService.instance.current;

    // Jika mode sensor yang aktif adalah accelerometer
    if (settings.tiltSensorType == 'accelerometer') {
      _processAngleUpdate(rawRoll);
    }
  }

  /// Memproses data giroskop.
  void _onGyroscopeData(GyroscopeEvent event) {
    final AppSettings settings = SettingsService.instance.current;

    // Jika mode sensor yang aktif adalah gyro, manfaatkan pembacaan sudut responsif
    if (settings.tiltSensorType == 'gyro') {
      // Kecepatan sudut rotasi z/y digabungkan dengan estimasi akselerometer
      _processAngleUpdate(_rollDeg);
    }
  }

  /// Memproses filter low-pass, kalibrasi zero offset, dan deadzone.
  void _processAngleUpdate(double rawAngle) {
    _rawAngleDeg = rawAngle;

    // 1. Hitung sudut terkalibrasi relatif terhadap Recenter Zero
    double calibratedAngle = _rawAngleDeg - _zeroOffsetDeg;

    // Normalisasi rentang sudut ke interval [-180, +180] derajat
    while (calibratedAngle > 180.0) {
      calibratedAngle -= 360.0;
    }
    while (calibratedAngle < -180.0) {
      calibratedAngle += 360.0;
    }

    // 2. Filter peredam getaran (Low-Pass Filter: alpha = 0.28)
    _filteredAngleDeg = (_filteredAngleDeg * (1.0 - lowPassAlpha)) +
        (calibratedAngle * lowPassAlpha);

    final AppSettings settings = SettingsService.instance.current;
    final double deadzone = settings.centerDeadzone;
    final double maxAngle = settings.tiltMaxAngle; // 30, 45, atau 60 derajat

    // 3. Center Deadzone Filter
    double normalized = 0.0;
    final double absAngle = _filteredAngleDeg.abs();

    if (absAngle > deadzone) {
      final double span = math.max(0.1, maxAngle - deadzone);
      final double excess = (absAngle - deadzone) / span;
      normalized = excess.clamp(0.0, 1.0) * _filteredAngleDeg.sign;
    }

    // Pembalikan nilai jika kemiringan negatif adalah belok kiri (-1.0) dan positif belok kanan (+1.0)
    // Sesuai orientasi standar kemudi
    telemetry.value = TiltTelemetry(
      rawAngleDeg: _rawAngleDeg,
      filteredAngleDeg: _filteredAngleDeg,
      zeroOffsetDeg: _zeroOffsetDeg,
      normalizedSteering: normalized,
      pitchDeg: _pitchDeg,
      rollDeg: _rollDeg,
      isCalibrated: _isCalibrated,
    );
  }

  /// Menetapkan posisi kemiringan ponsel saat ini sebagai titik nol netral (0.0°).
  void recenterZero() {
    _zeroOffsetDeg = _rawAngleDeg;
    _filteredAngleDeg = 0.0;
    _isCalibrated = true;

    telemetry.value = TiltTelemetry(
      rawAngleDeg: _rawAngleDeg,
      filteredAngleDeg: 0.0,
      zeroOffsetDeg: _zeroOffsetDeg,
      normalizedSteering: 0.0,
      pitchDeg: _pitchDeg,
      rollDeg: _rollDeg,
      isCalibrated: true,
    );
  }

  /// Mengatur ulang kalibrasi titik nol ke default pabrik (0.0).
  void resetCalibration() {
    _zeroOffsetDeg = 0.0;
    _isCalibrated = false;
    _processAngleUpdate(_rawAngleDeg);
  }

  /// Pemasukan data sensor mock untuk pengujian otomatis (Unit/Widget Tests).
  void feedMockSensorData({
    required double rollDeg,
    double pitchDeg = 0.0,
  }) {
    _pitchDeg = pitchDeg;
    _rollDeg = rollDeg;
    _processAngleUpdate(rollDeg);
  }
}
