import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive Realistic Steering Wheel Widget.
///
/// Features:
/// - Hardware-accelerated GPU matrix rotation via [Transform.rotate].
/// - Circular rotational drag tracking with trigonometry (atan2).
/// - Damped spring-return physics animating back to 0.0 center upon finger release.
/// - Live steering degree badge readout.
/// - Interactive center horn (klakson) button with haptic feedback.
class SteeringWheelWidget extends StatefulWidget {
  /// Asset image path for the steering wheel graphic.
  final String assetPath;

  /// Diameter/size of the steering wheel widget.
  final double size;

  /// Maximum one-way rotation lock in degrees (e.g. 90.0 for +/- 90 degrees).
  final double maxAngleDegrees;

  /// Whether the wheel automatically springs back to center when released.
  final bool autoSpringReturn;

  /// Duration of the spring-return animation.
  final Duration springDuration;

  /// Callback delivering normalized steering value between -1.0 (Left) and +1.0 (Right).
  final ValueChanged<double>? onAngleChanged;

  /// Callback delivering raw angle in degrees.
  final ValueChanged<double>? onRawDegreeChanged;

  /// Callback when center horn is pressed.
  final VoidCallback? onHornPressed;

  /// Callback when center horn is released.
  final VoidCallback? onHornReleased;

  /// Whether to show the top degree readout badge.
  final bool showDegreeBadge;

  const SteeringWheelWidget({
    super.key,
    this.assetPath = 'assets/images/steering_wheel_cropped.png',
    this.size = 280.0,
    this.maxAngleDegrees = 90.0,
    this.autoSpringReturn = true,
    this.springDuration = const Duration(milliseconds: 350),
    this.onAngleChanged,
    this.onRawDegreeChanged,
    this.onHornPressed,
    this.onHornReleased,
    this.showDegreeBadge = true,
  });

  @override
  State<SteeringWheelWidget> createState() => _SteeringWheelWidgetState();
}

class _SteeringWheelWidgetState extends State<SteeringWheelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  Animation<double>? _springAnimation;

  double _currentAngleRad = 0.0;
  double _lastTouchAngle = 0.0;
  bool _isDragging = false;
  bool _isHornPressed = false;

  double get _maxAngleRad => widget.maxAngleDegrees * (math.pi / 180.0);
  double get _currentAngleDegrees => _currentAngleRad * (180.0 / math.pi);
  double get _normalizedSteering =>
      (_currentAngleDegrees / widget.maxAngleDegrees).clamp(-1.0, 1.0);

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: widget.springDuration,
    )..addListener(_onSpringAnimationUpdate);
  }

  @override
  void dispose() {
    _springController.removeListener(_onSpringAnimationUpdate);
    _springController.dispose();
    super.dispose();
  }

  void _onSpringAnimationUpdate() {
    if (_springAnimation != null) {
      setState(() {
        _currentAngleRad = _springAnimation!.value;
      });
      _notifyAngleChanged();
    }
  }

  void _notifyAngleChanged() {
    final normalized = _normalizedSteering;
    final degrees = _currentAngleDegrees;
    widget.onAngleChanged?.call(normalized);
    widget.onRawDegreeChanged?.call(degrees);
  }

  void _onPanStart(DragStartDetails details, Offset center) {
    if (_springController.isAnimating) {
      _springController.stop();
    }
    setState(() {
      _isDragging = true;
    });

    final localPos = details.localPosition;
    _lastTouchAngle = math.atan2(
      localPos.dy - center.dy,
      localPos.dx - center.dx,
    );
  }

  void _onPanUpdate(DragUpdateDetails details, Offset center) {
    final localPos = details.localPosition;
    final currentTouchAngle = math.atan2(
      localPos.dy - center.dy,
      localPos.dx - center.dx,
    );

    double delta = currentTouchAngle - _lastTouchAngle;
    // Normalize delta across -pi to +pi boundary to avoid sudden 360-degree snap
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    setState(() {
      _currentAngleRad = (_currentAngleRad + delta).clamp(-_maxAngleRad, _maxAngleRad);
      _lastTouchAngle = currentTouchAngle;
    });

    _notifyAngleChanged();
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    if (widget.autoSpringReturn && _currentAngleRad != 0.0) {
      _startSpringReturn();
    }
  }

  void _onPanCancel() {
    setState(() {
      _isDragging = false;
    });
    if (widget.autoSpringReturn && _currentAngleRad != 0.0) {
      _startSpringReturn();
    }
  }

  void _startSpringReturn() {
    final startAngle = _currentAngleRad;
    _springAnimation = Tween<double>(
      begin: startAngle,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutCubic,
    ));

    _springController.forward(from: 0.0);
  }

  void _onHornTapDown(TapDownDetails details) {
    HapticFeedback.heavyImpact();
    setState(() {
      _isHornPressed = true;
    });
    widget.onHornPressed?.call();
  }

  void _onHornTapUp(TapUpDetails details) {
    setState(() {
      _isHornPressed = false;
    });
    widget.onHornReleased?.call();
  }

  void _onHornTapCancel() {
    setState(() {
      _isHornPressed = false;
    });
    widget.onHornReleased?.call();
  }

  /// Formats degree string for the top badge indicator.
  String _formatDegreeLabel() {
    final deg = _currentAngleDegrees.round();
    if (deg.abs() < 2) return '0° CENTER';
    if (deg < 0) return '${deg.abs()}° LEFT';
    return '${deg.abs()}° RIGHT';
  }

  Color _getDegreeBadgeColor() {
    final ratio = _normalizedSteering.abs();
    if (ratio < 0.1) return const Color(0xFF00E5FF); // Cyan neutral
    if (ratio < 0.7) return const Color(0xFFFFD600); // Amber warning
    return const Color(0xFFFF1744); // Red aggressive lock
  }

  @override
  Widget build(BuildContext context) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final hornRadius = widget.size * 0.18; // ~36% center horn diameter

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showDegreeBadge) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF141824).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getDegreeBadgeColor().withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getDegreeBadgeColor().withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.rotate_right,
                  size: 14,
                  color: _getDegreeBadgeColor(),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDegreeLabel(),
                  style: TextStyle(
                    color: _getDegreeBadgeColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Steering Wheel Interactive Container
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ambient glow ring
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      _getDegreeBadgeColor().withValues(alpha: _isDragging ? 0.20 : 0.08),
                    ],
                  ),
                ),
              ),

              // Rotational Gesture Layer
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => _onPanStart(d, center),
                onPanUpdate: (d) => _onPanUpdate(d, center),
                onPanEnd: _onPanEnd,
                onPanCancel: _onPanCancel,
                child: Transform.rotate(
                  angle: _currentAngleRad,
                  child: Image.asset(
                    widget.assetPath,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback circular wheel painter if asset path fails
                      return CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _FallbackWheelPainter(
                          angleRad: _currentAngleRad,
                          accentColor: _getDegreeBadgeColor(),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Top Alignment Marker (Center Strip)
              Transform.rotate(
                angle: _currentAngleRad,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 6,
                    height: 16,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1744),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFFF1744),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Center Hub Horn (Klakson Button)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _onHornTapDown,
                onTapUp: _onHornTapUp,
                onTapCancel: _onHornTapCancel,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: hornRadius * 2,
                  height: hornRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isHornPressed
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.25),
                    border: Border.all(
                      color: _isHornPressed
                          ? const Color(0xFF00E5FF)
                          : Colors.white.withValues(alpha: 0.2),
                      width: _isHornPressed ? 2.5 : 1.5,
                    ),
                    boxShadow: _isHornPressed
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: hornRadius * 0.9,
                      color: _isHornPressed
                          ? const Color(0xFF00E5FF)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
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

/// Fallback vector wheel painter used if raster asset is unavailable.
class _FallbackWheelPainter extends CustomPainter {
  final double angleRad;
  final Color accentColor;

  _FallbackWheelPainter({required this.angleRad, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer rim
    final rimPaint = Paint()
      ..color = const Color(0xFF222634)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.18;
    canvas.drawCircle(center, radius * 0.88, rimPaint);

    // Inner rim accent
    final accentPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 0.96, accentPaint);

    // Spokes
    final spokePaint = Paint()
      ..color = const Color(0xFF333A4D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;

    // Left, Right, Bottom spokes
    canvas.drawLine(center, Offset(center.dx - radius * 0.8, center.dy), spokePaint);
    canvas.drawLine(center, Offset(center.dx + radius * 0.8, center.dy), spokePaint);
    canvas.drawLine(center, Offset(center.dx, center.dy + radius * 0.8), spokePaint);
  }

  @override
  bool shouldRepaint(covariant _FallbackWheelPainter oldDelegate) {
    return oldDelegate.angleRad != angleRad || oldDelegate.accentColor != accentColor;
  }
}
