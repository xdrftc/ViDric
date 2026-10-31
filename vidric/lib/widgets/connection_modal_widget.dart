import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/udp_service.dart';
import 'qr_scanner_dialog.dart';

/// Modal dialog pengaturan koneksi Wi-Fi UDP ke PC Companion.
class ConnectionModalWidget extends StatefulWidget {
  const ConnectionModalWidget({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ConnectionModalWidget(),
    );
  }

  @override
  State<ConnectionModalWidget> createState() => _ConnectionModalWidgetState();
}

class _ConnectionModalWidgetState extends State<ConnectionModalWidget> {
  final UdpService _udpService = UdpService.instance;
  late TextEditingController _ipController;
  late TextEditingController _portController;

  bool _isTestingPing = false;
  String? _pingResult;
  bool _pingSuccess = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: _udpService.targetIp);
    _portController = TextEditingController(text: _udpService.targetPort.toString());
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F1720),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF223547), width: 1.2),
      ),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(20),
        child: ValueListenableBuilder<NetworkMetrics>(
          valueListenable: _udpService.metrics,
          builder: (context, metrics, _) {
            final isConnected = metrics.isConnected;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
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
                    const Expanded(
                      child: Text(
                        'KONEKSI PC COMPANION (WI-FI UDP)',
                        style: TextStyle(
                          color: Color(0xFFE0E6ED),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFF8B9FB3), size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Form Alamat IP & Port
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

                // Baris Tombol Ping & Status
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

                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFF1E2C3A)),
                const SizedBox(height: 14),

                // Kartu Metrik Transmisi Live (50 Hz, Latensi, Paket)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141E28),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF223547)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol(
                          'STATUS KONEKSI',
                          metrics.status.name.toUpperCase(),
                          isConnected ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                        ),
                        const SizedBox(width: 16),
                        _buildMetricCol(
                          'TX RATE (HZ)',
                          '${metrics.packetsPerSecond.toStringAsFixed(1)} Hz',
                          const Color(0xFF00E5FF),
                        ),
                        const SizedBox(width: 16),
                        _buildMetricCol(
                          'PAKET TERKIRIM',
                          metrics.packetsSent.toString(),
                          const Color(0xFFE0E6ED),
                        ),
                        const SizedBox(width: 16),
                        _buildMetricCol(
                          'LATENSI SOKET',
                          '${metrics.latencyMs} ms',
                          const Color(0xFF00E676),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tombol Aksi Utama (Connect / Disconnect)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('TUTUP', style: TextStyle(color: Color(0xFF8B9FB3), fontSize: 11)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _toggleConnection,
                        icon: Icon(
                          isConnected ? Icons.link_off : Icons.link,
                          size: 16,
                          color: isConnected ? Colors.white : const Color(0xFF0E141B),
                        ),
                        label: Text(
                          isConnected ? 'PUTUSKAN KONEKSI' : 'HUBUNGKAN KE PC (50 HZ)',
                          style: TextStyle(
                            color: isConnected ? Colors.white : const Color(0xFF0E141B),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConnected ? const Color(0xFFB71C1C) : const Color(0xFF00E5FF),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF7E93A8), fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
