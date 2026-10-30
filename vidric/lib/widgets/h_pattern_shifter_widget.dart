import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive Manual H-Pattern Shifter Widget.
///
/// Features:
/// - Uses authentic `persneling_tight.png` gate asset with cyan glow numbers 1 3 5 / 2 4 6.
/// - Smooth animated shift knob moving between slots (1, 2, 3, 4, 5, 6, N, R).
/// - Discrete vJoy button triggering (Gears 1-6 = Buttons 12-17, R = Button 18).
/// - Haptic notch-lock feedback upon gear engagement.
class HPatternShifterWidget extends StatefulWidget {
  final String activeGear; // 'N', '1', '2', '3', '4', '5', '6', 'R'
  final void Function(String gear, int? vjoyButton) onGearChanged;
  final double width;
  final double height;

  const HPatternShifterWidget({
    super.key,
    required this.activeGear,
    required this.onGearChanged,
    this.width = 110.0,
    this.height = 145.0,
  });

  @override
  State<HPatternShifterWidget> createState() => _HPatternShifterWidgetState();
}

class _HPatternShifterWidgetState extends State<HPatternShifterWidget> {
  // vJoy button mappings:
  // 1 -> Btn 12, 2 -> Btn 13, 3 -> Btn 14, 4 -> Btn 15, 5 -> Btn 16, 6 -> Btn 17, R -> Btn 18
  static const Map<String, int> _gearVJoyMap = {
    '1': 12,
    '2': 13,
    '3': 14,
    '4': 15,
    '5': 16,
    '6': 17,
    'R': 18,
  };

  Alignment _getKnobAlignment(String gear) {
    switch (gear) {
      case '1':
        return const Alignment(-0.62, -0.68);
      case '2':
        return const Alignment(-0.62, 0.68);
      case '3':
        return const Alignment(0.0, -0.68);
      case '4':
        return const Alignment(0.0, 0.68);
      case '5':
        return const Alignment(0.62, -0.68);
      case '6':
        return const Alignment(0.62, 0.68);
      case 'R':
        return const Alignment(-0.95, -0.68);
      case 'N':
      default:
        return const Alignment(0.0, 0.0);
    }
  }

  void _selectGear(String gear) {
    if (widget.activeGear != gear) {
      HapticFeedback.mediumImpact();
      final vjoyBtn = _gearVJoyMap[gear];
      widget.onGearChanged(gear, vjoyBtn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final knobAlignment = _getKnobAlignment(widget.activeGear);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF141C24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF283647), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Gate Image Asset
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/persneling_tight.png',
              width: widget.width,
              height: widget.height,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackGate();
              },
            ),
          ),

          // Tap Target Overlay Matrix for slots
          _buildTapSlots(),

          // Animated Shift Knob with Smooth Notch Physics
          AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            alignment: knobAlignment,
            child: GestureDetector(
              onTap: () {
                // Tapping active knob toggles back to Neutral (N)
                if (widget.activeGear != 'N') {
                  _selectGear('N');
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E2834),
                  border: Border.all(
                    color: widget.activeGear != 'N'
                        ? const Color(0xFF00E5FF)
                        : Colors.white60,
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.activeGear != 'N'
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
                          : Colors.black54,
                      blurRadius: widget.activeGear != 'N' ? 10 : 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.activeGear,
                    style: TextStyle(
                      color: widget.activeGear != 'N'
                          ? const Color(0xFF00E5FF)
                          : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Neutral Line Tap Target (Center bar)
          Positioned(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _selectGear('N'),
              child: const SizedBox(
                width: 60,
                height: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapSlots() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Row Slots: [1] [3] [5]
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 6, right: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSlotTarget('1'),
                const SizedBox(width: 4),
                _buildSlotTarget('3'),
                const SizedBox(width: 4),
                _buildSlotTarget('5'),
              ],
            ),
          ),
        ),

        // Bottom Row Slots: [2] [4] [6]
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 6, right: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSlotTarget('2'),
                const SizedBox(width: 4),
                _buildSlotTarget('4'),
                const SizedBox(width: 4),
                _buildSlotTarget('6'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotTarget(String gear) {
    final isActive = widget.activeGear == gear;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectGear(gear),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        child: Text(
          gear,
          style: TextStyle(
            color: isActive ? const Color(0xFF00E5FF) : Colors.transparent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackGate() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF17202B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _FallbackHGatePainter(),
      ),
    );
  }
}

class _FallbackHGatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C3C4E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final dx = size.width * 0.32;
    final dy = size.height * 0.35;

    // Center horizontal neutral bar
    canvas.drawLine(Offset(cx - dx, cy), Offset(cx + dx, cy), paint);

    // Vertical channels
    canvas.drawLine(Offset(cx - dx, cy - dy), Offset(cx - dx, cy + dy), paint);
    canvas.drawLine(Offset(cx, cy - dy), Offset(cx, cy + dy), paint);
    canvas.drawLine(Offset(cx + dx, cy - dy), Offset(cx + dx, cy + dy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

