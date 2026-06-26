import 'package:flutter/material.dart';

import '../painters/brain_map_painter.dart';
import '../painters/signal_painter.dart';
import '../painters/trend_painter.dart';
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
        _PatientStatusCard(),
        SizedBox(height: 12),
        _StatsRow(),
        SizedBox(height: 18),
        SectionTitle(title: 'Recent EEG Readings', action: 'Live'),
        SizedBox(height: 10),
        _ReadingsCard(),
        SizedBox(height: 18),
        SectionTitle(title: 'Signal Trace', action: 'MUSE 2'),
        SizedBox(height: 10),
        _SignalCard(),
        SizedBox(height: 18),
        SectionTitle(title: 'Brain Activity Map', action: 'Details'),
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
                'Good Morning',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .58),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'NeuroMotion',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const IconBadge(
          icon: Icons.psychology_alt_rounded,
          colors: [Color(0xff17d6c0), Color(0xff8b5cf6)],
        ),
      ],
    );
  }
}

class _PatientStatusCard extends StatelessWidget {
  const _PatientStatusCard();

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Row(
        children: [
          const IconBadge(
            icon: Icons.sentiment_satisfied_alt_rounded,
            colors: [Color(0xff22c55e), Color(0xff14b8a6)],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Patient Status',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'Calm state detected from latest EEG window',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .58),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Green',
                style: TextStyle(
                  color: Color(0xff22c55e),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Traffic Light',
                style: TextStyle(color: Color(0xff8792a8), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('18', 'Sessions'),
      ('74', 'Calm %'),
      ('6m', 'Latest'),
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
                    Text(
                      stat.$1,
                      style: const TextStyle(
                        color: Color(0xff8b5cf6),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
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

class _ReadingsCard extends StatelessWidget {
  const _ReadingsCard();

  @override
  Widget build(BuildContext context) {
    return const NeuroPanel(
      child: Column(
        children: [
          _ReadingRow(
            label: 'Calm',
            value: .74,
            color: Color(0xff22c55e),
            time: 'Now',
          ),
          _ReadingRow(
            label: 'Elevated',
            value: .19,
            color: Color(0xfff59e0b),
            time: '12:43 PM',
          ),
          _ReadingRow(
            label: 'Distress',
            value: .07,
            color: Color(0xffff4d6d),
            time: '12:38 PM',
          ),
        ],
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({
    required this.label,
    required this.value,
    required this.color,
    required this.time,
  });

  final String label;
  final double value;
  final Color color;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: const Icon(Icons.circle, size: 9, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(value * 100).round()}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  color: color,
                  backgroundColor: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .44),
              fontSize: 10,
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
            CustomPaint(
              size: Size.infinite,
              painter: const BrainMapPainter(),
            ),
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
