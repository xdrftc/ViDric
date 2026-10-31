import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../models/control_packet.dart';
import '../services/custom_button_service.dart';
import '../services/settings_service.dart';
import '../services/tilt_sensor_service.dart';
import '../services/udp_service.dart';
import '../widgets/steering_wheel_widget.dart';
import '../widgets/analog_pedal_widget.dart';
import '../widgets/h_pattern_shifter_widget.dart';
import '../widgets/nav_cluster_widget.dart';
import '../widgets/artificial_horizon_gauge_widget.dart';
import '../widgets/dynamic_button_layer.dart';
import '../widgets/sequential_shifter_widget.dart';
import 'settings_screen.dart';

enum CockpitMode {
  steeringWheel,
  tilt,
}

/// Main Cockpit Controller Screen (Landscape Locked).
///
/// Faithfully reproduces the user's wireframe design:
/// - STEERING MODE:
///   - Top Left: [MENU], [MAP], [CAMERA]
///   - Top Right: GYRO CAM : ACTIVE, (O) Recenter Camera, [*] Settings
///   - Left: SteeringWheelWidget (custom image asset, atan2 rotation, damped spring, center horn)
///   - Center Bottom: NavClusterWidget (< ENTER > / 1 2 3)
///   - Center-Right: HPatternShifterWidget (Gears 1-6, N, R via persneling_tight.png) & Handbrake
///   - Right Bottom: AnalogPedalWidget for Brake (pedal_rem_tight.png) and Gas (pedal_gas_tight.png)
/// - TILT MODE:
///   - Top Left adds [RECENTER] zero calibration button
///   - Center: Artificial Horizon Gauge with live degrees
///   - Left Bottom: Relocated Brake pedal for left-thumb braking
///   - Right Bottom: Handbrake & Gas pedal
class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  // Mode selection
  CockpitMode _activeMode = CockpitMode.steeringWheel;

  // Telemetry States
  double _steering = 0.0;
  double _steeringAngleDeg = 0.0;
  double _gas = 0.0;
  double _brake = 0.0;
  double _clutch = 0.0;
  bool _isHandbrakeActive = false;
  String _activeGear = 'N';
  final Set<int> _activeButtons = <int>{};
  int _sequenceNumber = 0;

  // Steering Asset
  final String _selectedWheelAsset = 'assets/images/steering_wheel_cropped.png';

  @override
  void initState() {
    super.initState();
    _lockLandscapeAndImmersive();
    _syncWithSettings();
    SettingsService.instance.settings.addListener(_onSettingsUpdated);
    TiltSensorService.instance.telemetry.addListener(_onTiltTelemetry);
    TiltSensorService.instance.startListening();
    CustomButtonService.instance.init();
    UdpService.instance.init();
    UdpService.instance.packetProvider = buildCurrentPacket;
  }

  @override
  void dispose() {
    SettingsService.instance.settings.removeListener(_onSettingsUpdated);
    TiltSensorService.instance.telemetry.removeListener(_onTiltTelemetry);
    TiltSensorService.instance.stopListening();
    UdpService.instance.disconnect();
    super.dispose();
  }

  void _onTiltTelemetry() {
    if (_activeMode == CockpitMode.tilt && mounted) {
      final t = TiltSensorService.instance.current;
      setState(() {
        _steering = t.normalizedSteering;
        _steeringAngleDeg = t.filteredAngleDeg;
      });
    }
  }

  void _syncWithSettings() {
    final mode = SettingsService.instance.current.cockpitMode;
    _activeMode = mode == 'tilt' ? CockpitMode.tilt : CockpitMode.steeringWheel;
  }

  void _onSettingsUpdated() {
    if (mounted) {
      setState(() {
        _syncWithSettings();
      });
    }
  }

  void _lockLandscapeAndImmersive() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _onSteeringChanged(double normalizedValue) {
    setState(() {
      _steering = normalizedValue;
    });
  }

  void _onSteeringDegreeChanged(double degrees) {
    setState(() {
      _steeringAngleDeg = degrees;
    });
  }

  void _onHornPressed() {
    setState(() {
      _activeButtons.add(7); // vJoy Button 7 = Horn
    });
  }

  void _onHornReleased() {
    setState(() {
      _activeButtons.remove(7);
    });
  }

  void _toggleHandbrake() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isHandbrakeActive = !_isHandbrakeActive;
      if (_isHandbrakeActive) {
        _activeButtons.add(9); // vJoy Button 9 = Handbrake
      } else {
        _activeButtons.remove(9);
      }
    });
  }

  void _onGearChanged(String gear, int? vjoyBtn) {
    setState(() {
      // Clear previous gear buttons (Btns 12-18)
      _activeButtons.removeWhere((btn) => btn >= 12 && btn <= 18);
      _activeGear = gear;
      if (vjoyBtn != null) {
        _activeButtons.add(vjoyBtn);
      }
    });
  }

  void _toggleCockpitMode() {
    HapticFeedback.mediumImpact();
    final newMode = _activeMode == CockpitMode.steeringWheel
        ? 'tilt'
        : 'steeringWheel';
    SettingsService.instance.setCockpitMode(newMode);
  }

  void _recenterZero() {
    HapticFeedback.heavyImpact();
    TiltSensorService.instance.recenterZero();
    setState(() {
      _steering = 0.0;
      _steeringAngleDeg = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎯 Recenter Zero: Posisi sudut netral berhasil dikalibrasi (0.0°).'),
        duration: Duration(milliseconds: 900),
        backgroundColor: Color(0xFF1B2836),
      ),
    );
  }

  void _triggerMomentaryButton(int buttonId) {
    HapticFeedback.lightImpact();
    setState(() {
      _activeButtons.add(buttonId);
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _activeButtons.remove(buttonId);
        });
      }
    });
  }

  void _onSequentialShift(String newGear, int pulseVjoyBtn) {
    setState(() {
      _activeGear = newGear;
      _activeButtons.add(pulseVjoyBtn);
    });
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) {
        setState(() {
          _activeButtons.remove(pulseVjoyBtn);
        });
      }
    });
  }

  void _onCustomButtonChanged(int vjoyButton, bool isPressed) {
    setState(() {
      if (isPressed) {
        _activeButtons.add(vjoyButton);
      } else {
        _activeButtons.remove(vjoyButton);
      }
    });
  }

  ControlPacket buildCurrentPacket() {
    _sequenceNumber++;
    return ControlPacket(
      mode: _activeMode == CockpitMode.steeringWheel ? 'guiWheel' : 'accelerometer',
      steering: _steering,
      gas: _gas,
      brake: _brake,
      clutch: _clutch,
      buttons: _activeButtons.toList()..sort(),
      seq: _sequenceNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131D24),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          child: Stack(
            children: [
              // 1. Top Header Controls (Left Action Buttons & Right Status Cluster)
              Align(
                alignment: Alignment.topCenter,
                child: _buildTopHeader(),
              ),

              // 2. Cockpit Main Layout (Changes depending on Steering vs Tilt Mode)
              Positioned.fill(
                top: 48,
                child: _activeMode == CockpitMode.steeringWheel
                    ? _buildSteeringModeLayout()
                    : _buildTiltModeLayout(),
              ),

              // 3. Lapisan Tombol Kustom Dinamis (Dynamic Draggable Button Box)
              Positioned.fill(
                top: 48,
                child: ValueListenableBuilder<AppSettings>(
                  valueListenable: SettingsService.instance.settings,
                  builder: (context, settings, _) {
                    return DynamicButtonLayer(
                      opacity: settings.buttonOpacity,
                      scale: settings.buttonScale,
                      onButtonStateChanged: _onCustomButtonChanged,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Bar matching wireframe: [MENU] [MAP] / [CAMERA] on left, Status & Settings on right.
  Widget _buildTopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Left Cluster: [MENU] [MAP] on row 1, [CAMERA] on row 2
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton('MENU', () => _triggerMomentaryButton(20)),
                const SizedBox(width: 8),
                _buildActionButton('MAP', () => _triggerMomentaryButton(21)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton('CAMERA', () => _triggerMomentaryButton(22)),
                if (_activeMode == CockpitMode.tilt) ...[
                  const SizedBox(width: 8),
                  _buildActionButton('RECENTER', _recenterZero),
                ],
              ],
            ),
          ],
        ),

        const Spacer(),

        // Top Right Cluster: [GYRO CAM: ACTIVE], (O) Recenter, [*] Settings
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode Switcher Pill (Interactive toggle between Steer & Tilt)
            GestureDetector(
              onTap: _toggleCockpitMode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2733),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2E3E50), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _activeMode == CockpitMode.steeringWheel
                          ? Icons.sports_esports_rounded
                          : Icons.screen_rotation_rounded,
                      size: 13,
                      color: const Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _activeMode == CockpitMode.steeringWheel ? 'STEER MODE' : 'TILT MODE',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // UDP Connection Status Pill (Tapping opens ConnectionModalWidget)
            ValueListenableBuilder<NetworkMetrics>(
              valueListenable: UdpService.instance.metrics,
              builder: (context, net, _) {
                final isLive = net.isConnected;
                return InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(
                          initialTab: SettingsTab.connection,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2733),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLive ? const Color(0xFF00E676) : const Color(0xFF2E3E50),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLive ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isLive ? 'UDP 50 HZ' : 'UDP OFF',
                          style: TextStyle(
                            color: isLive ? const Color(0xFF00E676) : const Color(0xFFD4E0EC),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 8),

            // GYRO CAM Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2733),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E3E50), width: 1.2),
              ),
              child: const Text(
                'GYRO CAM : ACTIVE',
                style: TextStyle(
                  color: Color(0xFFD4E0EC),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Circular Camera Reset Button (O)
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _triggerMomentaryButton(23);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF222E3A),
                  border: Border.all(color: const Color(0xFF334455), width: 1.2),
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8FA3B8),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Edit Layout Button (Drag & Drop Mode)
            ValueListenableBuilder<bool>(
              valueListenable: CustomButtonService.instance.isEditMode,
              builder: (context, isEditing, _) {
                return InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    CustomButtonService.instance.toggleEditMode();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isEditing ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : const Color(0xFF222E3A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isEditing ? const Color(0xFF00E5FF) : const Color(0xFF334455),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.dashboard_customize_rounded,
                          size: 15,
                          color: isEditing ? const Color(0xFF00E5FF) : const Color(0xFFD4E0EC),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isEditing ? 'EDITING' : 'LAYOUT',
                          style: TextStyle(
                            color: isEditing ? const Color(0xFF00E5FF) : const Color(0xFFD4E0EC),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 8),

            // Settings Gear Button [*]
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF222E3A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334455), width: 1.2),
                ),
                child: const Icon(
                  Icons.settings,
                  size: 18,
                  color: Color(0xFFD4E0EC),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF212C37),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF324252), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD4E0EC),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// STEERING MODE Layout: Roda setir di kiri, Nav cluster di tengah, Shifter & Pedals di kanan.
  Widget _buildSteeringModeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Left: Steering Wheel Module
        Expanded(
          flex: 4,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SteeringWheelWidget(
              assetPath: _selectedWheelAsset,
              size: 265.0,
              maxAngleDegrees: 90.0,
              autoSpringReturn: true,
              onAngleChanged: _onSteeringChanged,
              onRawDegreeChanged: _onSteeringDegreeChanged,
              onHornPressed: _onHornPressed,
              onHornReleased: _onHornReleased,
              showDegreeBadge: true,
            ),
          ),
        ),

        // 2. Center Bottom: Navigation Cluster (< ENTER > / 1 2 3)
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: NavClusterWidget(
                onLeftPressed: () => _triggerMomentaryButton(4),
                onEnterPressed: () => _triggerMomentaryButton(7),
                onRightPressed: () => _triggerMomentaryButton(5),
                onBtn1Pressed: () => _triggerMomentaryButton(1),
                onBtn2Pressed: () => _triggerMomentaryButton(2),
                onBtn3Pressed: () => _triggerMomentaryButton(3),
              ),
            ),
          ),
        ),

        // 3. Right: H-Pattern Shifter above Brake, Handbrake above Gas (Wireframe 2x2 Grid)
        Expanded(
          flex: 4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Column 1: Shifter (Sequential or H-Pattern) on top, Clutch & Brake Pedals directly below
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Shifter
                  ValueListenableBuilder<AppSettings>(
                    valueListenable: SettingsService.instance.settings,
                    builder: (context, settings, _) {
                      if (settings.transmissionMode == 'sequential') {
                        return SequentialShifterWidget(
                          activeGear: _activeGear,
                          onShift: _onSequentialShift,
                          width: 105,
                          height: 130,
                        );
                      }
                      return HPatternShifterWidget(
                        activeGear: _activeGear,
                        onGearChanged: _onGearChanged,
                        width: 105,
                        height: 130,
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // Pedals: Optional Clutch & Brake Pedal
                  ValueListenableBuilder<AppSettings>(
                    valueListenable: SettingsService.instance.settings,
                    builder: (context, settings, _) {
                      final hasClutch = settings.enableClutchPedal;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hasClutch) ...[
                            AnalogPedalWidget(
                              label: 'CLUTCH',
                              assetPath: 'assets/images/pedal_rem_tight.png',
                              activeColor: const Color(0xFF00E5FF),
                              value: _clutch,
                              width: 66,
                              height: 105,
                              onChanged: (val) {
                                setState(() {
                                  _clutch = val;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                          AnalogPedalWidget(
                            label: 'BRAKE',
                            assetPath: 'assets/images/pedal_rem_tight.png',
                            activeColor: const Color(0xFFFF1744),
                            value: _brake,
                            width: hasClutch ? 66 : 82,
                            height: 105,
                            onChanged: (val) {
                              setState(() {
                                _brake = val;
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Column 2: Handbrake Lever on top, Gas Pedal directly below
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Handbrake Lever
                  _buildHandbrakeLever(),

                  const SizedBox(height: 8),

                  // Gas Pedal (gas)
                  AnalogPedalWidget(
                    label: 'THROTTLE',
                    assetPath: 'assets/images/pedal_gas_tight.png',
                    activeColor: const Color(0xFF00E676),
                    value: _gas,
                    width: 78,
                    height: 155,
                    onChanged: (val) {
                      setState(() {
                        _gas = val;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// TILT MODE Layout: Horizon line di tengah, Brake di kiri bawah, Gas di kanan bawah.
  Widget _buildTiltModeLayout() {
    return Stack(
      children: [
        // Center: Artificial Horizon Gauge with Rotating Horizon & Degree Scale
        Align(
          alignment: const Alignment(0.0, -0.2),
          child: ArtificialHorizonGaugeWidget(
            angleDeg: _steeringAngleDeg,
            maxAngleDeg: SettingsService.instance.current.tiltMaxAngle,
            pitchDeg: TiltSensorService.instance.current.pitchDeg,
            isCalibrated: TiltSensorService.instance.current.isCalibrated,
            size: 190,
          ),
        ),

        // Left Bottom: Relocated Brake & Clutch Pedal for left-thumb operation
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6.0, left: 10.0),
            child: ValueListenableBuilder<AppSettings>(
              valueListenable: SettingsService.instance.settings,
              builder: (context, settings, _) {
                final hasClutch = settings.enableClutchPedal;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasClutch) ...[
                      AnalogPedalWidget(
                        label: 'CLUTCH',
                        assetPath: 'assets/images/pedal_rem_tight.png',
                        activeColor: const Color(0xFF00E5FF),
                        value: _clutch,
                        width: 72,
                        height: 120,
                        onChanged: (val) {
                          setState(() {
                            _clutch = val;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    AnalogPedalWidget(
                      label: 'BRAKE',
                      assetPath: 'assets/images/pedal_rem_tight.png',
                      activeColor: const Color(0xFFFF1744),
                      value: _brake,
                      width: hasClutch ? 72 : 88,
                      height: 120,
                      onChanged: (val) {
                        setState(() {
                          _brake = val;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Center Bottom: Navigation Cluster
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: NavClusterWidget(
              onLeftPressed: () => _triggerMomentaryButton(4),
              onEnterPressed: () => _triggerMomentaryButton(7),
              onRightPressed: () => _triggerMomentaryButton(5),
              onBtn1Pressed: () => _triggerMomentaryButton(1),
              onBtn2Pressed: () => _triggerMomentaryButton(2),
              onBtn3Pressed: () => _triggerMomentaryButton(3),
            ),
          ),
        ),

        // Right Bottom: Handbrake Lever above Gas Pedal (Wireframe Layout)
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6.0, right: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildHandbrakeLever(),
                const SizedBox(height: 10),
                AnalogPedalWidget(
                  label: 'THROTTLE',
                  assetPath: 'assets/images/pedal_gas_tight.png',
                  activeColor: const Color(0xFF00E676),
                  value: _gas,
                  width: 80,
                  height: 160,
                  onChanged: (val) {
                    setState(() {
                      _gas = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Handbrake lever widget switching between pulled and released image assets.
  Widget _buildHandbrakeLever() {
    final asset = _isHandbrakeActive
        ? 'assets/images/handbrake_tight.png'
        : 'assets/images/handbrake_down_tight.png';

    return GestureDetector(
      onTap: _toggleHandbrake,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 100,
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _isHandbrakeActive
              ? const Color(0xFFFF1744).withValues(alpha: 0.15)
              : const Color(0xFF16202A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isHandbrakeActive ? const Color(0xFFFF1744) : const Color(0xFF283647),
            width: 1.2,
          ),
        ),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pan_tool_alt_rounded,
                  size: 18,
                  color: _isHandbrakeActive ? const Color(0xFFFF1744) : Colors.white60,
                ),
                const SizedBox(width: 4),
                Text(
                  _isHandbrakeActive ? 'PARK ON' : 'PARK OFF',
                  style: TextStyle(
                    color: _isHandbrakeActive ? const Color(0xFFFF1744) : Colors.white60,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
