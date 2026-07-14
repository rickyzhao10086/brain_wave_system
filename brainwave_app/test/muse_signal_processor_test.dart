import 'dart:math' as math;

import 'package:brainwave_app/services/muse_packet_decoder.dart';
import 'package:brainwave_app/services/muse_signal_processor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identifies a 10 Hz EEG signal as alpha dominant', () {
    final processor = MuseSignalProcessor();
    for (var packet = 0; packet < 22; packet++) {
      final samples = List<double>.generate(12, (offset) {
        final sample = packet * 12 + offset;
        return 50 * math.sin(2 * math.pi * 10 * sample / 256);
      });
      for (var channel = 0; channel < 4; channel++) {
        processor.addEeg(channel, MuseEegPacket(packet, samples));
      }
    }

    final metrics = processor.buildMetrics();

    expect(metrics.eegLive, isTrue);
    expect(metrics.bands['alpha'], greaterThan(metrics.bands['theta']!));
    expect(metrics.bands['alpha'], greaterThan(metrics.bands['beta']!));
    expect(metrics.contact.values, everyElement(greaterThan(.8)));
  });

  test('estimates pulse rate from infrared PPG peaks', () {
    final processor = MuseSignalProcessor();
    for (var packet = 0; packet < 107; packet++) {
      final samples = List<double>.generate(6, (offset) {
        final sample = packet * 6 + offset;
        return 100000 + 1000 * math.sin(2 * math.pi * 1.2 * sample / 64);
      });
      processor.addPpg(1, MusePpgPacket(packet, samples));
    }

    final metrics = processor.buildMetrics();

    expect(metrics.ppgLive, isTrue);
    expect(metrics.heartRate, closeTo(72, 2));
  });
}
