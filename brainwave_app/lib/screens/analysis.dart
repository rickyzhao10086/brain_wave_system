import 'package:flutter/material.dart';

import '../painters/gauge_painter.dart';
import '../painters/trend_painter.dart';
import '../widgets/icon_badge.dart';
import '../widgets/neuro_panel.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_title.dart';
import '../widgets/status_pill.dart';

/// Analysis surfaces "how the health reading" of the wearer is derived: the
/// current predicted state with confidence, the per-band EEG power that drives
/// it, how the reading has trended, and the model's interpretation. The
/// per-band breakdown is intentionally unique to this screen — Home shows the
/// glanceable traffic light, this screen shows the evidence behind it.
class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  // Current reading. Calm → green traffic light, high confidence.
  static const _state = 'Calm';
  static const _stateColor = Color(0xff22c55e);
  static const _confidence = 0.91;

  @override
  Widget build(BuildContext context) {
    return const ScreenScaffold(
      children: [
        _AnalysisHeader(),
        SizedBox(height: 18),
        _ReadingHero(
          state: _state,
          color: _stateColor,
          confidence: _confidence,
        ),
        SizedBox(height: 12),
        _SignalQualityRow(),
        SizedBox(height: 18),
        SectionTitle(title: 'EEG Band Power', action: 'Relative'),
        SizedBox(height: 10),
        _BandPowerCard(),
        SizedBox(height: 18),
        SectionTitle(title: 'State Trend', action: 'Last 30m'),
        SizedBox(height: 10),
        _TrendCard(color: _stateColor),
        SizedBox(height: 18),
        SectionTitle(title: 'AI Interpretation', action: 'OpenAI'),
        SizedBox(height: 10),
        _InterpretationCard(),
      ],
    );
  }
}

class _AnalysisHeader extends StatelessWidget {
  const _AnalysisHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Analysis',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),
        StatusPill('Live', color: Color(0xff22c55e)),
      ],
    );
  }
}

/// The headline of the screen: a confidence ring around the current state,
/// followed by the traffic-light scale with the active light highlighted.
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
          _TrafficScale(activeColor: color),
        ],
      ),
    );
  }
}

/// The green / yellow / red scale; the active light glows, the rest dim.
class _TrafficScale extends StatelessWidget {
  const _TrafficScale({required this.activeColor});

  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    const lights = [
      ('Calm', Color(0xff22c55e)),
      ('Elevated', Color(0xfff59e0b)),
      ('Distress', Color(0xffff4d6d)),
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
                ? [BoxShadow(color: color.withValues(alpha: .55), blurRadius: 12)]
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

/// Quality of the underlying MUSE 2 capture — how trustworthy this reading is.
class _SignalQualityRow extends StatelessWidget {
  const _SignalQualityRow();

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('98%', 'Signal'),
      ('256Hz', 'Sample'),
      ('4 ch', 'Electrodes'),
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

/// The five EEG frequency bands the desktop app computes from the stream —
/// the evidence the model turns into a state. Alpha dominance here is what
/// reads as "calm".
class _BandPowerCard extends StatelessWidget {
  const _BandPowerCard();

  @override
  Widget build(BuildContext context) {
    return const NeuroPanel(
      child: Column(
        children: [
          _BandRow(
            name: 'Delta',
            range: '0.5–4 Hz',
            value: .30,
            color: Color(0xff60a5fa),
          ),
          _BandRow(
            name: 'Theta',
            range: '4–8 Hz',
            value: .42,
            color: Color(0xff8b5cf6),
          ),
          _BandRow(
            name: 'Alpha',
            range: '8–13 Hz',
            value: .78,
            color: Color(0xff22c55e),
            dominant: true,
          ),
          _BandRow(
            name: 'Beta',
            range: '13–30 Hz',
            value: .35,
            color: Color(0xff22d3ee),
          ),
          _BandRow(
            name: 'Gamma',
            range: '30–50 Hz',
            value: .18,
            color: Color(0xffd946ef),
            last: true,
          ),
        ],
      ),
    );
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

/// The model's plain-language reading — what the bands mean for the wearer.
class _InterpretationCard extends StatelessWidget {
  const _InterpretationCard();

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              IconBadge(
                icon: Icons.auto_awesome_rounded,
                colors: [Color(0xff22c55e), Color(0xff22d3ee)],
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Reading Summary',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              StatusPill('Synced', color: Color(0xff22c55e)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Alpha power is dominant while beta and gamma stay low, which the '
            'model reads as a relaxed, settled state. No spikes in the higher '
            'bands that would point to elevation or distress, so the traffic '
            'light is held at green with high confidence.',
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
}
