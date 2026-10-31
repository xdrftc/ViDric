import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidric/models/control_packet.dart';
import 'package:vidric/services/udp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UdpService Unit Tests', () {
    late UdpService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = UdpService.instance;
      await service.init();
    });

    tearDown(() {
      service.disconnect();
    });

    test('parses various QR Code URI payloads correctly', () {
      // 1. Full URI with port
      final res1 = UdpService.parseQrPayload('vidric://192.168.1.150:5005');
      expect(res1, isNotNull);
      expect(res1!['ip'], equals('192.168.1.150'));
      expect(res1['port'], equals(5005));

      // 2. URI without port (defaults to 5005)
      final res2 = UdpService.parseQrPayload('vidric://10.0.0.42');
      expect(res2, isNotNull);
      expect(res2!['ip'], equals('10.0.0.42'));
      expect(res2['port'], equals(5005));

      // 3. Plain IP:Port without scheme
      final res3 = UdpService.parseQrPayload('172.16.0.5:8080');
      expect(res3, isNotNull);
      expect(res3!['ip'], equals('172.16.0.5'));
      expect(res3['port'], equals(8080));

      // 4. Invalid IP formats
      expect(UdpService.parseQrPayload('not-an-ip'), isNull);
      expect(UdpService.parseQrPayload('vidric://999.999.999.999'), isNull);
      expect(UdpService.parseQrPayload(''), isNull);
    });

    test('configures and persists target IP and Port', () async {
      await service.configureTarget('192.168.1.200', 6006);

      expect(service.targetIp, equals('192.168.1.200'));
      expect(service.targetPort, equals(6006));
      expect(service.current.targetIp, equals('192.168.1.200'));
      expect(service.current.targetPort, equals(6006));

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(UdpService.prefKeyIp), equals('192.168.1.200'));
      expect(prefs.getInt(UdpService.prefKeyPort), equals(6006));
    });

    test('packetProvider integrates with ControlPacket serialization', () {
      bool providerCalled = false;
      service.packetProvider = () {
        providerCalled = true;
        return const ControlPacket(
          mode: 'guiWheel',
          steering: 0.5,
          gas: 0.8,
          brake: 0.0,
          buttons: [7, 12],
          seq: 99,
        );
      };

      expect(service.packetProvider, isNotNull);
      final packet = service.packetProvider!();
      expect(providerCalled, isTrue);
      expect(packet.steering, equals(0.5));
      expect(packet.buttons, equals([7, 12]));
    });

    test('initial connection status is disconnected and Hz is 0.0', () {
      expect(service.current.status, equals(ConnectionStatus.disconnected));
      expect(service.current.packetsPerSecond, equals(0.0));
      expect(service.isConnected, isFalse);
    });
  });
}
