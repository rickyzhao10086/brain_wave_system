import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/icon_badge.dart';
import '../widgets/neuro_panel.dart';

/// The login / signup gate shown before the app when no user is signed in.
///
/// The backend is Firebase, but it isn't connected yet, so submitting runs in
/// demo mode via [AuthService] — credentials are validated for shape only and
/// the call is bypassed. "Skip for now" enters as a guest with no account.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _accent = [Color(0xff17d6c0), Color(0xff8b5cf6)];

  bool _isLogin = true;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setMode(bool isLogin) {
    if (_isLogin == isLogin) return;
    setState(() {
      _isLogin = isLogin;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    // Light, shape-only validation so the form feels real. The backend is
    // bypassed, so any well-formed input is accepted.
    final problem = _validate(name: name, email: email, password: password);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await AuthService.instance.signIn(email: email, password: password);
      } else {
        await AuthService.instance
            .signUp(name: name, email: email, password: password);
      }
      // On success AuthService notifies the AuthGate, which swaps this screen
      // out for the app — nothing else to do here.
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validate({
    required String name,
    required String email,
    required String password,
  }) {
    if (!_isLogin && name.isEmpty) return 'Enter your name.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  Future<void> _skip() async {
    await AuthService.instance.continueAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Brand(),
                  const SizedBox(height: 22),
                  const _DemoNotice(),
                  const SizedBox(height: 16),
                  _formCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard() {
    return NeuroPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeToggle(isLogin: _isLogin, onChanged: _loading ? null : _setMode),
          const SizedBox(height: 18),
          if (!_isLogin) ...[
            _AuthField(
              controller: _name,
              hint: 'Full name',
              icon: Icons.badge_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
          ],
          _AuthField(
            controller: _email,
            hint: 'Email',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _AuthField(
            controller: _password,
            hint: 'Password',
            icon: Icons.lock_rounded,
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            trailing: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
                color: Colors.white.withValues(alpha: .45),
              ),
            ),
          ),
          if (_isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading ? null : _onForgotPassword,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: Color(0xff22d3ee), fontSize: 11),
                ),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            _ErrorText(_error!),
          ],
          const SizedBox(height: 16),
          _PrimaryButton(
            label: _isLogin ? 'Log In' : 'Create Account',
            loading: _loading,
            colors: _accent,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loading ? null : _skip,
            child: Text(
              'Skip for now',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .6),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset is available once the backend is connected.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0x5517d6c0), blurRadius: 28, spreadRadius: 1),
            ],
          ),
          child: const IconBadge(
            icon: Icons.psychology_alt_rounded,
            colors: [Color(0xff17d6c0), Color(0xff8b5cf6)],
            size: 64,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'NeuroMotion',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Clinician & caregiver access',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .55),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Honest banner so nobody mistakes the bypass for a working backend.
class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xfff59e0b);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: amber.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: amber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo mode — Firebase backend not connected yet. Sign-in is bypassed.',
              style: TextStyle(
                color: amber.withValues(alpha: .95),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isLogin, required this.onChanged});

  final bool isLogin;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xff0f111c),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        children: [
          Expanded(child: _segment('Login', isLogin, () => onChanged?.call(true))),
          Expanded(
            child: _segment('Sign Up', !isLogin, () => onChanged?.call(false)),
          ),
        ],
      ),
    );
  }

  Widget _segment(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onChanged == null ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [Color(0xff17d6c0), Color(0xff8b5cf6)])
              : null,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white.withValues(alpha: .5),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.trailing,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? trailing;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final faint = Colors.white.withValues(alpha: .45);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        );

    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      cursorColor: const Color(0xff22d3ee),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: faint, fontSize: 14),
        prefixIcon: Icon(icon, color: faint, size: 20),
        suffixIcon: trailing,
        filled: true,
        fillColor: const Color(0xff0f111c),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        enabledBorder: border(Colors.white.withValues(alpha: .08)),
        focusedBorder: border(const Color(0xff22d3ee)),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xffff4d6d), size: 15),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xffff4d6d), fontSize: 11.5),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final List<Color> colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: loading ? null : onPressed,
          child: SizedBox(
            height: 52,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
