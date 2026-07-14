import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'muse_ble_client.dart';
import 'muse_signal_processor.dart';

enum MuseConnectionStatus { mock, scanning, connecting, live, offline }

enum MuseDataSource { mock, directBle, bridge }

class MuseLiveService extends ChangeNotifier {
  MuseLiveService._();

  static final MuseLiveService instance = MuseLiveService._();

  static const defaultUrl = String.fromEnvironment(
    'MUSE_WS_URL',
    defaultValue: 'ws://127.0.0.1:8765',
  );

  MuseConnectionStatus _status = MuseConnectionStatus.mock;
  MuseSnapshot _snapshot = MuseSnapshot.mock();
  MuseDataSource _source = MuseDataSource.mock;
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  MuseBleClient? _bleClient;
  String _url = defaultUrl;
  String? _errorMessage;
  int _connectionGeneration = 0;

  MuseConnectionStatus get status => _status;
  MuseSnapshot get snapshot => _snapshot;
  MuseDataSource get source => _source;
  String get url => _url;
  String? get errorMessage => _errorMessage;
  String? get deviceName => _bleClient?.deviceName;

  String get sourceLabel => switch (_source) {
    MuseDataSource.directBle => 'Direct BLE',
    MuseDataSource.bridge => 'Bridge',
    MuseDataSource.mock => 'Mock',
  };

  bool get isLive => _status == MuseConnectionStatus.live && _snapshot.isLive;

  Future<void> connectDirect({String namePrefix = 'Muse'}) async {
    if (_isBusy || _status == MuseConnectionStatus.live) {
      return;
    }
    final generation = ++_connectionGeneration;
    await _disconnectTransports();
    if (generation != _connectionGeneration) return;

    _source = MuseDataSource.directBle;
    _errorMessage = null;
    _setStatus(MuseConnectionStatus.scanning);
    final client = MuseBleClient(
      onMetrics: _handleBleMetrics,
      onDisconnected: _goBleOffline,
      onError: (message) {
        _errorMessage = message;
        notifyListeners();
      },
    );
    _bleClient = client;

    try {
      await client.connect(
        namePrefix: namePrefix,
        onDeviceFound: () {
          if (generation == _connectionGeneration) {
            _setStatus(MuseConnectionStatus.connecting);
          }
        },
      );
    } catch (error) {
      if (generation != _connectionGeneration) return;
      _errorMessage = _friendlyError(error);
      await client.disconnect();
      _bleClient = null;
      _setStatus(MuseConnectionStatus.offline);
    }
  }

  Future<void> connect({String url = defaultUrl}) => connectBridge(url: url);

  Future<void> connectBridge({String url = defaultUrl}) async {
    if (_isBusy || _status == MuseConnectionStatus.live) return;
    final generation = ++_connectionGeneration;
    await _disconnectTransports();
    if (generation != _connectionGeneration) return;

    _source = MuseDataSource.bridge;
    _errorMessage = null;
    _url = url;
    _setStatus(MuseConnectionStatus.connecting);

    try {
      final socket = await WebSocket.connect(
        url,
      ).timeout(const Duration(seconds: 3));
      _socket = socket;
      _subscription = socket.listen(
        _handleMessage,
        onDone: _goBridgeOffline,
        onError: (_) => _goBridgeOffline(),
        cancelOnError: true,
      );
    } catch (error) {
      if (generation != _connectionGeneration) return;
      _errorMessage = _friendlyError(error);
      _goBridgeOffline();
    }
  }

  Future<void> disconnect() async {
    _connectionGeneration++;
    await _disconnectTransports();
    _source = MuseDataSource.mock;
    _errorMessage = null;
    _snapshot = MuseSnapshot.mock();
    _setStatus(MuseConnectionStatus.mock);
  }

  Future<void> _disconnectTransports() async {
    await _subscription?.cancel();
    _subscription = null;
    await _socket?.close();
    _socket = null;
    final bleClient = _bleClient;
    _bleClient = null;
    await bleClient?.disconnect();
  }

  void _handleMessage(dynamic message) {
    if (message is! String) return;
    try {
      final json = jsonDecode(message);
      if (json is! Map<String, dynamic>) return;
      _snapshot = MuseSnapshot.fromJson(json);
      _source = MuseDataSource.bridge;
      _setStatus(
        _snapshot.isLive
            ? MuseConnectionStatus.live
            : MuseConnectionStatus.offline,
      );
    } catch (_) {
      // Ignore malformed bridge messages and keep the previous reading.
    }
  }

  void _handleBleMetrics(MuseBleMetrics metrics) {
    final contact = metrics.contact;
    final minimumContact = contact.values.fold<double>(
      1,
      (minimum, value) => value < minimum ? value : minimum,
    );
    final artifact = !metrics.eegLive
        ? 'Waiting'
        : metrics.motionG > .12 || metrics.gyroDps > 12
        ? 'High'
        : metrics.motionG > .05 || metrics.gyroDps > 5
        ? 'Moderate'
        : 'Low';
    final bands = MuseBands.fromValues(metrics.bands);
    final state = _estimateState(
      eegLive: metrics.eegLive,
      minimumContact: minimumContact,
      artifact: artifact,
      bands: bands,
    );

    _source = MuseDataSource.directBle;
    _snapshot = MuseSnapshot(
      source: 'ble',
      connected: true,
      sampleRate: 256,
      batteryPercent: metrics.batteryPercent,
      state: state,
      contact: contact,
      bands: bands,
      body: MuseBodySignals(
        ppg: metrics.ppgLive ? 'Acquiring' : 'Waiting',
        heartRate: metrics.heartRate,
        breathRate: null,
        motionG: metrics.motionG,
        gyroDps: metrics.gyroDps,
      ),
      streams: MuseStreams(
        eeg: metrics.eegLive,
        ppg: metrics.ppgLive,
        acc: metrics.accLive,
        gyro: metrics.gyroLive,
      ),
    );
    _setStatus(
      metrics.eegLive
          ? MuseConnectionStatus.live
          : MuseConnectionStatus.connecting,
    );
  }

  void _goBleOffline() {
    _snapshot = _snapshot.copyWith(connected: false);
    _setStatus(MuseConnectionStatus.offline);
  }

  void _goBridgeOffline() {
    _subscription?.cancel();
    _subscription = null;
    _socket = null;
    _setStatus(MuseConnectionStatus.offline);
  }

  bool get _isBusy =>
      _status == MuseConnectionStatus.scanning ||
      _status == MuseConnectionStatus.connecting;

  static MuseState _estimateState({
    required bool eegLive,
    required double minimumContact,
    required String artifact,
    required MuseBands bands,
  }) {
    if (!eegLive) {
      return const MuseState(
        label: 'Waiting',
        confidence: 0,
        artifact: 'Waiting',
      );
    }

    final artifactPenalty = switch (artifact) {
      'High' => .3,
      'Moderate' => .12,
      _ => 0,
    };
    final confidence = (.48 + minimumContact * .45 - artifactPenalty).clamp(
      .25,
      .94,
    );
    if (minimumContact < .4 || artifact == 'High') {
      return MuseState(
        label: 'Review',
        confidence: confidence,
        artifact: artifact,
      );
    }
    return MuseState(
      label: bands.alpha > bands.beta && bands.alpha > bands.theta
          ? 'Calm'
          : 'Elevated',
      confidence: confidence,
      artifact: artifact,
    );
  }

  static String _friendlyError(Object error) {
    if (error is TimeoutException) {
      return error.message ?? 'Connection timed out.';
    }
    if (error is StateError) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _setStatus(MuseConnectionStatus status) {
    _status = status;
    notifyListeners();
  }
}

class MuseSnapshot {
  const MuseSnapshot({
    required this.source,
    required this.connected,
    required this.sampleRate,
    required this.batteryPercent,
    required this.state,
    required this.contact,
    required this.bands,
    required this.body,
    required this.streams,
  });

  final String source;
  final bool connected;
  final int? sampleRate;
  final int? batteryPercent;
  final MuseState state;
  final Map<String, double> contact;
  final MuseBands bands;
  final MuseBodySignals body;
  final MuseStreams streams;

  bool get isLive => source != 'mock' && connected;

  factory MuseSnapshot.mock() {
    return const MuseSnapshot(
      source: 'mock',
      connected: false,
      sampleRate: 256,
      batteryPercent: 82,
      state: MuseState(label: 'Calm', confidence: .91, artifact: 'Low'),
      contact: {'TP9': .92, 'AF7': .86, 'AF8': .89, 'TP10': .95},
      bands: MuseBands(
        delta: .30,
        theta: .42,
        alpha: .78,
        beta: .35,
        gamma: .18,
      ),
      body: MuseBodySignals(
        ppg: 'Mock',
        heartRate: 72,
        breathRate: 15,
        motionG: .04,
        gyroDps: 1.2,
      ),
      streams: MuseStreams(eeg: false, ppg: false, acc: false, gyro: false),
    );
  }

  factory MuseSnapshot.fromJson(Map<String, dynamic> json) {
    final device = _map(json['device']);
    return MuseSnapshot(
      source: _string(json['source'], fallback: 'waiting'),
      connected: _bool(device['connected']),
      sampleRate: _int(device['sampleRate']),
      batteryPercent: _int(device['batteryPercent']),
      state: MuseState.fromJson(_map(json['state'])),
      contact: _contactFromJson(_map(json['contact'])),
      bands: MuseBands.fromJson(_map(json['bands'])),
      body: MuseBodySignals.fromJson(_map(json['body'])),
      streams: MuseStreams.fromJson(_map(json['streams'])),
    );
  }

  MuseSnapshot copyWith({bool? connected}) {
    return MuseSnapshot(
      source: source,
      connected: connected ?? this.connected,
      sampleRate: sampleRate,
      batteryPercent: batteryPercent,
      state: state,
      contact: contact,
      bands: bands,
      body: body,
      streams: streams,
    );
  }

  static Map<String, double> _contactFromJson(Map<String, dynamic> json) {
    return {
      'TP9': _double(json['TP9'], fallback: .0),
      'AF7': _double(json['AF7'], fallback: .0),
      'AF8': _double(json['AF8'], fallback: .0),
      'TP10': _double(json['TP10'], fallback: .0),
    };
  }
}

class MuseState {
  const MuseState({
    required this.label,
    required this.confidence,
    required this.artifact,
  });

  final String label;
  final double confidence;
  final String artifact;

  factory MuseState.fromJson(Map<String, dynamic> json) {
    return MuseState(
      label: _string(json['label'], fallback: 'Waiting'),
      confidence: _double(json['confidence'], fallback: .0),
      artifact: _string(json['artifact'], fallback: 'Waiting'),
    );
  }
}

class MuseBands {
  const MuseBands({
    required this.delta,
    required this.theta,
    required this.alpha,
    required this.beta,
    required this.gamma,
  });

  final double delta;
  final double theta;
  final double alpha;
  final double beta;
  final double gamma;

  factory MuseBands.fromJson(Map<String, dynamic> json) {
    return MuseBands(
      delta: _double(json['delta'], fallback: .0),
      theta: _double(json['theta'], fallback: .0),
      alpha: _double(json['alpha'], fallback: .0),
      beta: _double(json['beta'], fallback: .0),
      gamma: _double(json['gamma'], fallback: .0),
    );
  }

  factory MuseBands.fromValues(Map<String, double> values) {
    return MuseBands(
      delta: values['delta'] ?? 0,
      theta: values['theta'] ?? 0,
      alpha: values['alpha'] ?? 0,
      beta: values['beta'] ?? 0,
      gamma: values['gamma'] ?? 0,
    );
  }
}

class MuseBodySignals {
  const MuseBodySignals({
    required this.ppg,
    required this.heartRate,
    required this.breathRate,
    required this.motionG,
    required this.gyroDps,
  });

  final String ppg;
  final int? heartRate;
  final int? breathRate;
  final double motionG;
  final double gyroDps;

  factory MuseBodySignals.fromJson(Map<String, dynamic> json) {
    return MuseBodySignals(
      ppg: _string(json['ppg'], fallback: 'Waiting'),
      heartRate: _int(json['heartRate']),
      breathRate: _int(json['breathRate']),
      motionG: _double(json['motionG'], fallback: .0),
      gyroDps: _double(json['gyroDps'], fallback: .0),
    );
  }
}

class MuseStreams {
  const MuseStreams({
    required this.eeg,
    required this.ppg,
    required this.acc,
    required this.gyro,
  });

  final bool eeg;
  final bool ppg;
  final bool acc;
  final bool gyro;

  factory MuseStreams.fromJson(Map<String, dynamic> json) {
    return MuseStreams(
      eeg: _bool(json['eeg']),
      ppg: _bool(json['ppg']),
      acc: _bool(json['acc']),
      gyro: _bool(json['gyro']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

String _string(Object? value, {required String fallback}) {
  return value is String && value.isNotEmpty ? value : fallback;
}

bool _bool(Object? value) {
  return value == true;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

double _double(Object? value, {required double fallback}) {
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
