import 'package:flutter/material.dart';

import '../screens/login.dart';
import '../services/auth_service.dart';
import 'app_shell.dart';

/// Decides what the app opens to: the login/signup flow until the user is
/// authenticated, then the main shell. Rebuilds automatically when auth state
/// changes through the Firebase-backed auth service.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        return AuthService.instance.isSignedIn
            ? const AppShell()
            : const LoginScreen();
      },
    );
  }
}
