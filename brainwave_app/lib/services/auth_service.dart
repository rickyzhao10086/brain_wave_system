import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.isAnonymous,
    required this.emailVerified,
    this.displayName,
  });

  final String uid;
  final String email;
  final String? displayName;
  final bool isAnonymous;
  final bool emailVerified;

  String get displayLabel {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (isAnonymous) return 'Guest';

    final handle = email.split('@').first;
    if (handle.isNotEmpty) {
      return handle[0].toUpperCase() + handle.substring(1);
    }
    return 'CerebroSync user';
  }
}

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  FirebaseAuth? _auth;
  AuthUser? _currentUser;
  Future<void> Function()? _beforeSignOut;
  Future<void> Function()? _onDeleteAccountData;

  AuthUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get isFirebaseReady => _auth != null;

  Future<void> initialize() async {
    if (_auth != null) return;
    final auth = FirebaseAuth.instance;
    if (auth.currentUser?.isAnonymous == true) {
      await auth.signOut();
    }
    _auth = auth;
    _currentUser = _mapUser(auth.currentUser);
    auth.userChanges().listen((user) {
      _currentUser = _mapUser(user);
      notifyListeners();
    });
    notifyListeners();
  }

  void registerBeforeSignOut(Future<void> Function() callback) {
    _beforeSignOut = callback;
  }

  /// Registers the step that erases the user's stored data during account
  /// deletion. It runs while the account is still signed in, because the
  /// Firestore rules only let the owner delete their own documents.
  ///
  /// The callback must throw if it cannot finish: [deleteAccount] treats a
  /// failure here as a reason to keep the account, so the user can retry
  /// instead of being left with data nobody can reach.
  void registerDeleteAccountData(Future<void> Function() callback) {
    _onDeleteAccountData = callback;
  }

  Future<void> signIn({required String email, required String password}) async {
    final auth = _auth;
    if (auth == null) {
      _setLocalUser(email: email);
      return;
    }

    try {
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error));
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      _setLocalUser(email: email, displayName: name);
      return;
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.sendEmailVerification();
      await credential.user?.reload();
      _currentUser = _mapUser(auth.currentUser);
      notifyListeners();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final auth = _auth;
    if (auth == null) return;
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error));
    }
  }

  Future<void> updateDisplayName(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const AuthServiceException('Enter a display name.');
    }
    final auth = _auth;
    if (auth == null) {
      final current = _currentUser;
      if (current == null) return;
      _currentUser = AuthUser(
        uid: current.uid,
        email: current.email,
        displayName: cleanName,
        isAnonymous: current.isAnonymous,
        emailVerified: current.emailVerified,
      );
      notifyListeners();
      return;
    }

    try {
      await auth.currentUser?.updateDisplayName(cleanName);
      await auth.currentUser?.reload();
      _currentUser = _mapUser(auth.currentUser);
      notifyListeners();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error));
    }
  }

  Future<void> resendEmailVerification() async {
    final user = _auth?.currentUser;
    if (user == null || user.isAnonymous || user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error));
    }
  }

  Future<void> signOut() async {
    await _beforeSignOut?.call();
    final auth = _auth;
    if (auth == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    await auth.signOut();
  }

  /// Permanently deletes the signed-in account and everything stored under it.
  ///
  /// Runs in a deliberate order:
  ///  1. Re-authenticate. Firebase requires a recent login before a delete, and
  ///     doing it first means a wrong password fails before any data is gone.
  ///  2. Erase the Firestore data, while the account still has permission to.
  ///  3. Delete the auth user last, so a failure at any earlier step leaves a
  ///     working account the user can retry with.
  ///
  /// Throws [AuthServiceException] if the password is wrong or the account
  /// cannot be deleted. Data-layer failures propagate from the callback
  /// registered through [registerDeleteAccountData].
  Future<void> deleteAccount({required String password}) async {
    final auth = _auth;
    if (auth == null) {
      // Firebase-less fallback, used by widget tests and by builds where
      // Firebase failed to start. There is no server-side account to remove.
      await _onDeleteAccountData?.call();
      _currentUser = null;
      notifyListeners();
      return;
    }

    final user = auth.currentUser;
    if (user == null) {
      throw const AuthServiceException('You are already signed out.');
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const AuthServiceException(
        'This account has no email address to confirm the deletion with.',
      );
    }
    if (password.isEmpty) {
      throw const AuthServiceException('Enter your password to confirm.');
    }

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error));
    }

    await _onDeleteAccountData?.call();

    try {
      await (auth.currentUser ?? user).delete();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error));
    }
  }

  void _setLocalUser({required String email, String? displayName}) {
    final cleanEmail = email.trim();
    _currentUser = AuthUser(
      uid: 'local-${cleanEmail.toLowerCase().hashCode}',
      email: cleanEmail,
      displayName: displayName?.trim(),
      isAnonymous: false,
      emailVerified: false,
    );
    notifyListeners();
  }

  static AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      isAnonymous: user.isAnonymous,
      emailVerified: user.emailVerified,
    );
  }

  static String _messageFor(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'The email or password is incorrect.',
      'email-already-in-use' => 'An account already uses this email.',
      'weak-password' => 'Choose a stronger password.',
      'user-disabled' => 'This account has been disabled.',
      'requires-recent-login' =>
        'For your security, sign out and sign back in, then delete the account.',
      'user-mismatch' => 'Those credentials belong to a different account.',
      'operation-not-allowed' =>
        'This sign-in method is not enabled for this Firebase project.',
      'network-request-failed' =>
        'The network is unavailable. Check your connection and retry.',
      'too-many-requests' => 'Too many attempts. Wait a moment and retry.',
      _ => error.message ?? 'Authentication failed. Try again.',
    };
  }
}
