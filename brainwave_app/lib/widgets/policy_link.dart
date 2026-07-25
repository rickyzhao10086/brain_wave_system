import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_links.dart';

/// A text link out to one of the [AppLinks] URLs.
///
/// Renders nothing while the URL is still a placeholder, so an unconfigured
/// link never ships as a button that opens a dead page.
class PolicyLink extends StatelessWidget {
  const PolicyLink({
    super.key,
    required this.label,
    required this.url,
    this.icon = Icons.open_in_new_rounded,
    this.color = const Color(0xff22d3ee),
  });

  const PolicyLink.privacy({Key? key})
    : this(
        key: key,
        label: 'Privacy policy',
        url: AppLinks.privacyPolicy,
        icon: Icons.privacy_tip_outlined,
      );

  final String label;
  final String url;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!AppLinks.isConfigured(url)) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: () => _open(context),
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 15, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      Uri.parse(url.trim()),
      mode: LaunchMode.externalApplication,
    ).catchError((Object _) => false);
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open $url'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
