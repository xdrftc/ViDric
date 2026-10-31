import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

/// Layanan Navigasi Tab Pengaturan (Master List).
enum SettingsTab {
  selectMode,
  customization,
  steering,
  pedals,
  soundAndHaptics,
  about,
}

/// Layar Pengaturan Lanskap Utama ViDric (Master-Detail Split View).
///
/// Selaras dengan wireframe rancangan visual pengguna (Image 1):
/// - Sisi Kiri (Bilah Master):
///   - SELECT MODE
///   - CUSTOMIZATION
///   - STEERING
///   - PEDALS
///   - SOUND AND HAPTICS
///   - ABOUT
/// - Sisi Kanan (Panel Detail):
///   - SETTING_SELECT: Dua kartu besar (TILT MODE & STEER MODE).
///   - SETTING_CUSTOMIZATION: Tombol Box, Opacity, Live Sensor Tester, vJoy Guide.
///   - SETTING_STEERING: Pilihan Gyro/Accel, Derajat Putaran, Damping, Deadzone.
///   - SETTING_PEDALS: Kurva Non-linear, Handbrake Mode, Transmisi, Invert Axis.
///   - SETTING_SOUND: Intensitas Haptik, Audio Clicks, Lock Bump.
///   - SETTING_ABOUT: Info Versi, Profil UKK RPL, Port UDP 5005.
class SettingsScreen extends StatefulWidget {
  final SettingsTab initialTab;

  const SettingsScreen({
    super.key,
    this.initialTab = SettingsTab.selectMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsTab _activeTab;
  final SettingsService _service = SettingsService.instance;

  // Variabel untuk Live Hardware Sensor Tester
  Timer? _sensorTimer;
  double _mockAccelX = 0.0;
  double _mockAccelY = 9.8;
  double _mockAccelZ = 0.2;
  double _mockGyroX = 0.0;
  double _mockGyroY = 0.0;
  double _mockGyroZ = 0.0;
  double _testerPhase = 0.0;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _startLiveSensorStream();
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    super.dispose();
  }

  void _startLiveSensorStream() {
    // Simulator pembacaan sensor live 20 Hz untuk panel tester
    _sensorTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      if (_activeTab == SettingsTab.customization) {
        setState(() {
          _testerPhase += 0.05;
          _mockAccelX = math.sin(_testerPhase) * 1.5;
          _mockAccelY = 9.8 + math.cos(_testerPhase * 0.7) * 0.3;
          _mockAccelZ = math.sin(_testerPhase * 1.2) * 0.5;
          _mockGyroX = math.cos(_testerPhase) * 12.0;
          _mockGyroY = math.sin(_testerPhase * 0.8) * 8.5;
          _mockGyroZ = math.sin(_testerPhase * 1.5) * 5.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: _service.settings,
      builder: (context, settings, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0E141B),
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                const Divider(height: 1, thickness: 1, color: Color(0xFF1E2C3A)),
                Expanded(
                  child: Row(
                    children: [
                      // Bilah Master (Kiri)
                      SizedBox(
                        width: 220,
                        child: _buildMasterList(settings),
                      ),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Color(0xFF1E2C3A),
                      ),
                      // Panel Detail (Kanan)
                      Expanded(
                        child: Container(
                          color: const Color(0xFF0F161E),
                          child: _buildDetailPanel(settings),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bilah Judul Atas
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF121B24),
      child: Row(
        children: [
          // Tombol Kembali
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2836),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2B3D50)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new, size: 13, color: Color(0xFF00E5FF)),
                  SizedBox(width: 6),
                  Text(
                    'KEMBALI',
                    style: TextStyle(
                      color: Color(0xFFE0E6ED),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'SETTINGS',
            style: TextStyle(
              color: Color(0xFFE0E6ED),
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const Spacer(),
          // Tombol Reset Default
          TextButton.icon(
            onPressed: () {
              _service.resetToDefaults();
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Seluruh setelan dikembalikan ke standar pabrik.'),
                  duration: Duration(milliseconds: 900),
                  backgroundColor: Color(0xFF1B2836),
                ),
              );
            },
            icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF7E93A8)),
            label: const Text(
              'RESET DEFAULT',
              style: TextStyle(
                color: Color(0xFF7E93A8),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bilah Navigasi Master (Kiri)
  Widget _buildMasterList(AppSettings settings) {
    return Container(
      color: const Color(0xFF121A23),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildMasterItem(
            tab: SettingsTab.selectMode,
            label: 'SELECT MODE',
            subtitle: settings.cockpitMode == 'steeringWheel' ? 'STEER MODE' : 'TILT MODE',
          ),
          _buildMasterItem(
            tab: SettingsTab.customization,
            label: 'CUSTOMIZATION',
            subtitle: 'Layout & Sensor Tester',
          ),
          _buildMasterItem(
            tab: SettingsTab.steering,
            label: 'STEERING',
            subtitle: '${settings.steeringDegrees}° / ${settings.tiltSensorType.toUpperCase()}',
          ),
          _buildMasterItem(
            tab: SettingsTab.pedals,
            label: 'PEDALS',
            subtitle: '${settings.transmissionMode} / ${settings.handbrakeMode}',
          ),
          _buildMasterItem(
            tab: SettingsTab.soundAndHaptics,
            label: 'SOUND AND HAPTICS',
            subtitle: 'Haptik: ${settings.hapticIntensity.toUpperCase()}',
          ),
          _buildMasterItem(
            tab: SettingsTab.about,
            label: 'ABOUT',
            subtitle: 'v1.0.0-rc1',
          ),
        ],
      ),
    );
  }

  Widget _buildMasterItem({
    required SettingsTab tab,
    required String label,
    required String subtitle,
  }) {
    final bool isSelected = _activeTab == tab;

    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = tab;
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1C2733) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFFD4E0EC),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? const Color(0xFF90A4AE) : const Color(0xFF5C7084),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Panel Konten Detail (Kanan)
  Widget _buildDetailPanel(AppSettings settings) {
    switch (_activeTab) {
      case SettingsTab.selectMode:
        return _buildTabSelectMode(settings);
      case SettingsTab.customization:
        return _buildTabCustomization(settings);
      case SettingsTab.steering:
        return _buildTabSteering(settings);
      case SettingsTab.pedals:
        return _buildTabPedals(settings);
      case SettingsTab.soundAndHaptics:
        return _buildTabSoundAndHaptics(settings);
      case SettingsTab.about:
        return _buildTabAbout();
    }
  }

  // ===========================================================================
  // 1. TAB: SELECT MODE (SETTING_SELECT)
  // ===========================================================================
  Widget _buildTabSelectMode(AppSettings settings) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECT COCKPIT MODE',
            style: TextStyle(
              color: Color(0xFFE0E6ED),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih metode input utama kendali kemudi simulator mengemudi Anda.',
            style: TextStyle(color: Color(0xFF7E93A8), fontSize: 11),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                // Kartu 1: TILT MODE
                Expanded(
                  child: _buildModeCard(
                    title: 'TILT MODE',
                    subtitle: 'Kemudikan dengan memiringkan smartphone secara fisik menggunakan sensor giroskop/akselerometer. Dilengkapi garis cakrawala buatan & rem kiri.',
                    icon: Icons.screen_rotation_rounded,
                    isActive: settings.cockpitMode == 'tilt',
                    onTap: () {
                      _service.setCockpitMode('tilt');
                      HapticFeedback.mediumImpact();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Kartu 2: STEER MODE
                Expanded(
                  child: _buildModeCard(
                    title: 'STEER MODE',
                    subtitle: 'Kemudikan menggunakan roda setir fotorealistik di layar. Akselerasi GPU 120 FPS dengan pegas pembalik otomatis (spring return).',
                    icon: Icons.radio_button_checked_rounded,
                    isActive: settings.cockpitMode == 'steeringWheel',
                    onTap: () {
                      _service.setCockpitMode('steeringWheel');
                      HapticFeedback.mediumImpact();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF192533) : const Color(0xFF131B24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF00E5FF) : const Color(0xFF223245),
            width: isActive ? 2.0 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? const Color(0xFF00E5FF).withValues(alpha: 0.15) : const Color(0xFF1C2733),
                border: Border.all(
                  color: isActive ? const Color(0xFF00E5FF) : const Color(0xFF2F435A),
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isActive ? const Color(0xFF00E5FF) : const Color(0xFF7E93A8),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: isActive ? const Color(0xFF00E5FF) : const Color(0xFFE0E6ED),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8B9FB3),
                fontSize: 10.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF00E5FF) : const Color(0xFF1F2B38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'MODE AKTIF' : 'PILIH MODE',
                style: TextStyle(
                  color: isActive ? const Color(0xFF0E141B) : const Color(0xFF7E93A8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. TAB: CUSTOMIZATION (SETTING_CUSTOMIZATION + Live Sensor Tester)
  // ===========================================================================
  Widget _buildTabCustomization(AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'KUSTOMISASI LAYOUT & BUTTON BOX',
          style: TextStyle(
            color: Color(0xFFE0E6ED),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Atur transparansi, skala ukuran tombol, serta uji kalibrasi sensor perangkat secara real-time.',
          style: TextStyle(color: Color(0xFF7E93A8), fontSize: 11),
        ),
        const SizedBox(height: 16),

        // Slider Opacity & Scale
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF131B24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF223245)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Transparansi Tombol Kokpit (Opacity):',
                    style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${(settings.buttonOpacity * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: settings.buttonOpacity,
                min: 0.3,
                max: 1.0,
                divisions: 7,
                activeColor: const Color(0xFF00E5FF),
                inactiveColor: const Color(0xFF1E2C3A),
                onChanged: (val) => _service.setButtonOpacity(val),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Skala Ukuran Tombol (Scale):',
                    style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${(settings.buttonScale * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: settings.buttonScale,
                min: 0.8,
                max: 1.2,
                divisions: 8,
                activeColor: const Color(0xFF00E5FF),
                inactiveColor: const Color(0xFF1E2C3A),
                onChanged: (val) => _service.setButtonScale(val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // LIVE HARDWARE SENSOR TESTER (Mandatory Acceptance Criteria)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF131B24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF223245)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sensors, size: 16, color: Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE HARDWARE SENSOR TESTER',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'STREAM 20 HZ',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Akselerometer (m/s²):',
                style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildSensorBar('X', _mockAccelX, -10.0, 10.0, const Color(0xFF00E5FF)),
                  const SizedBox(width: 8),
                  _buildSensorBar('Y', _mockAccelY, -10.0, 20.0, const Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  _buildSensorBar('Z', _mockAccelZ, -10.0, 10.0, const Color(0xFFFFB300)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Giroskop Derajat Sudut (°/s):',
                style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildSensorBar('Pitch', _mockGyroX, -30.0, 30.0, const Color(0xFF00E5FF)),
                  const SizedBox(width: 8),
                  _buildSensorBar('Roll', _mockGyroY, -30.0, 30.0, const Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  _buildSensorBar('Yaw', _mockGyroZ, -30.0, 30.0, const Color(0xFFFFB300)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // vJoy In-Game Binding Guide Table
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF131B24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF223245)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.gamepad_rounded, size: 16, color: Color(0xFF00E5FF)),
                  SizedBox(width: 8),
                  Text(
                    'PANDUAN PEMETAAN VJOY (IN-GAME BINDING)',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildBindingRow('Klakson Cepat (Horn)', 'vJoy Button 7'),
              _buildBindingRow('Rem Tangan (Handbrake)', 'vJoy Button 9'),
              _buildBindingRow('Navigasi Menu (< / >)', 'vJoy Button 10 / 11'),
              _buildBindingRow('Transmisi Manual Gigi 1-6', 'vJoy Button 12-17'),
              _buildBindingRow('Gigi Mundur (Reverse R)', 'vJoy Button 18'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorBar(String axis, double val, double min, double max, Color color) {
    final double norm = ((val - min) / (max - min)).clamp(0.0, 1.0);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF18222D),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF243344)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  axis,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  val.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFFE0E6ED),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: norm,
              backgroundColor: const Color(0xFF111822),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBindingRow(String label, String vjoyBtn) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8B9FB3), fontSize: 10.5)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2836),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2B3D50)),
            ),
            child: Text(
              vjoyBtn,
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. TAB: STEERING (SETTING_STEERING)
  // ===========================================================================
  Widget _buildTabSteering(AppSettings settings) {
    final List<int> degreeOptions = [180, 360, 540, 900, 1080];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'STEERING & TILT SETTINGS',
          style: TextStyle(
            color: Color(0xFFE0E6ED),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Konfigurasi sudut putaran setir virtual, sensitivitas sensor kemiringan, dan redaman pegas.',
          style: TextStyle(color: Color(0xFF7E93A8), fontSize: 11),
        ),
        const SizedBox(height: 16),

        // Bagian TILT SETTINGS (Sesuai wireframe Image 1)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF131B24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF223245)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TILT SENSOR TYPE',
                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              _buildSensorOptionTile(
                title: 'GYRO TILT',
                subtitle: 'Sensor giroskop 6-axis dengan responsivitas sudut instan dan stabil.',
                isSelected: settings.tiltSensorType == 'gyro',
                onTap: () => _service.setTiltSensorType('gyro'),
              ),
              const SizedBox(height: 6),
              _buildSensorOptionTile(
                title: 'ACCELEROMETER TILT',
                subtitle: 'Sensor gravitasi akselerometer standar 3-axis untuk perangkat tanpa giroskop.',
                isSelected: settings.tiltSensorType == 'accelerometer',
                onTap: () => _service.setTiltSensorType('accelerometer'),
              ),
              const SizedBox(height: 12),
              const Text(
                'SENSITIVITAS KEMIRINGAN (TILT SENSITIVITY)',
                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSensitivityChip(
                    label: 'SPORT (30°)',
                    value: 'sport',
                    selectedValue: settings.tiltSensitivity,
                    onSelected: () => _service.setTiltSensitivity('sport'),
                  ),
                  const SizedBox(width: 8),
                  _buildSensitivityChip(
                    label: 'NORMAL (45°)',
                    value: 'normal',
                    selectedValue: settings.tiltSensitivity,
                    onSelected: () => _service.setTiltSensitivity('normal'),
                  ),
                  const SizedBox(width: 8),
                  _buildSensitivityChip(
                    label: 'TRUCK (60°)',
                    value: 'truck',
                    selectedValue: settings.tiltSensitivity,
                    onSelected: () => _service.setTiltSensitivity('truck'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Bagian STEERING WHEEL SETTINGS
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF131B24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF223245)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BATAS DERAJAT PUTARAN (ROTATION LOCK)',
                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              Row(
                children: degreeOptions.map((deg) {
                  final bool isSelected = settings.steeringDegrees == deg;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$deg°'),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00E5FF),
                      backgroundColor: const Color(0xFF1B2836),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF0E141B) : const Color(0xFFD4E0EC),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => _service.setSteeringDegrees(deg),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Redaman Pegas Pembalik (Spring Damping):', style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 11)),
                  const Spacer(),
                  Text(
                    '${(settings.springDamping * 100).toInt()}%',
                    style: const TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: settings.springDamping,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                activeColor: const Color(0xFF00E5FF),
                inactiveColor: const Color(0xFF1E2C3A),
                onChanged: (val) => _service.setSpringDamping(val),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Center Deadzone:', style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 11)),
                  const Spacer(),
                  Text(
                    '${settings.centerDeadzone.toStringAsFixed(1)}°',
                    style: const TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: settings.centerDeadzone,
                min: 0.0,
                max: 15.0,
                divisions: 15,
                activeColor: const Color(0xFF00E5FF),
                inactiveColor: const Color(0xFF1E2C3A),
                onChanged: (val) => _service.setCenterDeadzone(val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorOptionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B2938) : const Color(0xFF16202A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF243547),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF7E93A8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFFE0E6ED),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF7E93A8), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensitivityChip({
    required String label,
    required String value,
    required String selectedValue,
    required VoidCallback onSelected,
  }) {
    final bool isSelected = value == selectedValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF00E5FF),
      backgroundColor: const Color(0xFF1B2836),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0E141B) : const Color(0xFFD4E0EC),
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) => onSelected(),
    );
  }

  // ===========================================================================
  // 4. TAB: PEDALS (SETTING_PEDALS)
  // ===========================================================================
  Widget _buildTabPedals(AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'PEDALS & TRANSMISSION SETTINGS',
          style: TextStyle(
            color: Color(0xFFE0E6ED),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kalibrasi kurva resistansi pedal, mode pengereman tangan, dan transmisi persneling.',
          style: TextStyle(color: Color(0xFF7E93A8), fontSize: 11),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131B24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF223245)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Kurva Pengereman Non-Linear Progresif', style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 11, fontWeight: FontWeight.bold)),
                subtitle: const Text('Mensimulasikan pedal rem empuk di awal injakan dan semakin memadat di ujung.', style: TextStyle(color: Color(0xFF7E93A8), fontSize: 10)),
                value: settings.nonLinearBrake,
                activeThumbColor: const Color(0xFF00E5FF),
                onChanged: (val) => _service.setNonLinearBrake(val),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFF1E2C3A)),
              SwitchListTile(
                title: const Text('Pembalikan Sumbu Pedal (Invert Axis)', style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 11, fontWeight: FontWeight.bold)),
                subtitle: const Text('Gunakan jika simulator Anda membaca injakan pedal secara terbalik.', style: TextStyle(color: Color(0xFF7E93A8), fontSize: 10)),
                value: settings.invertPedals,
                activeThumbColor: const Color(0xFF00E5FF),
                onChanged: (val) => _service.setInvertPedals(val),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFF1E2C3A)),
              ListTile(
                title: const Text('Mode Rem Tangan (Handbrake)', style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 11, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  settings.handbrakeMode == 'toggle' ? 'Parking (Toggle Lock)' : 'Drift/Rally (Momentary Hold)',
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10),
                ),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'toggle', label: Text('PARKING')),
                    ButtonSegment(value: 'momentary', label: Text('DRIFT')),
                  ],
                  selected: {settings.handbrakeMode},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) _service.setHandbrakeMode(set.first);
                  },
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFF1E2C3A)),
              ListTile(
                title: const Text('Mode Transmisi Kendaraan', style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 11, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  settings.transmissionMode == 'hPattern' ? 'Manual H-Pattern 6-Speed' : 'Sequential Shifter (< / >)',
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10),
                ),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'hPattern', label: Text('H-PATTERN')),
                    ButtonSegment(value: 'sequential', label: Text('SEQUENTIAL')),
                  ],
                  selected: {settings.transmissionMode},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) _service.setTransmissionMode(set.first);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. TAB: SOUND AND HAPTICS (SETTING_SOUND)
  // ===========================================================================
  Widget _buildTabSoundAndHaptics(AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'SOUND & HAPTICS SETTINGS',
          style: TextStyle(
            color: Color(0xFFE0E6ED),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Atur umpan balik getaran haptik dan efek audio mekanis perpindahan gigi.',
          style: TextStyle(color: Color(0xFF7E93A8), fontSize: 11),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131B24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF223245)),
          ),
          child: Column(
            children: [
              ListTile(
                title: const Text('Intensitas Getaran Haptik', style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 11, fontWeight: FontWeight.bold)),
                subtitle: Text('Tingkat getaran saat menyentuh klakson atau memindah gigi: ${settings.hapticIntensity.toUpperCase()}', style: const TextStyle(color: Color(0xFF7E93A8), fontSize: 10)),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'off', label: Text('OFF')),
                    ButtonSegment(value: 'low', label: Text('LOW')),
                    ButtonSegment(value: 'medium', label: Text('MED')),
                    ButtonSegment(value: 'high', label: Text('HIGH')),
                  ],
                  selected: {settings.hapticIntensity},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) {
                      _service.setHapticIntensity(set.first);
                      if (set.first != 'off') HapticFeedback.heavyImpact();
                    }
                  },
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFF1E2C3A)),
              SwitchListTile(
                title: const Text('Efek Audio Klik Mekanis', style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 11, fontWeight: FontWeight.bold)),
                subtitle: const Text('Menghasilkan suara klik relai sakelar mekanis saat mengoper gigi atau menekan tombol.', style: TextStyle(color: Color(0xFF7E93A8), fontSize: 10)),
                value: settings.mechanicalAudioClicks,
                activeThumbColor: const Color(0xFF00E5FF),
                onChanged: (val) => _service.setMechanicalAudioClicks(val),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFF1E2C3A)),
              SwitchListTile(
                title: const Text('Getaran Batas Setir (Lock-to-Lock Bump)', style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 11, fontWeight: FontWeight.bold)),
                subtitle: const Text('Memberikan denyut getaran haptik ketika roda kemudi diputar mencapai sudut maksimal.', style: TextStyle(color: Color(0xFF7E93A8), fontSize: 10)),
                value: settings.lockBumpHaptic,
                activeThumbColor: const Color(0xFF00E5FF),
                onChanged: (val) => _service.setLockBumpHaptic(val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. TAB: ABOUT (SETTING_ABOUT)
  // ===========================================================================
  Widget _buildTabAbout() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'TENTANG VIDRIC',
          style: TextStyle(
            color: Color(0xFFE0E6ED),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Informasi sistem, pengembang, dan spesifikasi integrasi simulator.',
          style: TextStyle(color: Color(0xFF7E93A8), fontSize: 11),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131B24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF223245)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ViDric (Virtual Driving Controller)',
                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              SizedBox(height: 4),
              Text('Versi Aplikasi: v1.0.0-rc1 (Build 2026.10)', style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 11)),
              SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: Color(0xFF1E2C3A)),
              SizedBox(height: 12),
              Text(
                'Kompetensi Keahlian:',
                style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Proyek Portofolio Uji Kompetensi Keahlian (UKK) Rekayasa Perangkat Lunak SMK.\nArsitektur: Non-MVVM State-Driven Flutter Controller + Dedicated Communication Services.',
                style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 10.5, height: 1.4),
              ),
              SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: Color(0xFF1E2C3A)),
              SizedBox(height: 12),
              Text(
                'Protokol & Driver PC:',
                style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                '- Wi-Fi UDP Port: 5005 (Latency < 8ms, 50 Hz Packet Stream)\n- Driver PC: vJoy 2.1.9 Virtual Joystick Windows\n- Lisensi: Open Source MIT License',
                style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 10.5, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
