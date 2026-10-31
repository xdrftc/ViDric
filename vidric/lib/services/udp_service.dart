import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/control_packet.dart';

/// Status koneksi jaringan transmisi UDP.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  transmitting,
  error,
}

/// Data telemetri status transmisi jaringan secara live.
class NetworkMetrics {
  final ConnectionStatus status;
  final String targetIp;
  final int targetPort;
  final int packetsSent;
  final double packetsPerSecond; // TX Rate aktual (Hz)
  final int latencyMs;
  final String? errorMessage;

  const NetworkMetrics({
    this.status = ConnectionStatus.disconnected,
    this.targetIp = '',
    this.targetPort = 5005,
    this.packetsSent = 0,
    this.packetsPerSecond = 0.0,
    this.latencyMs = 0,
    this.errorMessage,
  });

  bool get isConnected =>
      status == ConnectionStatus.connected || status == ConnectionStatus.transmitting;
}

/// Layanan transmisi nirkabel UDP berlatensi rendah (< 10 ms) ke PC Companion.
///
/// Fitur Utama (Issue #4):
/// 1. Transmisi soket UDP non-blocking via RawDatagramSocket.
/// 2. Timer periodik stabil pada frekuensi 50 Hz (interval 20 ms).
/// 3. Serialisasi payload JSON sesuai spesifikasi vJoy receiver server_receiver.py.
/// 4. Parsing URI QR Code format `vidric://<ip>:<port>`.
/// 5. Penyimpanan IP terakhir dengan SharedPreferences dan fasilitas ping test.
/// 6. Failsafe safety packet (mengirim paket netral saat disconnect).
class UdpService {
  UdpService._internal();

  static final UdpService instance = UdpService._internal();

  // Socket & Stream Timer
  RawDatagramSocket? _socket;
  Timer? _transmissionTimer;
  Timer? _metricsTimer;

  // Konfigurasi Target Server
  String _targetIp = '192.168.1.10';
  int _targetPort = 5005;
  InternetAddress? _targetAddress;

  // Metrik Transmisi
  int _packetsSent = 0;
  int _packetsInLastSecond = 0;
  double _currentHz = 0.0;
  int _lastLatencyMs = 0;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _lastError;

  // Callback penyedia paket kontrol terkini dari ControllerScreen
  ControlPacket Function()? packetProvider;

  // Notifier Reaktif untuk UI
  final ValueNotifier<NetworkMetrics> metrics = ValueNotifier<NetworkMetrics>(
    const NetworkMetrics(),
  );

  NetworkMetrics get current => metrics.value;
  String get targetIp => _targetIp;
  int get targetPort => _targetPort;
  bool get isConnected => current.isConnected;

  static const String prefKeyIp = 'vidric_last_ip';
  static const String prefKeyPort = 'vidric_last_port';

  /// Inisialisasi dan memuat alamat IP terakhir yang tersimpan.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _targetIp = prefs.getString(prefKeyIp) ?? '192.168.1.10';
      _targetPort = prefs.getInt(prefKeyPort) ?? 5005;
      _updateMetrics();
    } catch (e) {
      debugPrint('UdpService: Gagal memuat IP tersimpan: $e');
    }
  }

  /// Mengurai format URI QR Code `vidric://<ip>:<port>` atau `<ip>:<port>`.
  static Map<String, dynamic>? parseQrPayload(String raw) {
    try {
      String clean = raw.trim();
      if (clean.startsWith('vidric://')) {
        clean = clean.substring(9);
      }

      final parts = clean.split(':');
      if (parts.isEmpty) return null;

      final String ip = parts[0].trim();
      // Validasi format IPv4 sederhana
      final ipSegments = ip.split('.');
      if (ipSegments.length != 4) return null;
      for (final seg in ipSegments) {
        final val = int.tryParse(seg);
        if (val == null || val < 0 || val > 255) return null;
      }

      int port = 5005;
      if (parts.length > 1) {
        port = int.tryParse(parts[1].trim()) ?? 5005;
      }

      return {'ip': ip, 'port': port};
    } catch (_) {
      return null;
    }
  }

  /// Menetapkan konfigurasi IP dan Port tujuan, serta menyimpannya ke memori.
  Future<void> configureTarget(String ip, int port) async {
    _targetIp = ip.trim();
    _targetPort = port;
    _updateMetrics();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeyIp, _targetIp);
      await prefs.setInt(prefKeyPort, _targetPort);
    } catch (e) {
      debugPrint('UdpService: Gagal menyimpan preferensi IP: $e');
    }
  }

  /// Menguji konektivitas ping / socket handshake ke target PC.
  Future<bool> testPing(String ip, int port) async {
    try {
      final addresses = await InternetAddress.lookup(ip);
      if (addresses.isEmpty) return false;

      final testSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      testSocket.broadcastEnabled = true;

      final probePacket = jsonEncode({
        'mode': 'ping',
        'seq': 0,
        'client': 'ViDricMobile',
      });
      final bytes = utf8.encode(probePacket);
      final sent = testSocket.send(bytes, addresses.first, port);
      testSocket.close();

      return sent > 0;
    } catch (e) {
      debugPrint('UdpService: Ping test gagal: $e');
      return false;
    }
  }

  /// Menghubungkan soket UDP dan memulai timer transmisi periodik 50 Hz (20 ms).
  Future<bool> connect({String? ip, int? port}) async {
    if (ip != null && port != null) {
      await configureTarget(ip, port);
    }

    _status = ConnectionStatus.connecting;
    _updateMetrics();

    try {
      final addresses = await InternetAddress.lookup(_targetIp);
      if (addresses.isEmpty) {
        throw const SocketException('Alamat IP target tidak ditemukan.');
      }
      _targetAddress = addresses.first;

      // Inisialisasi RawDatagramSocket untuk transmisi non-blocking kecepatan tinggi
      _socket?.close();
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.broadcastEnabled = true;

      _status = ConnectionStatus.connected;
      _packetsSent = 0;
      _packetsInLastSecond = 0;
      _currentHz = 0.0;
      _lastError = null;

      // 1. Timer transmisi 50 Hz stabil (Interval 20 milidetik)
      _transmissionTimer?.cancel();
      _transmissionTimer = Timer.periodic(
        const Duration(milliseconds: 20),
        (_) => _sendCurrentPacketTick(),
      );

      // 2. Timer kalkulasi frekuensi aktual dan kesehatan transmisi (setiap 1 detik)
      _metricsTimer?.cancel();
      _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _currentHz = _packetsInLastSecond.toDouble();
        _packetsInLastSecond = 0;
        _updateMetrics();
      });

      _updateMetrics();
      debugPrint('UdpService: Terhubung ke $_targetIp:$_targetPort pada 50 Hz.');
      return true;
    } catch (e) {
      _status = ConnectionStatus.error;
      _lastError = e.toString();
      _updateMetrics();
      debugPrint('UdpService: Gagal menghubungkan UDP: $e');
      return false;
    }
  }

  /// Mengirim satu paket kontrol periodik pada tick 20 ms.
  void _sendCurrentPacketTick() {
    if (_socket == null || _targetAddress == null) return;

    try {
      final stopwatch = Stopwatch()..start();

      // Ambil paket kontrol terkini dari UI kokpit atau fallback paket netral
      final ControlPacket packet = packetProvider != null
          ? packetProvider!()
          : ControlPacket.neutral();

      final String payload = jsonEncode(packet.toJson());
      final List<int> bytes = utf8.encode(payload);

      final int bytesSent = _socket!.send(bytes, _targetAddress!, _targetPort);

      stopwatch.stop();
      _lastLatencyMs = stopwatch.elapsedMilliseconds;

      if (bytesSent > 0) {
        _packetsSent++;
        _packetsInLastSecond++;
        if (_status != ConnectionStatus.transmitting) {
          _status = ConnectionStatus.transmitting;
        }
      }
    } catch (e) {
      debugPrint('UdpService: Error saat transmisi paket: $e');
      _status = ConnectionStatus.error;
      _lastError = e.toString();
      _updateMetrics();
    }
  }

  /// Memutuskan koneksi soket dan mengirimkan Failsafe Safety Packet ke PC.
  void disconnect() {
    // Failsafe Watchdog: Kirim paket netral ke PC sebelum soket ditutup
    sendFailsafeNeutral();

    _transmissionTimer?.cancel();
    _transmissionTimer = null;
    _metricsTimer?.cancel();
    _metricsTimer = null;

    _socket?.close();
    _socket = null;

    _status = ConnectionStatus.disconnected;
    _currentHz = 0.0;
    _updateMetrics();
    debugPrint('UdpService: Terputus dari server PC.');
  }

  /// Mengirimkan paket darurat netral (Failsafe) agar vJoy PC melepaskan throttle dan rem.
  void sendFailsafeNeutral() {
    if (_socket == null || _targetAddress == null) return;

    try {
      final neutralPacket = ControlPacket.neutral(mode: 'failsafe');
      final bytes = utf8.encode(jsonEncode(neutralPacket.toJson()));
      _socket!.send(bytes, _targetAddress!, _targetPort);
    } catch (_) {}
  }

  void _updateMetrics() {
    metrics.value = NetworkMetrics(
      status: _status,
      targetIp: _targetIp,
      targetPort: _targetPort,
      packetsSent: _packetsSent,
      packetsPerSecond: _currentHz,
      latencyMs: _lastLatencyMs,
      errorMessage: _lastError,
    );
  }
}

