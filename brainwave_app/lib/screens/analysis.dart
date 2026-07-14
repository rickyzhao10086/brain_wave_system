import 'package:flutter/material.dart';

import '../painters/gauge_painter.dart';
import '../painters/trend_painter.dart';
import '../services/muse_live_service.dart';
import '../widgets/icon_badge.dart';
import '../widgets/neuro_panel.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_title.dart';
import '../widgets/status_pill.dart';

/// Analysis surfaces the Muse 2 evidence behind the session state: EEG band
/// power, contact quality, motion artifacts, PPG, breathing pace, and the
/// model's non-clinical interpretation.
class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MuseLiveService.instance,
      builder: (context, _) {
        final service = MuseLiveService.instance;
        final snapshot = service.snapshot;
        final stateColor = _stateColor(snapshot.state.label);
        return ScreenScaffold(
          children: [
            _AnalysisHeader(
              isLive: service.isLive,
              sourceLabel: service.sourceLabel,
            ),
            const SizedBox(height: 18),
            _ReadingHero(
              state: snapshot.state.label,
              color: stateColor,
              confidence: snapshot.state.confidence,
            ),
            const SizedBox(height: 12),
            _MuseQualityRow(snapshot: snapshot),
            const SizedBox(height: 18),
            const SectionTitle(
              title: 'Muse 2 Body Signals',
              action: 'PPG + IMU',
            ),
            const SizedBox(height: 10),
            _MuseBodySignalsCard(snapshot: snapshot),
            const SizedBox(height: 18),
            SectionTitle(
              title: 'EEG Band Power',
              action: service.isLive ? 'Live' : 'Relative',
            ),
            const SizedBox(height: 10),
            _BandPowerCard(bands: snapshot.bands),
            const SizedBox(height: 18),
            const SectionTitle(title: 'State Trend', action: 'Last 30m'),
            const SizedBox(height: 10),
            _TrendCard(color: stateColor),
            const SizedBox(height: 18),
            SectionTitle(
              title: 'Session Interpretation',
              action: service.sourceLabel,
            ),
            const SizedBox(height: 10),
            _InterpretationCard(
              snapshot: snapshot,
              isLive: service.isLive,
              sourceLabel: service.sourceLabel,
            ),
          ],
        );
      },
    );
  }

  static Color _stateColor(String state) {
    return switch (state.toLowerCase()) {
      'calm' => const Color(0xff22c55e),
      'elevated' => const Color(0xfff59e0b),
      _ => const Color(0xffff4d6d),
    };
  }
}

class _AnalysisHeader extends StatelessWidget {
  const _AnalysisHeader({required this.isLive, required this.sourceLabel});

  final bool isLive;
  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Analysis',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),
        StatusPill(
          isLive ? sourceLabel : 'Mock',
          color: isLive ? const Color(0xff22c55e) : const Color(0xfff59e0b),
        ),
      ],
    );
  }
}

/// The headline of the screen: a confidence ring around the current state,
/// followed by the readiness scale with the active light highlighted.
class _ReadingHero extends StatelessWidget {
  const _ReadingHero({
    required this.state,
    required this.color,
    required this.confidence,
  });

  final String state;
  final Color color;
  final double confidence;

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Current Reading',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .58),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const StatusPill('Stable', color: Color(0xff22d3ee)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 156,
            width: 156,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(156),
                  painter: GaugePainter(value: confidence, color: color),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(confidence * 100).round()}% confidence',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ReadinessScale(activeColor: color),
        ],
      ),
    );
  }
}

/// The green / yellow / red scale; red means the sample needs review, not a
/// clinical diagnosis.
class _ReadinessScale extends StatelessWidget {
  const _ReadinessScale({required this.activeColor});

  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    const lights = [
      ('Calm', Color(0xff22c55e)),
      ('Elevated', Color(0xfff59e0b)),
      ('Review', Color(0xffff4d6d)),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final light in lights)
          _TrafficLight(
            label: light.$1,
            color: light.$2,
            active: light.$2 == activeColor,
          ),
      ],
    );
  }
}

class _TrafficLight extends StatelessWidget {
  const _TrafficLight({
    required this.label,
    required this.color,
    required this.active,
  });

  final String label;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: .22),
            shape: BoxShape.circle,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: .55),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? color : Colors.white.withValues(alpha: .4),
            fontSize: 10,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Quality of the underlying Muse 2 capture - how trustworthy this reading is.
class _MuseQualityRow extends StatelessWidget {
  const _MuseQualityRow({required this.snapshot});

  final MuseSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final minContact = snapshot.contact.values.reduce((a, b) => a < b ? a : b);
    final stats = [
      ('${(minContact * 100).round()}%', 'Contact'),
      (
        snapshot.sampleRate == null ? '--' : '${snapshot.sampleRate}Hz',
        'Sample',
      ),
      (snapshot.state.artifact, 'Artifact'),
    ];

    return Row(
      children: [
        for (final stat in stats)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: NeuroPanel(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    FittedBox(
                      child: Text(
                        stat.$1,
                        style: const TextStyle(
                          color: Color(0xff22d3ee),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stat.$2,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .56),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MuseBodySignalsCard extends StatelessWidget {
  const _MuseBodySignalsCard({required this.snapshot});

  final MuseSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final body = snapshot.body;
    return NeuroPanel(
      child: Column(
        children: [
          _BodySignalRow(
            icon: Icons.monitor_heart_rounded,
            label: 'PPG pulse',
            value: body.heartRate == null ? body.ppg : '${body.heartRate} bpm',
            detail: snapshot.streams.ppg ? 'Live waveform' : 'Waiting for PPG',
            color: const Color(0xffff4d6d),
          ),
          const SizedBox(height: 12),
          _BodySignalRow(
            icon: Icons.air_rounded,
            label: 'Breathing pace',
            value: body.breathRate == null
                ? '-- rpm'
                : '${body.breathRate} rpm',
            detail: snapshot.streams.acc
                ? 'Motion-derived estimate'
                : 'Waiting for ACC',
            color: const Color(0xff22d3ee),
          ),
          const SizedBox(height: 12),
          _BodySignalRow(
            icon: Icons.screen_rotation_alt_rounded,
            label: 'Head motion',
            value: '${body.motionG.toStringAsFixed(2)} g',
            detail: body.motionG < .08 ? 'Low acceleration' : 'Motion artifact',
            color: const Color(0xff8b5cf6),
          ),
          const SizedBox(height: 12),
          _BodySignalRow(
            icon: Icons.threesixty_rounded,
            label: 'Gyroscope',
            value: '${body.gyroDps.toStringAsFixed(1)} dps',
            detail: body.gyroDps < 5
                ? 'No rotation artifact'
                : 'Rotation artifact',
            color: const Color(0xfff59e0b),
          ),
        ],
      ),
    );
  }
}

class _BodySignalRow extends StatelessWidget {
  const _BodySignalRow({
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

/// The five EEG frequency bands the desktop app computes from the stream -
/// the evidence the model turns into a state. Alpha dominance here is what
/// reads as "calm".
class _BandPowerCard extends StatelessWidget {
  const _BandPowerCard({required this.bands});

  final MuseBands bands;

  @override
  Widget build(BuildContext context) {
    final strongest = _strongestBand(bands);
    return NeuroPanel(
      child: Column(
        children: [
          _BandRow(
            name: 'Delta',
            range: '0.5-4 Hz',
            value: bands.delta,
            color: const Color(0xff60a5fa),
            dominant: strongest == 'Delta',
          ),
          _BandRow(
            name: 'Theta',
            range: '4-8 Hz',
            value: bands.theta,
            color: const Color(0xff8b5cf6),
            dominant: strongest == 'Theta',
          ),
          _BandRow(
            name: 'Alpha',
            range: '8-13 Hz',
            value: bands.alpha,
            color: const Color(0xff22c55e),
            dominant: strongest == 'Alpha',
          ),
          _BandRow(
            name: 'Beta',
            range: '13-30 Hz',
            value: bands.beta,
            color: const Color(0xff22d3ee),
            dominant: strongest == 'Beta',
          ),
          _BandRow(
            name: 'Gamma',
            range: '30-50 Hz',
            value: bands.gamma,
            color: const Color(0xffd946ef),
            dominant: strongest == 'Gamma',
            last: true,
          ),
        ],
      ),
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
    return values.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

class _BandRow extends StatelessWidget {
  const _BandRow({
    required this.name,
    required this.range,
    required this.value,
    required this.color,
    this.dominant = false,
    this.last = false,
  });

  final String name;
  final String range;
  final double value;
  final Color color;
  final bool dominant;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          SizedBox(
            width: 66,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (dominant) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.star_rounded, size: 11, color: color),
                    ],
                  ],
                ),
                Text(
                  range,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .42),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              color: color,
              backgroundColor: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
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

/// How the reading has moved across the recent window.
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text(
                'Calm index',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(painter: TrendPainter(color: color)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in ['30m', '20m', '10m', 'Now'])
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .4),
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The model's plain-language reading - what the bands mean for the wearer.
class _InterpretationCard extends StatelessWidget {
  const _InterpretationCard({
    required this.snapshot,
    required this.isLive,
    required this.sourceLabel,
  });

  final MuseSnapshot snapshot;
  final bool isLive;
  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.auto_awesome_rounded,
                colors: [Color(0xff22c55e), Color(0xff22d3ee)],
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Reading Summary',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              StatusPill(
                isLive ? sourceLabel : 'Mock',
                color: isLive
                    ? const Color(0xff22c55e)
                    : const Color(0xfff59e0b),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _summaryText(snapshot, isLive),
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  static String _summaryText(MuseSnapshot snapshot, bool isLive) {
    final source = isLive
        ? 'The live Muse stream reports'
        : 'The mock preview shows';
    final minContact = snapshot.contact.values.reduce((a, b) => a < b ? a : b);
    final contact = '${(minContact * 100).round()}% minimum contact';
    return '$source ${snapshot.state.label.toLowerCase()} with '
        '${(snapshot.state.confidence * 100).round()}% confidence, $contact, '
        'and ${snapshot.state.artifact.toLowerCase()} artifact. Treat this as '
        'a session-readiness signal until a validated classifier is added.';
  }
}
