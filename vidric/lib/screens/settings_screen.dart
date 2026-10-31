import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../models/custom_button_model.dart';
import '../models/layout_profile.dart';
import '../services/custom_button_service.dart';
import '../services/settings_service.dart';
import '../services/udp_service.dart';
import '../widgets/qr_scanner_dialog.dart';
import '../widgets/connection_modal_widget.dart';
import '../widgets/add_edit_button_dialog.dart';

/// Layanan Navigasi Tab Pengaturan (Master List).
enum SettingsTab {
  selectMode,
  connection,
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
  final UdpService _udpService = UdpService.instance;

  // Controller Input Koneksi UDP
  late TextEditingController _ipController;
  late TextEditingController _portController;
  bool _isTestingPing = false;
  String? _pingResult;
  bool _pingSuccess = false;

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
    _ipController = TextEditingController(text: _udpService.targetIp);
    _portController = TextEditingController(text: _udpService.targetPort.toString());
    _startLiveSensorStream();
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _openQrScanner() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const QrScannerDialog(),
    );

    if (result != null && mounted) {
      setState(() {
        _ipController.text = result['ip'] ?? _ipController.text;
        _portController.text = (result['port'] ?? 5005).toString();
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ QR Code berhasil dipindai: ${_ipController.text}:${_portController.text}'),
          backgroundColor: const Color(0xFF1B2836),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }

  Future<void> _runPingTest() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 5005;

    setState(() {
      _isTestingPing = true;
      _pingResult = null;
    });

    final success = await _udpService.testPing(ip, port);

    if (mounted) {
      setState(() {
        _isTestingPing = false;
        _pingSuccess = success;
        _pingResult = success
            ? 'PING BERHASIL (Target PC Merespons)'
            : 'PING TIMEOUT (Pastikan PC & Ponsel satu Wi-Fi)';
      });
    }
  }

  Future<void> _toggleConnection() async {
    HapticFeedback.mediumImpact();
    if (_udpService.isConnected) {
      _udpService.disconnect();
    } else {
      final ip = _ipController.text.trim();
      final port = int.tryParse(_portController.text.trim()) ?? 5005;
      final success = await _udpService.connect(ip: ip, port: port);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Gagal terhubung ke IP target. Periksa kembali alamat IP.'),
            backgroundColor: Color(0xFF8B1E1E),
          ),
        );
      }
    }
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
          ValueListenableBuilder<NetworkMetrics>(
            valueListenable: _udpService.metrics,
            builder: (context, net, _) {
              return _buildMasterItem(
                tab: SettingsTab.connection,
                label: 'CONNECTION',
                subtitle: net.isConnected ? '50 Hz ONLINE' : 'UDP DISCONNECTED',
              );
            },
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
      case SettingsTab.connection:
        return _buildTabConnection();
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
                    iconWidget: Image.asset(
                      'assets/images/steering_wheel_cropped2.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                    ),
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
    IconData? icon,
    Widget? iconWidget,
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
              child: Center(
                child: iconWidget ??
                    Icon(
                      icon,
                      size: 32,
                      color: isActive ? const Color(0xFF00E5FF) : const Color(0xFF7E93A8),
                    ),
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
  // 2. TAB: CONNECTION (SETTING_CONNECTION)
  // ===========================================================================
  Widget _buildTabConnection() {
    return ValueListenableBuilder<NetworkMetrics>(
      valueListenable: _udpService.metrics,
      builder: (context, metrics, _) {
        final isConnected = metrics.isConnected;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                    boxShadow: isConnected
                        ? [
                            const BoxShadow(
                              color: Color(0xFF00E676),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PENGATURAN KONEKSI WI-FI UDP',
                  style: TextStyle(
                    color: Color(0xFFE0E6ED),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Transmisi paket telemetri 50 Hz ke PC Companion dan driver vJoy Virtual Joystick.',
              style: TextStyle(color: Color(0xFF7E93A8), fontSize: 11),
            ),
            const SizedBox(height: 16),

            // Form Target PC
            Container(
              padding: const EdgeInsets.all(16),
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
                      // Input IP
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ALAMAT IP SERVER PC:',
                              style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16212D),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF26394D)),
                              ),
                              child: TextField(
                                controller: _ipController,
                                style: const TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace', fontSize: 12),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Contoh: 192.168.1.10',
                                  hintStyle: TextStyle(color: Color(0xFF486178), fontSize: 11),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Input Port
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PORT UDP:',
                              style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16212D),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF26394D)),
                              ),
                              child: TextField(
                                controller: _portController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace', fontSize: 12),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tombol Scan QR
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: InkWell(
                          onTap: _openQrScanner,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C2B3A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF00E5FF)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.qr_code_scanner, color: Color(0xFF00E5FF), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'SCAN QR',
                                  style: TextStyle(
                                    color: Color(0xFF00E5FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Ping & Status
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isTestingPing ? null : _runPingTest,
                        icon: _isTestingPing
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF00E5FF)),
                              )
                            : const Icon(Icons.network_check, size: 14, color: Color(0xFF7E93A8)),
                        label: const Text(
                          'TEST PING',
                          style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF26394D)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_pingResult != null)
                        Expanded(
                          child: Text(
                            _pingResult!,
                            style: TextStyle(
                              color: _pingSuccess ? const Color(0xFF00E676) : const Color(0xFFFFB300),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Kartu Metrik Live Transmisi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF131B24),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF223245)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'METRIK TRANSMISI REAL-TIME',
                    style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricBadge(
                          'STATUS',
                          metrics.status.name.toUpperCase(),
                          isConnected ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                        ),
                        const SizedBox(width: 24),
                        _buildMetricBadge(
                          'TX RATE (HZ)',
                          '${metrics.packetsPerSecond.toStringAsFixed(1)} Hz',
                          const Color(0xFF00E5FF),
                        ),
                        const SizedBox(width: 24),
                        _buildMetricBadge(
                          'PAKET TERKIRIM',
                          metrics.packetsSent.toString(),
                          const Color(0xFFE0E6ED),
                        ),
                        const SizedBox(width: 24),
                        _buildMetricBadge(
                          'LATENSI SOKET',
                          '${metrics.latencyMs} ms',
                          const Color(0xFF00E676),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tombol Hubungkan / Putuskan
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _toggleConnection,
                icon: Icon(
                  isConnected ? Icons.link_off : Icons.link,
                  size: 16,
                  color: isConnected ? Colors.white : const Color(0xFF0E141B),
                ),
                label: Text(
                  isConnected ? 'PUTUSKAN KONEKSI' : 'HUBUNGKAN KE PC COMPANION (50 HZ)',
                  style: TextStyle(
                    color: isConnected ? Colors.white : const Color(0xFF0E141B),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected ? const Color(0xFFB71C1C) : const Color(0xFF00E5FF),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Kartu Watchdog Failsafe
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF131B24),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF223245)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, size: 16, color: Color(0xFF00E676)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failsafe Watchdog Aktif (300 ms): PC otomatis mereset seluruh sumbu ke netral jika koneksi terganggu.',
                      style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 10.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricBadge(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF7E93A8), fontSize: 9.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Future<void> _openAddCustomButtonDialog() async {
    final newBtn = await showDialog<CustomButtonModel>(
      context: context,
      builder: (context) => const AddEditButtonDialog(),
    );
    if (newBtn != null) {
      await CustomButtonService.instance.addButton(newBtn);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Tombol "${newBtn.label}" (vJoy ${newBtn.vjoyButton}) berhasil ditambahkan ke kokpit.'),
            backgroundColor: const Color(0xFF1B2836),
            duration: const Duration(milliseconds: 1200),
          ),
        );
      }
    }
  }

  Future<void> _promptCreateProfile() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131D27),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF283B4E)),
        ),
        title: const Text(
          'BUAT PROFIL LAYOUT BARU',
          style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Contoh: ETS2 Truk, Assetto Corsa',
            hintStyle: const TextStyle(color: Color(0xFF455A64), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF18232F),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('BATAL', style: TextStyle(color: Color(0xFF7E93A8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: const Color(0xFF0D141C),
            ),
            child: const Text('BUAT'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      await CustomButtonService.instance.createProfile(name.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📁 Profil "$name" berhasil dibuat.'),
            backgroundColor: const Color(0xFF1B2836),
            duration: const Duration(milliseconds: 1000),
          ),
        );
      }
    }
  }

  // ===========================================================================
  // 3. TAB: CUSTOMIZATION (SETTING_CUSTOMIZATION + Live Sensor Tester)
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

        // 1. Modus Edit Layar Penuh & Tambah Tombol Cepat
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
                  Icon(Icons.dashboard_customize_rounded, size: 16, color: Color(0xFF00E5FF)),
                  SizedBox(width: 8),
                  Text(
                    'MODUS EDIT TATA LETAK (ON-SCREEN DRAG & DROP)',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Masuk ke layar kokpit interaktif untuk menggeser posisi tombol bebas ke koordinat mana pun dengan panduan kisi Snap to Grid.',
                style: TextStyle(color: Color(0xFF7E93A8), fontSize: 10.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        CustomButtonService.instance.toggleEditMode(true);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.touch_app_rounded, size: 15),
                      label: const Text(
                        'BUKA EDITOR LAYAR PENUH',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: const Color(0xFF0D141C),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openAddCustomButtonDialog,
                      icon: const Icon(Icons.add_circle_outline, size: 15, color: Color(0xFF00E676)),
                      label: const Text(
                        'TAMBAH TOMBOL BARU (+)',
                        style: TextStyle(color: Color(0xFF00E676), fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1E4631)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Profil Manajer Tata Letak (Profile Manager)
        ValueListenableBuilder<LayoutProfile>(
          valueListenable: CustomButtonService.instance.activeProfile,
          builder: (context, activeProf, _) {
            return ValueListenableBuilder<List<LayoutProfile>>(
              valueListenable: CustomButtonService.instance.allProfiles,
              builder: (context, allProfs, _) {
                return Container(
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
                          const Icon(Icons.folder_shared_rounded, size: 16, color: Color(0xFFFFB300)),
                          SizedBox(width: 8),
                          const Text(
                            'MANAJER PROFIL TATA LETAK',
                            style: TextStyle(
                              color: Color(0xFFFFB300),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${activeProf.buttons.length} Tombol Terpasang',
                            style: const TextStyle(
                              color: Color(0xFF7E93A8),
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF18232F),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF283B4E)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: activeProf.id,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF18232F),
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFFB300)),
                                  style: const TextStyle(
                                    color: Color(0xFFE0E6ED),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  items: allProfs.map((p) {
                                    return DropdownMenuItem<String>(
                                      value: p.id,
                                      child: Text(p.name),
                                    );
                                  }).toList(),
                                  onChanged: (id) {
                                    if (id != null) {
                                      CustomButtonService.instance.switchProfile(id);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _promptCreateProfile,
                            icon: const Icon(Icons.add, size: 18, color: Color(0xFF00E5FF)),
                            tooltip: 'Buat Profil Baru',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF1B2836),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              CustomButtonService.instance.resetToDefaultProfile();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profil layout dikembalikan ke standar awal.'),
                                  duration: Duration(milliseconds: 900),
                                  backgroundColor: Color(0xFF1B2836),
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF7E93A8)),
                            tooltip: 'Reset Standar',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF1B2836),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
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
              _buildBindingRow('Kamera Cockpit & Look', 'vJoy Button 20-23'),
              const Divider(color: Color(0xFF1F2F40), height: 16),
              const Text(
                'TOMBOL KUSTOM AKTIF PENGGUNA:',
                style: TextStyle(color: Color(0xFF7E93A8), fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<LayoutProfile>(
                valueListenable: CustomButtonService.instance.activeProfile,
                builder: (context, prof, _) {
                  if (prof.buttons.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Belum ada tombol kustom terpasang. Tekan Tambah Tombol (+) di atas.',
                        style: TextStyle(color: Color(0xFF55687A), fontSize: 10),
                      ),
                    );
                  }
                  return Column(
                    children: prof.buttons.map((b) {
                      final modeStr = b.isToggle ? 'Toggle' : 'Push';
                      return _buildBindingRow('${b.label} ($modeStr)', 'vJoy Button ${b.vjoyButton}');
                    }).toList(),
                  );
                },
              ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ViDric (Virtual Driving Controller)',
                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              const SizedBox(height: 4),
              const Text('Versi Aplikasi: v1.0.0-rc1 (Build 2026.10)', style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 11)),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Color(0xFF1E2C3A)),
              const SizedBox(height: 12),
              const Text(
                'Kompetensi Keahlian:',
                style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Proyek Portofolio Uji Kompetensi Keahlian (UKK) Rekayasa Perangkat Lunak SMK.\nArsitektur: Non-MVVM State-Driven Flutter Controller + Dedicated Communication Services.',
                style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 10.5, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Color(0xFF1E2C3A)),
              const SizedBox(height: 12),
              const Text(
                'Protokol & Driver PC:',
                style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '- Wi-Fi UDP Port: 5005 (Latency < 8ms, 50 Hz Packet Stream)\n- Driver PC: vJoy 2.1.9 Virtual Joystick Windows\n- Lisensi: Open Source MIT License',
                style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 10.5, height: 1.4),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => ConnectionModalWidget.show(context),
                  icon: const Icon(Icons.wifi, size: 14, color: Color(0xFF00E5FF)),
                  label: const Text(
                    'PENGATURAN KONEKSI UDP / SCAN QR',
                    style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00E5FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
