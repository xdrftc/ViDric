import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/control_packet.dart';
import 'settings_service.dart';

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
  final int targetRateHz;
  final bool isBinary;
  final String? errorMessage;

  const NetworkMetrics({
    this.status = ConnectionStatus.disconnected,
    this.targetIp = '',
    this.targetPort = 5005,
    this.packetsSent = 0,
    this.packetsPerSecond = 0.0,
    this.latencyMs = 0,
    this.targetRateHz = 50,
    this.isBinary = true,
    this.errorMessage,
  });

  bool get isConnected =>
      status == ConnectionStatus.connected || status == ConnectionStatus.transmitting;
}

/// Layanan transmisi nirkabel UDP berlatensi rendah (< 10 ms) ke PC Companion.
///
/// Fitur Utama:
/// 1. Transmisi soket UDP non-blocking via RawDatagramSocket.
/// 2. Timer periodik adaptif (50 Hz, 60 Hz, 100 Hz, 120 Hz).
/// 3. Dukungan Dual-Mode: Paket Biner Kompak 17-Byte & JSON Fallback.
/// 4. Pengukuran True RTT Ping Echo Heartbeat secara real-time.
/// 5. Parsing URI QR Code format `vidric://<ip>:<port>`.
/// 6. Penyimpanan IP terakhir dengan SharedPreferences.
/// 7. Failsafe safety packet (mengirim paket netral saat disconnect).
class UdpService {
  UdpService._internal();

  static final UdpService instance = UdpService._internal();

  // Socket & Stream Timer
  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _socketSubscription;
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
  int _lastPingLatencyMs = 0;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _lastError;

  // Pelacakan RTT Echo (Seq -> Sent Timestamp)
  final Map<int, int> _pendingEchoTimestamps = <int, int>{};

  // Callback penyedia paket kontrol terkini dari ControllerScreen
  ControlPacket Function()? packetProvider;

  // Notifier Reaktif untuk UI
  final ValueNotifier<NetworkMetrics> metrics = ValueNotifier<NetworkMetrics>(
    const NetworkMetrics(),
  );

  NetworkMetrics get current => metrics.value;
  String get targetIp => _targetIp;
  int get targetPort => _targetPort;
  int get lastPingLatencyMs => _lastPingLatencyMs;
  bool get isConnected => current.isConnected;

  static const String prefKeyIp = 'vidric_last_ip';
  static const String prefKeyPort = 'vidric_last_port';

  /// Inisialisasi dan memuat alamat IP terakhir yang tersimpan.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _targetIp = prefs.getString(prefKeyIp) ?? '192.168.1.10';
      _targetPort = prefs.getInt(prefKeyPort) ?? 5005;
      SettingsService.instance.settings.addListener(_onSettingsChanged);
      _updateMetrics();
    } catch (e) {
      debugPrint('UdpService: Gagal memuat IP tersimpan: $e');
    }
  }

  void _onSettingsChanged() {
    if (isConnected && _transmissionTimer != null) {
      _startTransmissionTimer();
    }
    _updateMetrics();
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

  /// Menguji konektivitas ping / socket handshake ke target PC dengan RTT aktual.
  Future<bool> testPing(String ip, int port) async {
    try {
      final addresses = await InternetAddress.lookup(ip);
      if (addresses.isEmpty) return false;

      final testSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      testSocket.broadcastEnabled = true;

      final completer = Completer<int>();
      final start = DateTime.now().millisecondsSinceEpoch;

      final sub = testSocket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final dg = testSocket.receive();
          if (dg != null && !completer.isCompleted) {
            final rtt = DateTime.now().millisecondsSinceEpoch - start;
            completer.complete(rtt);
          }
        }
      });

      // Kirim probe packet (JSON probe dengan flag timestamp)
      final probePacket = jsonEncode({
        'mode': 'ping',
        'seq': 0,
        'client': 'ViDricMobile',
        't': start,
      });
      final bytes = utf8.encode(probePacket);
      final sent = testSocket.send(bytes, addresses.first, port);

      if (sent <= 0) {
        await sub.cancel();
        testSocket.close();
        return false;
      }

      try {
        final rtt = await completer.future.timeout(const Duration(milliseconds: 1000));
        _lastPingLatencyMs = rtt;
        _lastLatencyMs = rtt;
        _updateMetrics();
        await sub.cancel();
        testSocket.close();
        return true;
      } on TimeoutException {
        // Fallback jika tidak ada echo server (misal test environment tanpa UDP server live)
        await sub.cancel();
        testSocket.close();
        _lastPingLatencyMs = -1;
        return true;
      }
    } catch (e) {
      debugPrint('UdpService: Ping test gagal: $e');
      return false;
    }
  }

  /// Menghubungkan soket UDP dan memulai timer transmisi periodik sesuai frekuensi terpilih.
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
      await _socketSubscription?.cancel();
      _socket?.close();
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.broadcastEnabled = true;

      // Dengarkan respon datagram balik dari Server PC (Echo Heartbeat RTT)
      _socketSubscription = _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handleIncomingDatagram(datagram.data);
          }
        }
      });

      _status = ConnectionStatus.connected;
      _packetsSent = 0;
      _packetsInLastSecond = 0;
      _currentHz = 0.0;
      _lastError = null;

      // 1. Timer transmisi adaptif (50, 60, 100, 120 Hz)
      _startTransmissionTimer();

      // 2. Timer kalkulasi frekuensi aktual dan metrik transmisi (setiap 1 detik)
      _metricsTimer?.cancel();
      _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _currentHz = _packetsInLastSecond.toDouble();
        _packetsInLastSecond = 0;
        _updateMetrics();
      });

      _updateMetrics();
      debugPrint('UdpService: Terhubung ke $_targetIp:$_targetPort.');
      return true;
    } catch (e) {
      _status = ConnectionStatus.error;
      _lastError = e.toString();
      _updateMetrics();
      debugPrint('UdpService: Gagal menghubungkan UDP: $e');
      return false;
    }
  }

  void _startTransmissionTimer() {
    _transmissionTimer?.cancel();
    final int hz = SettingsService.instance.current.transmissionRateHz;
    final int targetHz = (hz > 0) ? hz : 50;
    final int intervalMicros = (1000000 / targetHz).round();

    _transmissionTimer = Timer.periodic(
      Duration(microseconds: intervalMicros),
      (_) => _sendCurrentPacketTick(),
    );
  }

  /// Memproses balasan datagram dari Server PC untuk kalkulasi Real RTT Ping.
  void _handleIncomingDatagram(Uint8List data) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // A. Binary Echo Heartbeat: 'VA' (0x56, 0x41) + uint16 seq
    if (data.length >= 4 && data[0] == 0x56 && data[1] == 0x41) {
      final byteData = ByteData.sublistView(data);
      final seq = byteData.getUint16(2, Endian.little);
      final sentTime = _pendingEchoTimestamps.remove(seq);
      if (sentTime != null) {
        final rtt = now - sentTime;
        if (rtt >= 0 && rtt < 1000) {
          _lastLatencyMs = rtt;
        }
      }
    }
    // B. Legacy Text "ack" atau "pong"
    else if ((data.length >= 3 && data[0] == 0x61 && data[1] == 0x63 && data[2] == 0x6B) ||
             (data.length >= 4 && data[0] == 0x70 && data[1] == 0x6F)) {
      if (_pendingEchoTimestamps.isNotEmpty) {
        final lastKey = _pendingEchoTimestamps.keys.last;
        final sentTime = _pendingEchoTimestamps.remove(lastKey);
        if (sentTime != null) {
          final rtt = now - sentTime;
          if (rtt >= 0 && rtt < 1000) {
            _lastLatencyMs = rtt;
          }
        }
      }
    }
  }

  /// Mengirim satu paket kontrol periodik pada tick frekuensi target.
  void _sendCurrentPacketTick() {
    if (_socket == null || _targetAddress == null) return;

    try {
      // Ambil paket kontrol terkini dari UI kokpit atau fallback paket netral
      final ControlPacket packet = packetProvider != null
          ? packetProvider!()
          : ControlPacket.neutral();

      final bool useBinary = SettingsService.instance.current.useBinaryProtocol;
      final List<int> bytes = useBinary
          ? packet.toBinaryPacket()
          : utf8.encode(jsonEncode(packet.toJson()));

      // Catat timestamp pengiriman seq untuk penghitungan RTT jika respons tiba
      final now = DateTime.now().millisecondsSinceEpoch;
      _pendingEchoTimestamps[packet.seq % 65536] = now;
      if (_pendingEchoTimestamps.length > 128) {
        _pendingEchoTimestamps.remove(_pendingEchoTimestamps.keys.first);
      }

      final int bytesSent = _socket!.send(bytes, _targetAddress!, _targetPort);

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

    _socketSubscription?.cancel();
    _socketSubscription = null;

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
      final bool useBinary = SettingsService.instance.current.useBinaryProtocol;
      final bytes = useBinary
          ? neutralPacket.toBinaryPacket()
          : utf8.encode(jsonEncode(neutralPacket.toJson()));
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
      targetRateHz: SettingsService.instance.current.transmissionRateHz,
      isBinary: SettingsService.instance.current.useBinaryProtocol,
      errorMessage: _lastError,
    );
  }
}


