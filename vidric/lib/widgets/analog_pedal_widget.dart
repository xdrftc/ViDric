import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Progressive Analog Pedal Widget using authentic metallic plate assets.
///
/// Supports:
/// - Gas Pedal (vertical plate via `pedal_gas_tight.png`).
/// - Brake Pedal (horizontal plate via `pedal_rem_tight.png`).
/// - Smooth vertical drag gesture mapping 0.0 to 1.0.
/// - Auto-spring return instantly dropping value to 0.0 upon finger release.
/// - Liquid neon level indicator and percentage readout.
class AnalogPedalWidget extends StatelessWidget {
  final String label;
  final String assetPath;
  final Color activeColor;
  final double value; // 0.0 to 1.0
  final double width;
  final double height;
  final ValueChanged<double> onChanged;

  const AnalogPedalWidget({
    super.key,
    required this.label,
    required this.assetPath,
    required this.activeColor,
    required this.value,
    required this.onChanged,
    this.width = 75.0,
    this.height = 140.0,
  });

  void _handleDrag(DragUpdateDetails details, BuildContext context) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final totalHeight = box.size.height;
    final localY = details.localPosition.dy;
    // Dragging upward increases pressure from 0.0 to 1.0
    final rawRatio = 1.0 - (localY / totalHeight);
    onChanged(rawRatio.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = value > 0.02;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragDown: (_) {
        HapticFeedback.selectionClick();
      },
      onVerticalDragUpdate: (details) => _handleDrag(details, context),
      onVerticalDragEnd: (_) {
        onChanged(0.0); // Auto-spring release
      },
      onVerticalDragCancel: () {
        onChanged(0.0);
      },
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF16202A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPressed ? activeColor : const Color(0xFF283647),
            width: isPressed ? 1.8 : 1.2,
          ),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Liquid Neon Fill Level Indicator (Rises from bottom)
            FractionallySizedBox(
              heightFactor: value.clamp(0.0, 1.0),
              widthFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            // Content Column
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Label Badge
                Text(
                  label,
                  style: TextStyle(
                    color: isPressed ? activeColor : const Color(0xFF8FA3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),

                // Center Pedal Plate Image Asset
                Expanded(
                  child: Center(
                    child: Transform.scale(
                      scale: 1.0 - (value * 0.08), // Subtle 3D depression compression effect
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.directions_car_filled_outlined,
                            size: 32,
                            color: activeColor.withValues(alpha: 0.5),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Bottom Percentage Readout
                Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    color: isPressed ? activeColor : const Color(0xFFB0C4D8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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

