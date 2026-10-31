import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';

/// Layanan penyimpanan dan manajemen setelan aplikasi (Non-MVVM Service).
///
/// Menyediakan akses reaktif terhadap preferensi konfigurasi controller
/// menggunakan ValueNotifier agar pembaruan UI instan dan hemat memori.
class SettingsService {
  SettingsService._internal();

  static final SettingsService instance = SettingsService._internal();

  final ValueNotifier<AppSettings> settings = ValueNotifier<AppSettings>(
    const AppSettings(),
  );

  AppSettings get current => settings.value;

  void update(AppSettings Function(AppSettings current) updater) {
    settings.value = updater(settings.value);
  }

  void setCockpitMode(String mode) {
    update((c) => c.copyWith(cockpitMode: mode));
  }

  void setTiltSensorType(String type) {
    update((c) => c.copyWith(tiltSensorType: type));
  }

  void setTiltSensitivity(String sensitivity) {
    update((c) => c.copyWith(tiltSensitivity: sensitivity));
  }

  void setSteeringDegrees(int degrees) {
    update((c) => c.copyWith(steeringDegrees: degrees));
  }

  void setSpringDamping(double damping) {
    update((c) => c.copyWith(springDamping: damping));
  }

  void setCenterDeadzone(double deadzone) {
    update((c) => c.copyWith(centerDeadzone: deadzone));
  }

  void setNonLinearBrake(bool enabled) {
    update((c) => c.copyWith(nonLinearBrake: enabled));
  }

  void setHandbrakeMode(String mode) {
    update((c) => c.copyWith(handbrakeMode: mode));
  }

  void setTransmissionMode(String mode) {
    update((c) => c.copyWith(transmissionMode: mode));
  }

  void setInvertPedals(bool inverted) {
    update((c) => c.copyWith(invertPedals: inverted));
  }

  void setHapticIntensity(String intensity) {
    update((c) => c.copyWith(hapticIntensity: intensity));
  }

  void setMechanicalAudioClicks(bool enabled) {
    update((c) => c.copyWith(mechanicalAudioClicks: enabled));
  }

  void setLockBumpHaptic(bool enabled) {
    update((c) => c.copyWith(lockBumpHaptic: enabled));
  }

  void setButtonOpacity(double opacity) {
    update((c) => c.copyWith(buttonOpacity: opacity));
  }

  void setButtonScale(double scale) {
    update((c) => c.copyWith(buttonScale: scale));
  }

  void resetToDefaults() {
    settings.value = const AppSettings();
  }
}

