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
          title: 'Muse 2 Feature Prep',
          subtitle: 'EEG bands, contact quality, PPG, and IMU artifacts',
          metricOne: '4 Sensors',
          metricTwo: 'EEG+Body',
          color: Color(0xff22d3ee),
        ),
        SizedBox(height: 10),
        _ModelInfoCard(
          icon: Icons.psychology_rounded,
          title: 'Session Classifier',
          subtitle: 'Maps clean sensor windows to calm, elevated, or review',
          metricOne: '3 States',
          metricTwo: 'Readiness',
          color: Color(0xff8b5cf6),
        ),
        SizedBox(height: 18),
        SectionTitle(title: 'LLM API', action: 'Pending'),
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
                  'Muse 2 Session Pipeline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Muse 2 signals are represented here as frontend mock data until hardware and Firebase are connected. The intended pipeline combines EEG band power, electrode contact, PPG pulse, breathing pace, and IMU artifact features before producing a session readiness label.',
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
                child: _Metric(label: 'Input', value: 'Muse 2'),
              ),
              Expanded(
                child: _Metric(label: 'Signals', value: '4'),
              ),
              Expanded(
                child: _Metric(label: 'Output', value: 'R/Y/G'),
              ),
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
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
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
                  'OpenAI Reasoning Placeholder',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              StatusPill('Pending', color: Color(0xfff59e0b)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Backend calls are intentionally held for now. When enabled, the API should receive compact Muse 2 feature summaries, not raw caregiver notes, and return a plain-language explanation for the readiness label.',
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
          style: TextStyle(
            color: Colors.white.withValues(alpha: .55),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
