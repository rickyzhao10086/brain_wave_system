import 'package:flutter/material.dart';

import '../painters/brain_map_painter.dart';
import '../painters/signal_painter.dart';
import '../painters/trend_painter.dart';
import '../services/auth_service.dart';
import '../widgets/icon_badge.dart';
import '../widgets/neuro_panel.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_title.dart';
import '../widgets/status_pill.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenScaffold(
      children: [
        _HomeHeader(),
        SizedBox(height: 18),
        _MuseSessionCard(),
        SizedBox(height: 18),
        SectionTitle(title: 'Electrode Contact', action: 'Muse 2'),
        SizedBox(height: 10),
        _ContactQualityCard(),
        SizedBox(height: 18),
        SectionTitle(title: 'Live Sensor Snapshot', action: 'Mock'),
        SizedBox(height: 10),
        _MuseSensorGrid(),
        SizedBox(height: 18),
        SectionTitle(title: 'EEG Trace', action: '4 ch'),
        SizedBox(height: 10),
        _SignalCard(),
        SizedBox(height: 18),
        SectionTitle(title: 'Headband Map', action: 'Contact'),
        SizedBox(height: 10),
        _BrainMapCard(),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Muse 2 Session',
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
  const _MuseSessionCard();

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              IconBadge(
                icon: Icons.bluetooth_connected_rounded,
                colors: [Color(0xff22c55e), Color(0xff14b8a6)],
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Muse 2 Ready',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              StatusPill('Frontend Mock', color: Color(0xfff59e0b)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Signal preview is tailored to Muse 2 EEG, PPG, accelerometer, and gyroscope streams. Hardware and Firebase are pending, so values are representative placeholders.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _SessionMetric(label: 'Battery', value: '82%'),
              ),
              Expanded(
                child: _SessionMetric(label: 'Stream', value: '256Hz'),
              ),
              Expanded(
                child: _SessionMetric(label: 'Artifact', value: 'Low'),
              ),
            ],
          ),
        ],
      ),
    );
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
  const _ContactQualityCard();

  @override
  Widget build(BuildContext context) {
    return const NeuroPanel(
      child: Column(
        children: [
          _ContactRow(label: 'TP9', description: 'Left ear', value: .92),
          _ContactRow(label: 'AF7', description: 'Left forehead', value: .86),
          _ContactRow(label: 'AF8', description: 'Right forehead', value: .89),
          _ContactRow(
            label: 'TP10',
            description: 'Right ear',
            value: .95,
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
  const _MuseSensorGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      _MuseSensorData(
        icon: Icons.graphic_eq_rounded,
        label: 'EEG',
        value: 'Alpha up',
        detail: 'Bands stable',
        color: Color(0xff22c55e),
      ),
      _MuseSensorData(
        icon: Icons.monitor_heart_rounded,
        label: 'PPG',
        value: '72 bpm',
        detail: 'Pulse clean',
        color: Color(0xffff4d6d),
      ),
      _MuseSensorData(
        icon: Icons.air_rounded,
        label: 'Breath',
        value: '15 rpm',
        detail: 'Even pace',
        color: Color(0xff22d3ee),
      ),
      _MuseSensorData(
        icon: Icons.screen_rotation_alt_rounded,
        label: 'IMU',
        value: 'Still',
        detail: 'Motion low',
        color: Color(0xff8b5cf6),
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
