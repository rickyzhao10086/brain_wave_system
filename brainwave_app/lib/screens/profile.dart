import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/icon_badge.dart';
import '../widgets/neuro_panel.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_title.dart';
import '../widgets/status_pill.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenScaffold(
      children: [
        _ProfileHeader(),
        SizedBox(height: 18),
        _PatientCard(),
        SizedBox(height: 18),
        SectionTitle(title: 'Body Measurements', action: 'Updated'),
        SizedBox(height: 10),
        _MeasurementsGrid(),
        SizedBox(height: 18),
        SectionTitle(title: 'Care Notes', action: 'Patient'),
        SizedBox(height: 10),
        _DescriptionCard(),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),
        const StatusPill('Consent Active', color: Color(0xff22c55e)),
        IconButton(
          onPressed: () => AuthService.instance.signOut(),
          tooltip: 'Sign out',
          icon: Icon(
            Icons.logout_rounded,
            size: 20,
            color: Colors.white.withValues(alpha: .6),
          ),
        ),
      ],
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard();

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff8b5cf6), Color(0xff22d3ee)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.person_rounded, size: 52),
          ),
          const SizedBox(height: 12),
          Text(
            AuthService.instance.currentUser?.displayLabel ?? 'Patient',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Patient ID NM-2048',
            style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 12),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _MiniMetric(label: 'Age', value: '34')),
              Expanded(child: _MiniMetric(label: 'Height', value: '168 cm')),
              Expanded(child: _MiniMetric(label: 'Weight', value: '61 kg')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeasurementsGrid extends StatelessWidget {
  const _MeasurementsGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.monitor_heart_rounded, 'Resting HR', '72 bpm', Color(0xffff4d6d)),
      (Icons.air_rounded, 'Respiration', '15 rpm', Color(0xff22d3ee)),
      (Icons.bedtime_rounded, 'Sleep Avg', '7h 12m', Color(0xff8b5cf6)),
      (Icons.accessibility_new_rounded, 'BMI', '21.6', Color(0xff22c55e)),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        for (final item in items)
          NeuroPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(item.$1, color: item.$4),
                Text(
                  item.$3,
                  style: TextStyle(
                    color: item.$4,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  item.$2,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard();

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              IconBadge(
                icon: Icons.description_rounded,
                colors: [Color(0xff22c55e), Color(0xff14b8a6)],
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Therapist Summary',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Maya is monitored during guided relaxation sessions. Caregivers should respond when the mobile indicator shifts to yellow or red and review the desktop EEG features after each session.',
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

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

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
