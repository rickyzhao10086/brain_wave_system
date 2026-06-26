import 'package:flutter/material.dart';

import '../widgets/icon_badge.dart';
import '../widgets/neuro_panel.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_title.dart';
import '../widgets/status_pill.dart';

class ModelScreen extends StatelessWidget {
  const ModelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenScaffold(
      children: [
        _ModelHeader(),
        SizedBox(height: 18),
        _PipelineCard(),
        SizedBox(height: 18),
        SectionTitle(title: 'Desktop Models', action: 'Python'),
        SizedBox(height: 10),
        _ModelInfoCard(
          icon: Icons.filter_alt_rounded,
          title: 'Signal Processing',
          subtitle: 'MUSE 2 stream filtering and band power extraction',
          metricOne: '5 Bands',
          metricTwo: 'Delta-Gamma',
          color: Color(0xff22d3ee),
        ),
        SizedBox(height: 10),
        _ModelInfoCard(
          icon: Icons.psychology_rounded,
          title: 'State Classifier',
          subtitle: 'Maps EEG features to calm, elevated, or distress',
          metricOne: '3 States',
          metricTwo: 'Traffic Light',
          color: Color(0xff8b5cf6),
        ),
        SizedBox(height: 18),
        SectionTitle(title: 'LLM API', action: 'OpenAI'),
        SizedBox(height: 10),
        _OpenAiCard(),
      ],
    );
  }
}

class _ModelHeader extends StatelessWidget {
  const _ModelHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Model',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),
        const StatusPill('Active', color: Color(0xff22c55e)),
      ],
    );
  }
}

class _PipelineCard extends StatelessWidget {
  const _PipelineCard();

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              IconBadge(
                icon: Icons.account_tree_rounded,
                colors: [Color(0xff17d6c0), Color(0xff8b5cf6)],
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'EEG State Pipeline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'MUSE 2 signals are filtered in the desktop app, converted into EEG band-power features, then sent to the OpenAI API for a patient-state prediction.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _Metric(label: 'Input', value: 'MUSE 2')),
              Expanded(child: _Metric(label: 'Bands', value: '5')),
              Expanded(child: _Metric(label: 'Output', value: 'R/Y/G')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelInfoCard extends StatelessWidget {
  const _ModelInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.metricOne,
    required this.metricTwo,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String metricOne;
  final String metricTwo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Row(
        children: [
          IconBadge(icon: icon, colors: [color, const Color(0xff111827)]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .58),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metricOne,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                metricTwo,
                style: const TextStyle(color: Color(0xff8792a8), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpenAiCard extends StatelessWidget {
  const _OpenAiCard();

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Column(
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
                  'OpenAI State Reasoning',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              StatusPill('Online', color: Color(0xff22c55e)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'The API receives compact EEG features, not raw caregiver notes, and returns a predicted state label for the mobile traffic-light display.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

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
          style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 10),
        ),
      ],
    );
  }
}
