import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Komponen busur visual instrumen cakrawala buatan (Artificial Horizon Gauge).
///
/// Menampilkan derajat kemiringan rotasi smartphone secara live, dilengkapi:
/// - Garis cakrawala buatan (Horizon Line) yang berputar dinamis mengikuti kemiringan ponsel.
/// - Busur derajat kemudi (Arc Degree Scale) dengan garis skala -45° s/d +45° (atau sesuai batas sudut).
/// - Titik retikel tengah (Center Reticle Pip).
/// - Badge digital pembacaan derajat numerik (misal: 0.0° CENTER, 18.2° LEFT, 24.5° RIGHT).
/// - Warna otomotif adaptif (Cyan di area tengah, Amber di belokan tajam, Merah di batas sudut).
class ArtificialHorizonGaugeWidget extends StatelessWidget {
  final double angleDeg;
  final double maxAngleDeg;
  final double pitchDeg;
  final bool isCalibrated;
  final double size;

  const ArtificialHorizonGaugeWidget({
    super.key,
    required this.angleDeg,
    this.maxAngleDeg = 45.0,
    this.pitchDeg = 0.0,
    this.isCalibrated = true,
    this.size = 180.0,
  });

  Color _getTelemetryColor(double absAngle) {
    if (absAngle < 2.0) {
      return const Color(0xFF00E676); // Neon Green saat netral lurus
    } else if (absAngle < maxAngleDeg * 0.6) {
      return const Color(0xFF00E5FF); // Cyan saat belok normal
    } else if (absAngle < maxAngleDeg * 0.9) {
      return const Color(0xFFFFB300); // Amber saat belok tajam
    } else {
      return const Color(0xFFFF1744); // Red saat mencapai lock sudut
    }
  }

  String _getDirectionLabel(double angle) {
    if (angle.abs() < 1.0) {
      return 'CENTER';
    } else if (angle < 0) {
      return 'LEFT';
    } else {
      return 'RIGHT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double absAngle = angleDeg.abs();
    final Color activeColor = _getTelemetryColor(absAngle);
    final String direction = _getDirectionLabel(angleDeg);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Cincin & Busur Derajat
          CustomPaint(
            size: Size(size, size),
            painter: _HorizonGaugePainter(
              angleDeg: angleDeg,
              maxAngleDeg: maxAngleDeg,
              pitchDeg: pitchDeg,
              activeColor: activeColor,
            ),
          ),

          // Badge Derajat Numerik di Tengah
          Positioned(
            bottom: size * 0.16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF131D27).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${angleDeg.abs().toStringAsFixed(1)}°',
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    direction,
                    style: TextStyle(
                      color: activeColor.withValues(alpha: 0.8),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Label Status Sensor & Kalibrasi
          Positioned(
            top: size * 0.14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCalibrated ? const Color(0xFF00E676) : const Color(0xFFFFB300),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isCalibrated ? 'TILT HORIZON : ACTIVE' : 'UNCALIBRATED',
                  style: const TextStyle(
                    color: Color(0xFF8B9FB3),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter untuk menggambar busur instrumen dan garis horizon yang berputar.
class _HorizonGaugePainter extends CustomPainter {
  final double angleDeg;
  final double maxAngleDeg;
  final double pitchDeg;
  final Color activeColor;

  _HorizonGaugePainter({
    required this.angleDeg,
    required this.maxAngleDeg,
    required this.pitchDeg,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width * 0.42;

    // 1. Gambar Cincin Luar & Busur Skala
    final Paint ringPaint = Paint()
      ..color = const Color(0xFF1E2B38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, ringPaint);

    // 2. Gambar Busur Derajat (-60° s/d +60°)
    final Paint tickPaint = Paint()
      ..color = const Color(0xFF486178)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final Paint majorTickPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final List<double> ticks = [-60, -45, -30, -15, 0, 15, 30, 45, 60];

    for (final deg in ticks) {
      if (deg.abs() > maxAngleDeg + 15) continue;

      // Sudut 0 berada di puncak atas (-PI / 2)
      final double rad = (deg - 90.0) * (math.pi / 180.0);
      final bool isMajor = deg == 0 || deg.abs() == maxAngleDeg;
      final double innerR = radius - (isMajor ? 8.0 : 4.0);
      final double outerR = radius;

      final Offset p1 = Offset(center.dx + innerR * math.cos(rad), center.dy + innerR * math.sin(rad));
      final Offset p2 = Offset(center.dx + outerR * math.cos(rad), center.dy + outerR * math.sin(rad));

      canvas.drawLine(p1, p2, isMajor ? majorTickPaint : tickPaint);
    }

    // 3. Simpan canvas dan lakukan rotasi garis horizon sesuai kemiringan ponsel
    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Rotasi mengikuti sudut kemiringan (dalam radian)
    final double rollRad = angleDeg * (math.pi / 180.0);
    canvas.rotate(-rollRad); // Berputar berlawanan untuk menjaga horizon relatif horizontal

    // 4. Gambar Garis Horizon Utama (Artificial Horizon Line)
    final Paint horizonPaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final double barWidth = radius * 0.75;
    // Garis kiri
    canvas.drawLine(Offset(-barWidth, 0), const Offset(-14, 0), horizonPaint);
    // Garis kanan
    canvas.drawLine(const Offset(14, 0), Offset(barWidth, 0), horizonPaint);

    // Titik retikel tengah (Pip Crosshair)
    final Paint reticlePaint = Paint()
      ..color = const Color(0xFFE0E6ED)
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset.zero, 3.0, reticlePaint);
    canvas.drawLine(const Offset(0, -6), const Offset(0, 6), reticlePaint);

    // Kembalikan canvas
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HorizonGaugePainter oldDelegate) {
    return oldDelegate.angleDeg != angleDeg ||
        oldDelegate.maxAngleDeg != maxAngleDeg ||
        oldDelegate.pitchDeg != pitchDeg ||
        oldDelegate.activeColor != activeColor;
  }
}

