import 'dart:typed_data';

class MuseEegPacket {
  const MuseEegPacket(this.index, this.samples);

  final int index;
  final List<double> samples;
}

class MusePpgPacket {
  const MusePpgPacket(this.index, this.samples);

  final int index;
  final List<double> samples;
}

class MuseImuPacket {
  const MuseImuPacket(this.index, this.samples);

  final int index;
  final List<List<double>> samples;
}

class MuseTelemetryPacket {
  const MuseTelemetryPacket({
    required this.batteryPercent,
    required this.fuelGauge,
    required this.adcVoltage,
    required this.temperature,
  });

  final double batteryPercent;
  final double fuelGauge;
  final int adcVoltage;
  final int temperature;
}

class MusePacketDecoder {
  static const eegScale = 0.48828125;
  static const accelerometerScale = 0.0000610352;
  static const gyroscopeScale = 0.0074768;

  static MuseEegPacket decodeEeg(Uint8List packet) {
    if (packet.length < 20) {
      throw const FormatException('Muse EEG packet must contain 20 bytes.');
    }

    final index = _readUnsignedBits(packet, 0, 16);
    final samples = List<double>.generate(12, (sample) {
      final raw = _readUnsignedBits(packet, 16 + sample * 12, 12);
      return eegScale * (raw - 2048);
    }, growable: false);
    return MuseEegPacket(index, samples);
  }

  static MusePpgPacket decodePpg(Uint8List packet) {
    if (packet.length < 20) {
      throw const FormatException('Muse PPG packet must contain 20 bytes.');
    }

    final bytes = ByteData.sublistView(packet);
    final samples = List<double>.generate(6, (sample) {
      final offset = 2 + sample * 3;
      return ((bytes.getUint8(offset) << 16) |
              (bytes.getUint8(offset + 1) << 8) |
              bytes.getUint8(offset + 2))
          .toDouble();
    }, growable: false);
    return MusePpgPacket(bytes.getUint16(0, Endian.big), samples);
  }

  static MuseImuPacket decodeAccelerometer(Uint8List packet) {
    return _decodeImu(packet, accelerometerScale);
  }

  static MuseImuPacket decodeGyroscope(Uint8List packet) {
    return _decodeImu(packet, gyroscopeScale);
  }

  static MuseTelemetryPacket decodeTelemetry(Uint8List packet) {
    if (packet.length < 10) {
      throw const FormatException(
        'Muse telemetry packet must contain at least 10 bytes.',
      );
    }

    final bytes = ByteData.sublistView(packet);
    return MuseTelemetryPacket(
      batteryPercent: bytes.getUint16(2, Endian.big) / 512,
      fuelGauge: bytes.getUint16(4, Endian.big) * 2.2,
      adcVoltage: bytes.getUint16(6, Endian.big),
      temperature: bytes.getUint16(8, Endian.big),
    );
  }

  static MuseImuPacket _decodeImu(Uint8List packet, double scale) {
    if (packet.length < 20) {
      throw const FormatException('Muse IMU packet must contain 20 bytes.');
    }

    final bytes = ByteData.sublistView(packet);
    final raw = List<int>.generate(
      9,
      (index) => bytes.getInt16(2 + index * 2, Endian.big),
      growable: false,
    );
    final samples = List<List<double>>.generate(
      3,
      (sample) => List<double>.generate(
        3,
        (axis) => raw[sample + axis * 3] * scale,
        growable: false,
      ),
      growable: false,
    );
    return MuseImuPacket(bytes.getUint16(0, Endian.big), samples);
  }

  static int _readUnsignedBits(Uint8List data, int start, int width) {
    var value = 0;
    for (var bit = 0; bit < width; bit++) {
      final absoluteBit = start + bit;
      final byte = data[absoluteBit ~/ 8];
      final bitValue = (byte >> (7 - absoluteBit % 8)) & 1;
      value = (value << 1) | bitValue;
    }
    return value;
  }
}
