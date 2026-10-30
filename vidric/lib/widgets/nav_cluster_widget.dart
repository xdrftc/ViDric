import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation & Quick Action Cluster Widget matching the Cockpit wireframe.
///
/// Layout:
/// Row 1: [ < ] [ ENTER ] [ > ]
/// Row 2: [ 1 ]   [ 2 ]   [ 3 ]
class NavClusterWidget extends StatelessWidget {
  final VoidCallback? onLeftPressed;
  final VoidCallback? onEnterPressed;
  final VoidCallback? onRightPressed;
  final VoidCallback? onBtn1Pressed;
  final VoidCallback? onBtn2Pressed;
  final VoidCallback? onBtn3Pressed;
  final double buttonWidth;
  final double buttonHeight;

  const NavClusterWidget({
    super.key,
    this.onLeftPressed,
    this.onEnterPressed,
    this.onRightPressed,
    this.onBtn1Pressed,
    this.onBtn2Pressed,
    this.onBtn3Pressed,
    this.buttonWidth = 48.0,
    this.buttonHeight = 36.0,
  });

  Widget _buildKeyButton({
    required Widget child,
    required VoidCallback? onTap,
    double? width,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width ?? buttonWidth,
        height: buttonHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF222D39),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334253), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: [ < ] [ ENTER ] [ > ]
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildKeyButton(
              onTap: onLeftPressed,
              child: const Icon(Icons.arrow_left_rounded, size: 24, color: Color(0xFFD4E0EC)),
            ),
            const SizedBox(width: 8),
            _buildKeyButton(
              width: buttonWidth * 1.35,
              onTap: onEnterPressed,
              child: const Text(
                'ENTER',
                style: TextStyle(
                  color: Color(0xFFD4E0EC),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildKeyButton(
              onTap: onRightPressed,
              child: const Icon(Icons.arrow_right_rounded, size: 24, color: Color(0xFFD4E0EC)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 2: [ 1 ] [ 2 ] [ 3 ]
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildKeyButton(
              onTap: onBtn1Pressed,
              child: const Text(
                '1',
                style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            _buildKeyButton(
              width: buttonWidth * 1.35,
              onTap: onBtn2Pressed,
              child: const Text(
                '2',
                style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            _buildKeyButton(
              onTap: onBtn3Pressed,
              child: const Text(
                '3',
                style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

