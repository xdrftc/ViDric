import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/control_packet.dart';
import '../widgets/steering_wheel_widget.dart';

/// Main Cockpit Controller Screen (Landscape Locked).
///
/// Implements Issue #5:
/// - Realistic steering wheel rotation using user image asset.
/// - Live angle degree readout and normalized output (-1.0 to 1.0).
/// - Instant center horn button (vJoy Button 7).
/// - Fullscreen sticky immersive mode.
class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  // Telemetry States
  double _steering = 0.0;
  double _steeringAngleDeg = 0.0;
  double _gas = 0.0;
  double _brake = 0.0;
  bool _isHandbrakeActive = false;
  final Set<int> _activeButtons = <int>{};
  int _sequenceNumber = 0;

  // Selected Gear State
  int _currentGearIndex = 1; // 0=R, 1=N, 2=1, 3=2, 4=3, 5=4, 6=5, 7=6
  static const List<String> _gears = ['R', 'N', '1', '2', '3', '4', '5', '6'];

  // Active Steering Asset Option
  final String _selectedWheelAsset = 'assets/images/steering_wheel_cropped.png';

  @override
  void initState() {
    super.initState();
    _lockLandscapeAndImmersive();
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

  void _toggleButton(int buttonId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_activeButtons.contains(buttonId)) {
        _activeButtons.remove(buttonId);
      } else {
        _activeButtons.add(buttonId);
      }
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

  void _shiftUp() {
    if (_currentGearIndex < _gears.length - 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentGearIndex++;
      });
    }
  }

  void _shiftDown() {
    if (_currentGearIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentGearIndex--;
      });
    }
  }

  ControlPacket _buildCurrentPacket() {
    _sequenceNumber++;
    return ControlPacket(
      mode: 'guiWheel',
      steering: _steering,
      gas: _gas,
      brake: _brake,
      buttons: _activeButtons.toList()..sort(),
      seq: _sequenceNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPacket = _buildCurrentPacket();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1017),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Column(
            children: [
              // 1. Top Header Bar (Wireframe Aligned)
              _buildTopHeader(),

              const SizedBox(height: 6),

              // 2. Cockpit Main Body
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: Realistic Steering Wheel
                    _buildSteeringModule(),

                    const SizedBox(width: 12),

                    // Center Column: Gear Shifter, Accessory Buttons & HUD
                    Expanded(
                      flex: 4,
                      child: _buildCenterModule(currentPacket),
                    ),

                    const SizedBox(width: 12),

                    // Right Column: Handbrake Lever & Gas / Brake Pedals
                    _buildRightPedalsModule(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Header Bar matching wireframe: Camera / View controls, Mode Pill, Connection Status & Settings.
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF232A3B), width: 1),
      ),
      child: Row(
        children: [
          // Left Quick Action Buttons
          _buildHeaderPillButton('MODE', Icons.tune, () {}),
          const SizedBox(width: 6),
          _buildHeaderPillButton('VIEW', Icons.remove_red_eye_outlined, () {}),
          const SizedBox(width: 6),
          _buildHeaderPillButton('CAMERA', Icons.videocam_outlined, () {}),

          const Spacer(),

          // Center Mode Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_car_rounded, size: 14, color: Color(0xFF00E5FF)),
                SizedBox(width: 6),
                Text(
                  'STEERING MODE',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Connection Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF00E676), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF00E676)),
                SizedBox(width: 5),
                Text(
                  'COCKPIT READY',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Settings Button
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings Screen (Master-Detail) will be configured in Issue #7.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF22293A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings_outlined, size: 18, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPillButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2433),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2D364A), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Left Column: Interactive Steering Wheel Widget using user's asset.
  Widget _buildSteeringModule() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2435), width: 1.5),
      ),
      child: Center(
        child: SteeringWheelWidget(
          assetPath: _selectedWheelAsset,
          size: 260.0,
          maxAngleDegrees: 90.0,
          autoSpringReturn: true,
          onAngleChanged: _onSteeringChanged,
          onRawDegreeChanged: _onSteeringDegreeChanged,
          onHornPressed: _onHornPressed,
          onHornReleased: _onHornReleased,
          showDegreeBadge: true,
        ),
      ),
    );
  }

  /// Center Column: Gear Shifter, Accessory Buttons & Live Telemetry HUD.
  Widget _buildCenterModule(ControlPacket packet) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2435), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Live Telemetry Readout Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0D14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1A2233), width: 1),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTelemetryField('STEER', '${packet.steering.toStringAsFixed(2)} (${_steeringAngleDeg.round()}°)'),
                  const SizedBox(width: 14),
                  _buildTelemetryField('GAS', '${(packet.gas * 100).toInt()}%'),
                  const SizedBox(width: 14),
                  _buildTelemetryField('BRAKE', '${(packet.brake * 100).toInt()}%'),
                  const SizedBox(width: 14),
                  _buildTelemetryField('BTNS', packet.buttons.isEmpty ? 'NONE' : packet.buttons.join(', ')),
                ],
              ),
            ),
          ),

          // Accessory Buttons Grid (Button Box)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAccessoryButton(3, Icons.lightbulb_outline, 'LIGHTS'),
                const SizedBox(width: 6),
                _buildAccessoryButton(4, Icons.arrow_back_rounded, 'TURN-L'),
                const SizedBox(width: 6),
                _buildAccessoryButton(5, Icons.arrow_forward_rounded, 'TURN-R'),
                const SizedBox(width: 6),
                _buildAccessoryButton(6, Icons.warning_amber_rounded, 'HAZARD'),
                const SizedBox(width: 6),
                _buildAccessoryButton(8, Icons.water_drop_outlined, 'WIPER'),
              ],
            ),
          ),

          // Sequential Gear Shifter Module
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F131D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF22293A), width: 1),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _shiftDown,
                    icon: const Icon(Icons.arrow_left, size: 28, color: Color(0xFF00E5FF)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2638),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 55,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141926),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _gears[_currentGearIndex],
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    onPressed: _shiftUp,
                    icon: const Icon(Icons.arrow_right, size: 28, color: Color(0xFF00E5FF)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2638),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryField(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAccessoryButton(int btnId, IconData icon, String label) {
    final isActive = _activeButtons.contains(btnId);

    return InkWell(
      onTap: () => _toggleButton(btnId),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : const Color(0xFF19202E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF00E5FF) : const Color(0xFF263045),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? const Color(0xFF00E5FF) : Colors.white60,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF00E5FF) : Colors.white60,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Right Column: Handbrake Lever & Vertical Pedals (Brake & Gas).
  Widget _buildRightPedalsModule() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2435), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handbrake Toggle
          _buildHandbrakeWidget(),

          const SizedBox(width: 8),

          // Brake Pedal
          _buildPedal(
            label: 'BRAKE',
            color: const Color(0xFFFF1744),
            value: _brake,
            assetName: 'pedal_rem.png',
            onChanged: (val) {
              setState(() {
                _brake = val;
              });
            },
          ),

          const SizedBox(width: 8),

          // Gas / Throttle Pedal
          _buildPedal(
            label: 'THROTTLE',
            color: const Color(0xFF00E676),
            value: _gas,
            assetName: 'pedal_gas.png',
            onChanged: (val) {
              setState(() {
                _gas = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHandbrakeWidget() {
    return InkWell(
      onTap: _toggleHandbrake,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 60,
        decoration: BoxDecoration(
          color: _isHandbrakeActive
              ? const Color(0xFFFF1744).withValues(alpha: 0.18)
              : const Color(0xFF161B27),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHandbrakeActive ? const Color(0xFFFF1744) : const Color(0xFF273145),
            width: _isHandbrakeActive ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pan_tool_alt_rounded,
              size: 26,
              color: _isHandbrakeActive ? const Color(0xFFFF1744) : Colors.white54,
            ),
            const SizedBox(height: 8),
            Text(
              'PARK',
              style: TextStyle(
                color: _isHandbrakeActive ? const Color(0xFFFF1744) : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _isHandbrakeActive ? 'ON' : 'OFF',
              style: TextStyle(
                color: _isHandbrakeActive ? const Color(0xFFFF1744) : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPedal({
    required String label,
    required Color color,
    required double value,
    required String assetName,
    required ValueChanged<double> onChanged,
  }) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final height = box.size.height;
        final rawRatio = 1.0 - (details.localPosition.dy / (height * 0.7));
        onChanged(rawRatio.clamp(0.0, 1.0));
      },
      onVerticalDragEnd: (_) {
        onChanged(0.0); // Auto-spring return on release
      },
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF161B27),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value > 0.05 ? color : const Color(0xFF273145),
            width: value > 0.05 ? 1.5 : 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Liquid Neon Fill Level
            FractionallySizedBox(
              heightFactor: value.clamp(0.0, 1.0),
              widthFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Content Column
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: value > 0.05 ? color : Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '${(value * 100).toInt()}%',
                    style: TextStyle(
                      color: value > 0.05 ? color : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
