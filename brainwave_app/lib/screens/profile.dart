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
        SectionTitle(title: 'Muse 2 Setup', action: 'Mock'),
        SizedBox(height: 10),
        _MeasurementsGrid(),
        SizedBox(height: 18),
        SectionTitle(title: 'Session Notes', action: 'Pending'),
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
            'Muse profile CS-2048',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .55),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _MiniMetric(label: 'Device', value: 'Muse 2'),
              ),
              Expanded(
                child: _MiniMetric(label: 'Mode', value: 'Care'),
              ),
              Expanded(
                child: _MiniMetric(label: 'Window', value: '30s'),
              ),
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
      (Icons.graphic_eq_rounded, 'EEG channels', '4 ch', Color(0xff22c55e)),
      (Icons.monitor_heart_rounded, 'PPG pulse', 'Ready', Color(0xffff4d6d)),
      (Icons.air_rounded, 'Breath pace', 'Ready', Color(0xff22d3ee)),
      (
        Icons.screen_rotation_alt_rounded,
        'IMU motion',
        'Ready',
        Color(0xff8b5cf6),
      ),
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
                  'Integration Note',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'This screen is prepared for Muse 2 session monitoring, but it is still frontend-only. Firebase auth, stored patient records, and live hardware streams should be added after the device integration is ready.',
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
          style: TextStyle(
            color: Colors.white.withValues(alpha: .55),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
