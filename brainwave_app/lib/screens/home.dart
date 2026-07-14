import 'package:flutter/material.dart';

import '../painters/brain_map_painter.dart';
import '../painters/signal_painter.dart';
import '../painters/trend_painter.dart';
import '../services/auth_service.dart';
import '../services/muse_live_service.dart';
import '../widgets/icon_badge.dart';
import '../widgets/neuro_panel.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_title.dart';
import '../widgets/status_pill.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MuseLiveService.instance,
      builder: (context, _) {
        final service = MuseLiveService.instance;
        final snapshot = service.snapshot;
        return ScreenScaffold(
          children: [
            _HomeHeader(isLive: service.isLive),
            const SizedBox(height: 18),
            _MuseSessionCard(service: service, snapshot: snapshot),
            const SizedBox(height: 18),
            SectionTitle(
              title: 'Electrode Contact',
              action: service.isLive ? 'Live' : 'Muse 2',
            ),
            const SizedBox(height: 10),
            _ContactQualityCard(contact: snapshot.contact),
            const SizedBox(height: 18),
            SectionTitle(
              title: 'Live Sensor Snapshot',
              action: service.sourceLabel,
            ),
            const SizedBox(height: 10),
            _MuseSensorGrid(snapshot: snapshot),
            const SizedBox(height: 18),
            const SectionTitle(title: 'EEG Trace', action: '4 ch'),
            const SizedBox(height: 10),
            const _SignalCard(),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Headband Map', action: 'Contact'),
            const SizedBox(height: 10),
            const _BrainMapCard(),
          ],
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLive ? 'Muse 2 Live Session' : 'Muse 2 Session',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .58),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _greetingName(AuthService.instance.currentUser),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const IconBadge(
          icon: Icons.sensors_rounded,
          colors: [Color(0xff17d6c0), Color(0xff8b5cf6)],
        ),
      ],
    );
  }

  static String _greetingName(AuthUser? user) {
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final email = user?.email ?? '';
    if (email.contains('@')) {
      final handle = email.split('@').first;
      if (handle.isNotEmpty) {
        return handle[0].toUpperCase() + handle.substring(1);
      }
    }
    return 'there';
  }
}

class _MuseSessionCard extends StatelessWidget {
  const _MuseSessionCard({required this.service, required this.snapshot});

  final MuseLiveService service;
  final MuseSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.bluetooth_connected_rounded,
                colors: [Color(0xff22c55e), Color(0xff14b8a6)],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.isLive
                      ? '${service.deviceName ?? 'Muse 2'} Streaming'
                      : 'Muse 2 Ready',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(
                _statusText(service.status),
                color: _statusColor(service.status),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            service.isLive
                ? service.source == MuseDataSource.directBle
                      ? 'Connected directly to the headband. EEG, PPG, accelerometer, gyroscope, and telemetry packets are being decoded on this phone.'
                      : 'Receiving Muse summaries from the local developer bridge.'
                : 'Turn on your Muse 2, keep it close to the phone, then scan. Disconnect MuseLSL or the Muse app first because only one Bluetooth client can use the headband.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SessionMetric(
                  label: 'Battery',
                  value: _batteryText(snapshot),
                ),
              ),
              Expanded(
                child: _SessionMetric(
                  label: 'Stream',
                  value: _sampleRateText(snapshot),
                ),
              ),
              Expanded(
                child: _SessionMetric(
                  label: 'Artifact',
                  value: snapshot.state.artifact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (service.errorMessage != null) ...[
            Text(
              service.errorMessage!,
              style: const TextStyle(
                color: Color(0xffff8ca1),
                fontSize: 11,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isBusy(service.status)
                  ? null
                  : service.isLive
                  ? service.disconnect
                  : service.connectDirect,
              icon: Icon(
                service.isLive
                    ? Icons.bluetooth_disabled_rounded
                    : Icons.bluetooth_searching_rounded,
                size: 18,
              ),
              label: Text(_primaryActionText(service)),
            ),
          ),
          if (!service.isLive) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isBusy(service.status)
                    ? null
                    : service.connectBridge,
                icon: const Icon(Icons.developer_mode_rounded, size: 17),
                label: const Text('Connect developer bridge'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _statusText(MuseConnectionStatus status) {
    return switch (status) {
      MuseConnectionStatus.live => 'Live',
      MuseConnectionStatus.scanning => 'Scanning',
      MuseConnectionStatus.connecting => 'Connecting',
      MuseConnectionStatus.offline => 'Offline',
      MuseConnectionStatus.mock => 'Mock',
    };
  }

  static Color _statusColor(MuseConnectionStatus status) {
    return switch (status) {
      MuseConnectionStatus.live => const Color(0xff22c55e),
      MuseConnectionStatus.scanning => const Color(0xff8b5cf6),
      MuseConnectionStatus.connecting => const Color(0xff22d3ee),
      MuseConnectionStatus.offline => const Color(0xffff4d6d),
      MuseConnectionStatus.mock => const Color(0xfff59e0b),
    };
  }

  static String _batteryText(MuseSnapshot snapshot) {
    final battery = snapshot.batteryPercent;
    return battery == null ? '--' : '$battery%';
  }

  static String _sampleRateText(MuseSnapshot snapshot) {
    final sampleRate = snapshot.sampleRate;
    return sampleRate == null ? '--' : '${sampleRate}Hz';
  }

  static bool _isBusy(MuseConnectionStatus status) {
    return status == MuseConnectionStatus.scanning ||
        status == MuseConnectionStatus.connecting;
  }

  static String _primaryActionText(MuseLiveService service) {
    return switch (service.status) {
      MuseConnectionStatus.scanning => 'Scanning for Muse 2...',
      MuseConnectionStatus.connecting => 'Setting up Muse sensors...',
      MuseConnectionStatus.live => 'Disconnect Muse 2',
      MuseConnectionStatus.offline => 'Retry direct connection',
      MuseConnectionStatus.mock => 'Scan for Muse 2',
    };
  }
}

class _SessionMetric extends StatelessWidget {
  const _SessionMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xff22d3ee),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .55),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ContactQualityCard extends StatelessWidget {
  const _ContactQualityCard({required this.contact});

  final Map<String, double> contact;

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Column(
        children: [
          _ContactRow(
            label: 'TP9',
            description: 'Left ear',
            value: contact['TP9'] ?? 0,
          ),
          _ContactRow(
            label: 'AF7',
            description: 'Left forehead',
            value: contact['AF7'] ?? 0,
          ),
          _ContactRow(
            label: 'AF8',
            description: 'Right forehead',
            value: contact['AF8'] ?? 0,
          ),
          _ContactRow(
            label: 'TP10',
            description: 'Right ear',
            value: contact['TP10'] ?? 0,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.label,
    required this.description,
    required this.value,
    this.last = false,
  });

  final String label;
  final String description;
  final double value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = value >= .9
        ? const Color(0xff22c55e)
        : value >= .75
        ? const Color(0xfff59e0b)
        : const Color(0xffff4d6d);

    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .5),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  color: color,
                  backgroundColor: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 38,
            child: Text(
              '${(value * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuseSensorGrid extends StatelessWidget {
  const _MuseSensorGrid({required this.snapshot});

  final MuseSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final body = snapshot.body;
    final bands = snapshot.bands;
    final strongestBand = _strongestBand(bands);
    final items = [
      _MuseSensorData(
        icon: Icons.graphic_eq_rounded,
        label: 'EEG',
        value: strongestBand,
        detail: snapshot.streams.eeg ? 'Live bands' : 'Bands ready',
        color: const Color(0xff22c55e),
      ),
      _MuseSensorData(
        icon: Icons.monitor_heart_rounded,
        label: 'PPG',
        value: body.heartRate == null ? body.ppg : '${body.heartRate} bpm',
        detail: snapshot.streams.ppg ? 'Live pulse' : 'Pulse ready',
        color: const Color(0xffff4d6d),
      ),
      _MuseSensorData(
        icon: Icons.air_rounded,
        label: 'Breath',
        value: body.breathRate == null ? '-- rpm' : '${body.breathRate} rpm',
        detail: snapshot.streams.acc ? 'Motion-derived' : 'Pace ready',
        color: const Color(0xff22d3ee),
      ),
      _MuseSensorData(
        icon: Icons.screen_rotation_alt_rounded,
        label: 'IMU',
        value: body.motionG < .08 ? 'Still' : 'Moving',
        detail: '${body.motionG.toStringAsFixed(2)} g',
        color: const Color(0xff8b5cf6),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [for (final item in items) _MuseSensorTile(data: item)],
    );
  }

  static String _strongestBand(MuseBands bands) {
    final values = {
      'Delta': bands.delta,
      'Theta': bands.theta,
      'Alpha': bands.alpha,
      'Beta': bands.beta,
      'Gamma': bands.gamma,
    };
    final strongest = values.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return '${strongest.key} up';
  }
}

class _MuseSensorData {
  const _MuseSensorData({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;
}

class _MuseSensorTile extends StatelessWidget {
  const _MuseSensorTile({required this.data});

  final _MuseSensorData data;

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(data.icon, color: data.color, size: 20),
              const Spacer(),
              Text(
                data.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            data.value,
            style: TextStyle(
              color: data.color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            data.detail,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .56),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard();

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: 116,
        width: double.infinity,
        child: CustomPaint(painter: const SignalPainter()),
      ),
    );
  }
}

class _BrainMapCard extends StatelessWidget {
  const _BrainMapCard();

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: SizedBox(
        height: 170,
        width: double.infinity,
        child: Stack(
          children: [
            CustomPaint(size: Size.infinite, painter: const BrainMapPainter()),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 44,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: const TrendPainter(color: Color(0xff22c55e)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
