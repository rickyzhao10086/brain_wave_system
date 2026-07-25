/// External URLs the app links out to.
///
/// These are the same URLs submitted to App Store Connect and the Play Console
/// store listing — keep the two in sync. Both stores require a privacy policy
/// that is publicly reachable without signing in.
///
/// PASTE THE LIVE URLS HERE. Until a value stops being a placeholder, the
/// widgets that link to it hide themselves rather than open a dead page, so a
/// forgotten URL shows up as a missing link instead of a broken one.
class AppLinks {
  const AppLinks._();

  /// Privacy policy. Required by both stores because CerebroSync creates
  /// accounts and stores EEG-derived session data.
  static const String privacyPolicy =
      'https://doc-hosting.flycricket.io/skate-sensor-privacy-policy/d569a3ae-a671-4d03-b14d-87981b3a3735/privacy';

  /// Support page or contact form. Required by App Store Connect.
  static const String support = 'https://codingmind.com';

  static bool get hasPrivacyPolicy => isConfigured(privacyPolicy);
  static bool get hasSupport => isConfigured(support);

  /// A URL counts as configured once it is a real https link that no longer
  /// carries the placeholder markers above. Tolerates stray whitespace so a
  /// pasted URL does not silently disable its own link.
  static bool isConfigured(String url) {
    final clean = url.trim();
    return clean.startsWith('https://') &&
        !clean.contains('TODO') &&
        !clean.contains('example.com');
  }
}
