import 'dart:collection';
import 'dart:math' as math;

import 'muse_packet_decoder.dart';

class MuseBleMetrics {
  const MuseBleMetrics({
    required this.contact,
    required this.bands,
    required this.heartRate,
    required this.motionG,
    required this.gyroDps,
    required this.batteryPercent,
    required this.eegLive,
    required this.ppgLive,
    required this.accLive,
    required this.gyroLive,
  });

  final Map<String, double> contact;
  final Map<String, double> bands;
  final int? heartRate;
  final double motionG;
  final double gyroDps;
  final int? batteryPercent;
  final bool eegLive;
  final bool ppgLive;
  final bool accLive;
  final bool gyroLive;
}

class MuseSignalProcessor {
  static const eegSampleRate = 256;
  static const ppgSampleRate = 64;
  static const channelNames = ['TP9', 'AF7', 'AF8', 'TP10'];

  final List<ListQueue<double>> _eeg = List.generate(
    channelNames.length,
    (_) => ListQueue<double>(),
  );
  final ListQueue<double> _infraredPpg = ListQueue<double>();

  DateTime? _lastEeg;
  DateTime? _lastPpg;
  DateTime? _lastAcc;
  DateTime? _lastGyro;
  double _motionG = 0;
  double _gyroDps = 0;
  int? _batteryPercent;

  void reset() {
    for (final channel in _eeg) {
      channel.clear();
    }
    _infraredPpg.clear();
    _lastEeg = null;
    _lastPpg = null;
    _lastAcc = null;
    _lastGyro = null;
    _motionG = 0;
    _gyroDps = 0;
    _batteryPercent = null;
  }

  void addEeg(int channel, MuseEegPacket packet) {
    if (channel < 0 || channel >= _eeg.length) return;
    _append(_eeg[channel], packet.samples, eegSampleRate * 2);
    _lastEeg = DateTime.now();
  }

  void addPpg(int channel, MusePpgPacket packet) {
    if (channel == 1) {
      _append(_infraredPpg, packet.samples, ppgSampleRate * 10);
    }
    _lastPpg = DateTime.now();
  }

  void addAccelerometer(MuseImuPacket packet) {
    var largestDeviation = 0.0;
    for (final sample in packet.samples) {
      final magnitude = math.sqrt(
        sample[0] * sample[0] + sample[1] * sample[1] + sample[2] * sample[2],
      );
      largestDeviation = math.max(largestDeviation, (magnitude - 1).abs());
    }
    _motionG = _motionG * .65 + largestDeviation * .35;
    _lastAcc = DateTime.now();
  }

  void addGyroscope(MuseImuPacket packet) {
    var largestMagnitude = 0.0;
    for (final sample in packet.samples) {
      largestMagnitude = math.max(
        largestMagnitude,
        math.sqrt(
          sample[0] * sample[0] + sample[1] * sample[1] + sample[2] * sample[2],
        ),
      );
    }
    _gyroDps = _gyroDps * .65 + largestMagnitude * .35;
    _lastGyro = DateTime.now();
  }

  void addTelemetry(MuseTelemetryPacket packet) {
    _batteryPercent = packet.batteryPercent.round().clamp(0, 100);
  }

  MuseBleMetrics buildMetrics() {
    final now = DateTime.now();
    final bands = _relativeBandPower();
    return MuseBleMetrics(
      contact: {
        for (var i = 0; i < channelNames.length; i++)
          channelNames[i]: _signalQuality(_eeg[i]),
      },
      bands: bands,
      heartRate: _estimateHeartRate(),
      motionG: _motionG,
      gyroDps: _gyroDps,
      batteryPercent: _batteryPercent,
      eegLive: _isRecent(_lastEeg, now),
      ppgLive: _isRecent(_lastPpg, now),
      accLive: _isRecent(_lastAcc, now),
      gyroLive: _isRecent(_lastGyro, now),
    );
  }

  static bool _isRecent(DateTime? value, DateTime now) {
    return value != null && now.difference(value) < const Duration(seconds: 3);
  }

  static void _append(
    ListQueue<double> target,
    Iterable<double> values,
    int maximum,
  ) {
    target.addAll(values);
    while (target.length > maximum) {
      target.removeFirst();
    }
  }

  static double _signalQuality(ListQueue<double> samples) {
    if (samples.length < eegSampleRate ~/ 2) return 0;
    final window = samples.toList().sublist(
      samples.length - eegSampleRate ~/ 2,
    );
    final mean = window.reduce((a, b) => a + b) / window.length;
    var variance = 0.0;
    var maxAbsolute = 0.0;
    for (final sample in window) {
      variance += math.pow(sample - mean, 2).toDouble();
      maxAbsolute = math.max(maxAbsolute, sample.abs());
    }
    final standardDeviation = math.sqrt(variance / window.length);

    if (standardDeviation < .5 || maxAbsolute > 990) return .1;
    if (standardDeviation > 300) return .2;
    if (standardDeviation > 150) return .45;
    if (standardDeviation > 75) return .7;
    return .92;
  }

  Map<String, double> _relativeBandPower() {
    if (_eeg.any((channel) => channel.length < eegSampleRate)) {
      return const {'delta': 0, 'theta': 0, 'alpha': 0, 'beta': 0, 'gamma': 0};
    }

    final powers = List<double>.filled(46, 0);
    for (final queue in _eeg) {
      final samples = queue.toList().sublist(queue.length - eegSampleRate);
      final mean = samples.reduce((a, b) => a + b) / samples.length;
      for (var frequency = 1; frequency <= 45; frequency++) {
        var real = 0.0;
        var imaginary = 0.0;
        for (var sample = 0; sample < samples.length; sample++) {
          final window =
              .5 * (1 - math.cos(2 * math.pi * sample / (samples.length - 1)));
          final value = (samples[sample] - mean) * window;
          final angle = 2 * math.pi * frequency * sample / eegSampleRate;
          real += value * math.cos(angle);
          imaginary -= value * math.sin(angle);
        }
        powers[frequency] += real * real + imaginary * imaginary;
      }
    }

    double sumRange(int start, int end) {
      var sum = 0.0;
      for (var frequency = start; frequency <= end; frequency++) {
        sum += powers[frequency];
      }
      return sum;
    }

    final raw = <String, double>{
      'delta': sumRange(1, 3),
      'theta': sumRange(4, 7),
      'alpha': sumRange(8, 12),
      'beta': sumRange(13, 29),
      'gamma': sumRange(30, 45),
    };
    final total = raw.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return raw;
    return raw.map((name, value) => MapEntry(name, value / total));
  }

  int? _estimateHeartRate() {
    if (_infraredPpg.length < ppgSampleRate * 6) return null;
    final samples = _infraredPpg.toList();
    final mean = samples.reduce((a, b) => a + b) / samples.length;
    var variance = 0.0;
    for (final value in samples) {
      variance += math.pow(value - mean, 2).toDouble();
    }
    final standardDeviation = math.sqrt(variance / samples.length);
    if (standardDeviation == 0) return null;

    final threshold = mean + standardDeviation * .45;
    final peaks = <int>[];
    final minimumDistance = (ppgSampleRate * .33).round();
    for (var i = 1; i < samples.length - 1; i++) {
      final isPeak =
          samples[i] > threshold &&
          samples[i] > samples[i - 1] &&
          samples[i] >= samples[i + 1];
      if (!isPeak) continue;
      if (peaks.isEmpty || i - peaks.last >= minimumDistance) {
        peaks.add(i);
      } else if (samples[i] > samples[peaks.last]) {
        peaks[peaks.length - 1] = i;
      }
    }
    if (peaks.length < 4) return null;

    final intervals = <double>[];
    for (var i = 1; i < peaks.length; i++) {
      intervals.add((peaks[i] - peaks[i - 1]) / ppgSampleRate);
    }
    intervals.sort();
    final median = intervals[intervals.length ~/ 2];
    final bpm = (60 / median).round();
    return bpm >= 40 && bpm <= 180 ? bpm : null;
  }
}
