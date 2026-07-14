import 'dart:async';
import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

import 'muse_packet_decoder.dart';
import 'muse_signal_processor.dart';

typedef MuseMetricsCallback = void Function(MuseBleMetrics metrics);

class MuseBleClient {
  MuseBleClient({
    required this.onMetrics,
    required this.onDisconnected,
    required this.onError,
  });

  static const _controlUuid = '273e0001-4c4d-454d-96be-f03bac821358';
  static const _gyroUuid = '273e0009-4c4d-454d-96be-f03bac821358';
  static const _accelerometerUuid = '273e000a-4c4d-454d-96be-f03bac821358';
  static const _telemetryUuid = '273e000b-4c4d-454d-96be-f03bac821358';
  static const _eegUuids = [
    '273e0003-4c4d-454d-96be-f03bac821358',
    '273e0004-4c4d-454d-96be-f03bac821358',
    '273e0005-4c4d-454d-96be-f03bac821358',
    '273e0006-4c4d-454d-96be-f03bac821358',
  ];
  static const _ppgUuids = [
    '273e000f-4c4d-454d-96be-f03bac821358',
    '273e0010-4c4d-454d-96be-f03bac821358',
    '273e0011-4c4d-454d-96be-f03bac821358',
  ];

  final MuseMetricsCallback onMetrics;
  final void Function() onDisconnected;
  final void Function(String message) onError;
  final MuseSignalProcessor _processor = MuseSignalProcessor();
  final List<StreamSubscription<Uint8List>> _valueSubscriptions = [];
  final List<BleCharacteristic> _notifyingCharacteristics = [];

  BleDevice? _device;
  BleCharacteristic? _control;
  StreamSubscription<BleDevice>? _scanSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Completer<BleDevice>? _scanCompleter;
  Timer? _metricsTimer;
  bool _disconnecting = false;

  String? get deviceName => _device?.name;
  bool get isConnected => _device != null && !_disconnecting;

  Future<void> connect({
    String namePrefix = 'Muse',
    void Function()? onDeviceFound,
  }) async {
    await disconnect();
    _disconnecting = false;
    _processor.reset();

    await UniversalBle.requestPermissions(withAndroidFineLocation: false);
    final availability = await _waitForBluetooth();
    if (availability != AvailabilityState.poweredOn) {
      throw StateError(_availabilityMessage(availability));
    }

    final device = await _scanForMuse(namePrefix);
    onDeviceFound?.call();
    _device = device;
    await device.connect(timeout: const Duration(seconds: 20));
    if (_disconnecting) return;

    _connectionSubscription = device.connectionStream.listen((connected) {
      if (!connected && !_disconnecting) {
        _handleUnexpectedDisconnect();
      }
    });

    final services = await device.discoverServices(
      timeout: const Duration(seconds: 15),
    );
    final characteristics = <String, BleCharacteristic>{};
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        characteristics[characteristic.uuid.toLowerCase()] = characteristic;
      }
    }

    _control = _requiredCharacteristic(characteristics, _controlUuid);
    await _subscribe(_control!, (_) {});

    for (var channel = 0; channel < _eegUuids.length; channel++) {
      final characteristic = _requiredCharacteristic(
        characteristics,
        _eegUuids[channel],
      );
      await _subscribe(characteristic, (packet) {
        try {
          _processor.addEeg(channel, MusePacketDecoder.decodeEeg(packet));
        } on FormatException catch (error) {
          onError(error.message);
        }
      });
    }

    await _subscribeIfPresent(characteristics, _accelerometerUuid, (packet) {
      _processor.addAccelerometer(
        MusePacketDecoder.decodeAccelerometer(packet),
      );
    });
    await _subscribeIfPresent(characteristics, _gyroUuid, (packet) {
      _processor.addGyroscope(MusePacketDecoder.decodeGyroscope(packet));
    });
    await _subscribeIfPresent(characteristics, _telemetryUuid, (packet) {
      _processor.addTelemetry(MusePacketDecoder.decodeTelemetry(packet));
    });
    for (var channel = 0; channel < _ppgUuids.length; channel++) {
      await _subscribeIfPresent(characteristics, _ppgUuids[channel], (packet) {
        _processor.addPpg(channel, MusePacketDecoder.decodePpg(packet));
      });
    }

    await _writeCommand('d');
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      onMetrics(_processor.buildMetrics());
    });
  }

  Future<void> disconnect() async {
    _disconnecting = true;
    _metricsTimer?.cancel();
    _metricsTimer = null;

    final scanCompleter = _scanCompleter;
    if (scanCompleter != null && !scanCompleter.isCompleted) {
      scanCompleter.completeError(StateError('Muse scan cancelled.'));
    }
    _scanCompleter = null;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    try {
      if (await UniversalBle.isScanning()) {
        await UniversalBle.stopScan();
      }
    } catch (_) {
      // A scan may already have ended at the platform layer.
    }

    if (_control != null) {
      try {
        await _writeCommand('h');
      } catch (_) {
        // The headband may already be out of range or powered off.
      }
    }

    for (final characteristic in _notifyingCharacteristics.reversed) {
      try {
        await characteristic.unsubscribe(timeout: const Duration(seconds: 2));
      } catch (_) {
        // Continue cleanup when one characteristic is already unavailable.
      }
    }
    _notifyingCharacteristics.clear();
    for (final subscription in _valueSubscriptions) {
      await subscription.cancel();
    }
    _valueSubscriptions.clear();
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    final device = _device;
    _device = null;
    _control = null;
    if (device != null) {
      try {
        await device.disconnect(timeout: const Duration(seconds: 5));
      } catch (_) {
        // Native stacks can report an error when the device is already gone.
      }
    }
    _processor.reset();
  }

  Future<BleDevice> _scanForMuse(String namePrefix) async {
    final completer = Completer<BleDevice>();
    _scanCompleter = completer;
    _scanSubscription = UniversalBle.scanStream.listen((device) {
      final name = device.name ?? '';
      if (name.toLowerCase().startsWith(namePrefix.toLowerCase()) &&
          !completer.isCompleted) {
        completer.complete(device);
      }
    });

    try {
      await UniversalBle.startScan(
        scanFilter: ScanFilter(withNamePrefix: [namePrefix]),
        platformConfig: PlatformConfig(
          android: AndroidOptions(
            requestLocationPermission: false,
            scanMode: AndroidScanMode.lowLatency,
            legacy: true,
          ),
        ),
      );
      return await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw TimeoutException(
          'No Muse headband was found. Make sure it is on and not connected to another app.',
        ),
      );
    } finally {
      _scanCompleter = null;
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      try {
        await UniversalBle.stopScan();
      } catch (_) {
        // A timed-out scan can already be stopped by the platform.
      }
    }
  }

  static BleCharacteristic _requiredCharacteristic(
    Map<String, BleCharacteristic> characteristics,
    String uuid,
  ) {
    final characteristic = characteristics[uuid];
    if (characteristic == null) {
      throw StateError(
        'This device does not expose the expected Muse 2 characteristic $uuid.',
      );
    }
    return characteristic;
  }

  Future<void> _subscribeIfPresent(
    Map<String, BleCharacteristic> characteristics,
    String uuid,
    void Function(Uint8List packet) onPacket,
  ) async {
    final characteristic = characteristics[uuid];
    if (characteristic == null) return;
    try {
      await _subscribe(characteristic, (packet) {
        try {
          onPacket(packet);
        } on FormatException catch (error) {
          onError(error.message);
        }
      });
    } catch (error) {
      onError('Muse sensor $uuid could not be enabled: $error');
    }
  }

  Future<void> _subscribe(
    BleCharacteristic characteristic,
    void Function(Uint8List packet) onPacket,
  ) async {
    if (!characteristic.notifications.isSupported) {
      throw StateError(
        'Muse characteristic ${characteristic.uuid} is not notifiable.',
      );
    }
    _valueSubscriptions.add(characteristic.onValueReceived.listen(onPacket));
    await characteristic.notifications.subscribe(
      timeout: const Duration(seconds: 8),
    );
    _notifyingCharacteristics.add(characteristic);
  }

  Future<void> _writeCommand(String command) async {
    final control = _control;
    if (control == null) return;
    final bytes = <int>[command.length + 1, ...command.codeUnits, 0x0a];
    await control.write(
      bytes,
      withResponse: false,
      timeout: const Duration(seconds: 5),
    );
  }

  void _handleUnexpectedDisconnect() {
    _metricsTimer?.cancel();
    _metricsTimer = null;
    onDisconnected();
  }

  static String _availabilityMessage(AvailabilityState state) {
    return switch (state) {
      AvailabilityState.poweredOff => 'Turn on Bluetooth and try again.',
      AvailabilityState.unauthorized =>
        'Bluetooth permission is denied. Enable it in system settings.',
      AvailabilityState.unsupported =>
        'Bluetooth Low Energy is not supported on this device.',
      _ => 'Bluetooth is not ready yet. Wait a moment and try again.',
    };
  }

  static Future<AvailabilityState> _waitForBluetooth() async {
    var state = await UniversalBle.getBluetoothAvailabilityState();
    for (var attempt = 0;
        attempt < 8 &&
            (state == AvailabilityState.unknown ||
                state == AvailabilityState.resetting);
        attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      state = await UniversalBle.getBluetoothAvailabilityState();
    }
    return state;
  }
}
