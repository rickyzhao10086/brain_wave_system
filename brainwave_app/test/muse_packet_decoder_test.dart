import 'dart:typed_data';

import 'package:brainwave_app/services/muse_packet_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MusePacketDecoder', () {
    test('decodes packed EEG samples', () {
      final low = MusePacketDecoder.decodeEeg(Uint8List(20));
      final high = MusePacketDecoder.decodeEeg(
        Uint8List.fromList(List<int>.filled(20, 0xff)),
      );

      expect(low.index, 0);
      expect(low.samples, hasLength(12));
      expect(low.samples.first, closeTo(-1000, .001));
      expect(high.index, 65535);
      expect(high.samples.first, closeTo(999.5117, .001));
    });

    test('decodes IMU samples in Muse axis order', () {
      final bytes = ByteData(20)..setUint16(0, 7, Endian.big);
      for (var i = 0; i < 9; i++) {
        bytes.setInt16(2 + i * 2, i + 1, Endian.big);
      }

      final packet = MusePacketDecoder.decodeAccelerometer(
        bytes.buffer.asUint8List(),
      );

      expect(packet.index, 7);
      expect(packet.samples[0][0], closeTo(1 * 0.0000610352, 1e-10));
      expect(packet.samples[0][1], closeTo(4 * 0.0000610352, 1e-10));
      expect(packet.samples[0][2], closeTo(7 * 0.0000610352, 1e-10));
      expect(packet.samples[2][2], closeTo(9 * 0.0000610352, 1e-10));
    });

    test('decodes telemetry battery percentage', () {
      final bytes = ByteData(20)
        ..setUint16(2, 80 * 512, Endian.big)
        ..setUint16(4, 100, Endian.big)
        ..setUint16(6, 3300, Endian.big)
        ..setUint16(8, 25, Endian.big);

      final packet = MusePacketDecoder.decodeTelemetry(
        bytes.buffer.asUint8List(),
      );

      expect(packet.batteryPercent, 80);
      expect(packet.fuelGauge, closeTo(220, .001));
      expect(packet.adcVoltage, 3300);
      expect(packet.temperature, 25);
    });
  });
}
