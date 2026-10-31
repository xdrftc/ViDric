import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget Transmisi Sekuensial (*Sequential Shifter Widget*).
///
/// Fitur:
/// - Tombol naik gigi (▲ Upshift / +) yang memicu pulsa vJoy Button 10.
/// - Tombol turun gigi (▼ Downshift / -) yang memicu pulsa vJoy Button 11.
/// - Tampilan indikator digital LED untuk posisi gigi aktif: R, N, 1, 2, 3, 4, 5, 6.
/// - Animasi pendar neon dan umpan balik getaran haptik *notch* saat pergantian gigi.
class SequentialShifterWidget extends StatefulWidget {
  final String activeGear; // 'R', 'N', '1', '2', '3', '4', '5', '6'
  final void Function(String newGear, int pulseVjoyButton) onShift;
  final double width;
  final double height;

  const SequentialShifterWidget({
    super.key,
    required this.activeGear,
    required this.onShift,
    this.width = 105.0,
    this.height = 130.0,
  });

  @override
  State<SequentialShifterWidget> createState() => _SequentialShifterWidgetState();
}

class _SequentialShifterWidgetState extends State<SequentialShifterWidget> {
  static const List<String> _gearSequence = ['R', 'N', '1', '2', '3', '4', '5', '6'];

  bool _isUpshiftPressed = false;
  bool _isDownshiftPressed = false;
  Timer? _pulseTimer;

  @override
  void dispose() {
    _pulseTimer?.cancel();
    super.dispose();
  }

  void _upshift() {
    final currentIndex = _gearSequence.indexOf(widget.activeGear);
    if (currentIndex < _gearSequence.length - 1) {
      final nextGear = _gearSequence[currentIndex + 1];
      _triggerShift(nextGear, 10, isUpshift: true);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _downshift() {
    final currentIndex = _gearSequence.indexOf(widget.activeGear);
    if (currentIndex > 0) {
      final prevGear = _gearSequence[currentIndex - 1];
      _triggerShift(prevGear, 11, isUpshift: false);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _triggerShift(String targetGear, int vjoyPulseBtn, {required bool isUpshift}) {
    HapticFeedback.heavyImpact();
    setState(() {
      if (isUpshift) {
        _isUpshiftPressed = true;
      } else {
        _isDownshiftPressed = true;
      }
    });

    widget.onShift(targetGear, vjoyPulseBtn);

    _pulseTimer?.cancel();
    _pulseTimer = Timer(const Duration(milliseconds: 140), () {
      if (mounted) {
        setState(() {
          _isUpshiftPressed = false;
          _isDownshiftPressed = false;
        });
      }
    });
  }

  Color _getGearColor(String gear) {
    switch (gear) {
      case 'R':
        return const Color(0xFFFF1744); // Crimson Red
      case 'N':
        return const Color(0xFF00E676); // Emerald Green
      default:
        return const Color(0xFF00E5FF); // Neon Cyan
    }
  }

  @override
  Widget build(BuildContext context) {
    final gearColor = _getGearColor(widget.activeGear);

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
      child: Column(
        children: [
          // 1. Tombol UPSHIFT (+)
          Expanded(
            flex: 4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _upshift,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  decoration: BoxDecoration(
                    color: _isUpshiftPressed
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                        : const Color(0xFF18232E),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border(
                      bottom: BorderSide(
                        color: _isUpshiftPressed ? const Color(0xFF00E5FF) : const Color(0xFF283647),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                            color: _isUpshiftPressed ? const Color(0xFF00E5FF) : const Color(0xFF8FA3B8),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'SHIFT UP',
                            style: TextStyle(
                              color: _isUpshiftPressed ? const Color(0xFF00E5FF) : const Color(0xFFD4E0EC),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Layar Indikator Gigi Digital (Digital HUD)
          Expanded(
            flex: 5,
            child: Container(
              color: const Color(0xFF0D141C),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.activeGear,
                        style: TextStyle(
                          color: gearColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 1.0,
                          shadows: [
                            Shadow(
                              color: gearColor.withValues(alpha: 0.7),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'SEQUENTIAL',
                        style: TextStyle(
                          color: Color(0xFF5A7084),
                          fontSize: 7.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Tombol DOWNSHIFT (-)
          Expanded(
            flex: 4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _downshift,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  decoration: BoxDecoration(
                    color: _isDownshiftPressed
                        ? const Color(0xFFFF1744).withValues(alpha: 0.25)
                        : const Color(0xFF18232E),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    border: Border(
                      top: BorderSide(
                        color: _isDownshiftPressed ? const Color(0xFFFF1744) : const Color(0xFF283647),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: _isDownshiftPressed ? const Color(0xFFFF1744) : const Color(0xFF8FA3B8),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'SHIFT DOWN',
                            style: TextStyle(
                              color: _isDownshiftPressed ? const Color(0xFFFF1744) : const Color(0xFFD4E0EC),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
