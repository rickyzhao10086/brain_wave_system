import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firebase_data_service.dart';
import '../widgets/icon_badge.dart';
import '../widgets/neuro_panel.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_title.dart';
import '../widgets/status_pill.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  String _careMode = 'Care';
  int _sessionWindowSeconds = 30;
  bool _consentActive = true;
  bool _saving = false;
  bool _dirty = false;
  String? _loadedSignature;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FirebaseDataService.instance,
      builder: (context, _) {
        final data = FirebaseDataService.instance;
        final profile = data.profile;
        _syncFields(profile);
        return ScreenScaffold(
          children: [
            _ProfileHeader(data: data),
            const SizedBox(height: 18),
            _AccountCard(profile: profile),
            const SizedBox(height: 18),
            SectionTitle(
              title: 'Data Controls',
              action: _syncLabel(data.status),
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              name: _name,
              notes: _notes,
              careMode: _careMode,
              sessionWindowSeconds: _sessionWindowSeconds,
              consentActive: _consentActive,
              saving: _saving,
              onChanged: () => setState(() => _dirty = true),
              onCareModeChanged: (value) {
                setState(() {
                  _careMode = value;
                  _dirty = true;
                });
              },
              onWindowChanged: (value) {
                setState(() {
                  _sessionWindowSeconds = value;
                  _dirty = true;
                });
              },
              onConsentChanged: (value) {
                setState(() {
                  _consentActive = value;
                  _dirty = true;
                });
              },
              onSave: _save,
            ),
            if (data.lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                data.lastError!,
                style: const TextStyle(color: Color(0xffff8ca1), fontSize: 11),
              ),
            ],
            const SizedBox(height: 18),
            const SectionTitle(title: 'Muse 2 Setup', action: 'On device'),
            const SizedBox(height: 10),
            const _MeasurementsGrid(),
            const SizedBox(height: 18),
            SectionTitle(
              title: 'Session History',
              action: '${data.sessionCount} synced',
            ),
            const SizedBox(height: 10),
            _SessionHistoryCard(sessions: data.recentSessions),
          ],
        );
      },
    );
  }

  void _syncFields(CerebroProfile profile) {
    final signature = [
      profile.uid,
      profile.displayName,
      profile.careMode,
      profile.sessionWindowSeconds,
      profile.consentActive,
      profile.sessionNote,
    ].join('|');
    if (_dirty || signature == _loadedSignature) return;
    _loadedSignature = signature;
    _name.text = profile.displayName;
    _notes.text = profile.sessionNote;
    _careMode = profile.careMode;
    _sessionWindowSeconds = profile.sessionWindowSeconds;
    _consentActive = profile.consentActive;
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _showMessage('Enter a display name.');
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateDisplayName(_name.text);
      await FirebaseDataService.instance.saveProfile(
        displayName: _name.text,
        consentActive: _consentActive,
        careMode: _careMode,
        sessionWindowSeconds: _sessionWindowSeconds,
        sessionNote: _notes.text,
      );
      if (!mounted) return;
      setState(() => _dirty = false);
      _showMessage('Profile and recording preferences saved.');
    } on AuthServiceException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'Could not save your profile. Check Firebase rules and retry.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static String _syncLabel(FirebaseSyncStatus status) => switch (status) {
    FirebaseSyncStatus.ready => 'Synced',
    FirebaseSyncStatus.syncing => 'Syncing',
    FirebaseSyncStatus.error => 'Error',
    FirebaseSyncStatus.unavailable => 'Offline',
  };
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.data});

  final FirebaseDataService data;

  @override
  Widget build(BuildContext context) {
    final consent = data.profile.consentActive;
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),
        StatusPill(
          consent ? 'Consent Active' : 'Local Only',
          color: consent ? const Color(0xff22c55e) : const Color(0xfff59e0b),
        ),
        IconButton(
          onPressed: AuthService.instance.signOut,
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

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.profile});

  final CerebroProfile profile;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final verified = user?.emailVerified == true;
    return NeuroPanel(
      child: Column(
        children: [
          const IconBadge(
            icon: Icons.person_rounded,
            colors: [Color(0xff8b5cf6), Color(0xff22d3ee)],
            size: 72,
          ),
          const SizedBox(height: 12),
          Text(
            profile.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .55),
              fontSize: 12,
            ),
          ),
          if (!verified) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _resendVerification(context),
              icon: const Icon(Icons.mark_email_unread_rounded, size: 17),
              label: const Text('Resend verification email'),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Device',
                  value: profile.preferredDeviceName ?? 'Muse 2',
                ),
              ),
              Expanded(
                child: _MiniMetric(label: 'Mode', value: profile.careMode),
              ),
              Expanded(
                child: _MiniMetric(
                  label: 'Window',
                  value: '${profile.sessionWindowSeconds}s',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _resendVerification(BuildContext context) async {
    try {
      await AuthService.instance.resendEmailVerification();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthServiceException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.name,
    required this.notes,
    required this.careMode,
    required this.sessionWindowSeconds,
    required this.consentActive,
    required this.saving,
    required this.onChanged,
    required this.onCareModeChanged,
    required this.onWindowChanged,
    required this.onConsentChanged,
    required this.onSave,
  });

  final TextEditingController name;
  final TextEditingController notes;
  final String careMode;
  final int sessionWindowSeconds;
  final bool consentActive;
  final bool saving;
  final VoidCallback onChanged;
  final ValueChanged<String> onCareModeChanged;
  final ValueChanged<int> onWindowChanged;
  final ValueChanged<bool> onConsentChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: name,
            onChanged: (_) => onChanged(),
            decoration: _decoration('Display name', Icons.badge_rounded),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: careMode,
            decoration: _decoration('Session mode', Icons.tune_rounded),
            items: const [
              DropdownMenuItem(value: 'Care', child: Text('Care')),
              DropdownMenuItem(value: 'Self', child: Text('Self')),
              DropdownMenuItem(value: 'Research', child: Text('Research')),
            ],
            onChanged: saving
                ? null
                : (value) {
                    if (value != null) onCareModeChanged(value);
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: sessionWindowSeconds,
            decoration: _decoration('Analysis window', Icons.timelapse_rounded),
            items: const [
              DropdownMenuItem(value: 15, child: Text('15 seconds')),
              DropdownMenuItem(value: 30, child: Text('30 seconds')),
              DropdownMenuItem(value: 60, child: Text('60 seconds')),
            ],
            onChanged: saving
                ? null
                : (value) {
                    if (value != null) onWindowChanged(value);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            onChanged: (_) => onChanged(),
            maxLength: 1000,
            minLines: 3,
            maxLines: 5,
            decoration: _decoration('Session notes', Icons.description_rounded)
                .copyWith(
                  hintText: 'Context that should accompany future sessions',
                ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Cloud session recording',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                consentActive
                    ? 'Summary checkpoints sync once per minute.'
                    : 'Muse processing stays on this phone.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .5),
                  fontSize: 10,
                ),
              ),
              value: consentActive,
              onChanged: saving ? null : onConsentChanged,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded, size: 18),
              label: Text(saving ? 'Saving...' : 'Save settings'),
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: const Color(0xff0f111c),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
      (
        Icons.battery_charging_full_rounded,
        'Telemetry',
        'Ready',
        Color(0xff22d3ee),
      ),
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

class _SessionHistoryCard extends StatelessWidget {
  const _SessionHistoryCard({required this.sessions});

  final List<SessionSummary> sessions;

  @override
  Widget build(BuildContext context) {
    return NeuroPanel(
      child: sessions.isEmpty
          ? Text(
              'No cloud sessions yet. Connect a Muse 2 while cloud recording is enabled.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .55),
                fontSize: 11,
                height: 1.35,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < sessions.take(5).length; index++)
                  _SessionRow(
                    session: sessions[index],
                    last: index == sessions.take(5).length - 1,
                  ),
              ],
            ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.last});

  final SessionSummary session;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          Icon(
            session.status == 'active'
                ? Icons.sync_rounded
                : Icons.check_circle_outline_rounded,
            color: session.status == 'active'
                ? const Color(0xff22d3ee)
                : const Color(0xff22c55e),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(session.startedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${session.sampleCount} checkpoints',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .48),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            session.state,
            style: const TextStyle(
              color: Color(0xff22d3ee),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Syncing session time';
    final local = date.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year}  $hour:$minute $period';
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
        FittedBox(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xff22d3ee),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
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
