import 'package:flutter/foundation.dart';

/// A signed-in user. The fields mirror what we'll read off Firebase's `User`
/// object so screens won't need to change when the real backend is wired in.
class AuthUser {
  const AuthUser({required this.uid, required this.email, this.displayName});

  final String uid;
  final String email;
  final String? displayName;

  /// Human-friendly name: the display name when set, otherwise the email
  /// handle (capitalised). Always non-empty for a signed-in user.
  String get displayLabel {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final handle = email.split('@').first;
    if (handle.isNotEmpty) {
      return handle[0].toUpperCase() + handle.substring(1);
    }
    return email;
  }
}

/// Authentication for NeuroMotion.
///
/// The intended backend is **Firebase Auth**, but it can't be provisioned yet
/// (the developer is in a region where Firebase setup is blocked for a few
/// weeks). Until then every method here BYPASSES the network and fakes a
/// successful result, so the rest of the app can be built and demoed.
///
/// When Firebase is ready:
///   1. add `firebase_core` + `firebase_auth` to pubspec and run FlutterFire,
///   2. replace each body marked `TODO(firebase)` with the matching call,
///   3. swap `currentUser`/`isSignedIn` to listen to `authStateChanges()`.
/// The public surface already matches FirebaseAuth, so callers stay untouched.
class AuthService extends ChangeNotifier {
  AuthService._();

  /// Single shared instance — stands in for `FirebaseAuth.instance`.
  static final AuthService instance = AuthService._();

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Fakes the round-trip latency of a real auth call so the UI's loading
  /// state is exercised. Delete once Firebase is handling the request.
  static const _fakeLatency = Duration(milliseconds: 900);

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(_fakeLatency);
    // TODO(firebase): await FirebaseAuth.instance
    //     .signInWithEmailAndPassword(email: email, password: password);
    _currentUser = AuthUser(uid: _localUid(email), email: email.trim());
    notifyListeners();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(_fakeLatency);
    // TODO(firebase): create the user, then user.updateDisplayName(name):
    //   final cred = await FirebaseAuth.instance
    //       .createUserWithEmailAndPassword(email: email, password: password);
    //   await cred.user?.updateDisplayName(name);
    _currentUser = AuthUser(
      uid: _localUid(email),
      email: email.trim(),
      displayName: name.trim(),
    );
    notifyListeners();
  }

  /// "Skip for now" — lets the team use the app before any account exists.
  Future<void> continueAsGuest() async {
    // TODO(firebase): await FirebaseAuth.instance.signInAnonymously();
    _currentUser = const AuthUser(
      uid: 'guest',
      email: 'guest@neuromotion.local',
      displayName: 'Guest',
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    // TODO(firebase): await FirebaseAuth.instance.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Deterministic placeholder uid so the same email maps to the same "user"
  /// within a session. Replaced by Firebase's real uid later.
  String _localUid(String email) =>
      'local-${email.trim().toLowerCase().hashCode}';
}
