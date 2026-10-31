import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/udp_service.dart';

/// Dialog pemindai QR Code untuk auto-connect alamat IP dan Port PC Companion.
class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({super.key});

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  late MobileScannerController _cameraController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        final parsed = UdpService.parseQrPayload(rawValue);
        if (parsed != null) {
          _isProcessing = true;
          Navigator.of(context).pop(parsed);
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF101720),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
      ),
      child: Container(
        width: 480,
        height: 320,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Color(0xFF00E5FF), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'PINDAI QR CODE PC COMPANION',
                  style: TextStyle(
                    color: Color(0xFFE0E6ED),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF8B9FB3), size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Arahkan kamera ke QR Code yang ditampilkan pada ViDric PC Companion.',
              style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 10.5),
            ),
            const SizedBox(height: 12),

            // Area Kamera Pemindai
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _cameraController,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) {
                        return Container(
                          color: const Color(0xFF16202C),
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.videocam_off, color: Color(0xFFFFB300), size: 32),
                                const SizedBox(height: 8),
                                const Text(
                                  'Kamera Tidak Tersedia',
                                  style: TextStyle(color: Color(0xFFE0E6ED), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  error.errorDetails?.message ?? 'Gunakan input manual alamat IP.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFF7E93A8), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Kotak Bidik Target (Aim Reticle)
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF00E5FF), width: 2.0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            // Tombol Tutup / Batal
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'BATAL & INPUT MANUAL',
                  style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

