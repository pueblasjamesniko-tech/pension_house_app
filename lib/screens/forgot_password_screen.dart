import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/common.dart';

class ForgotPasswordScreen extends StatefulWidget {
  /// Filled in from the sign-in screen so the guest does not type it twice.
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _otp = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();

  bool _codeSent = false; // false = step 1 (email), true = step 2 (code)
  bool _busy = false;
  int _wait = 0; // seconds until "Resend code" works again
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_email, _otp, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _wait = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _wait = _wait > 0 ? _wait - 1 : 0);
      if (_wait == 0) t.cancel();
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (!resend && !_emailForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final seconds = await ApiService.instance.forgotPassword(_email.text);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _startCountdown(seconds);
      toast(context,
          'If that email has an account, a 6-digit code is on its way.');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!_resetForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ApiService.instance.resetPassword(_email.text, _otp.text, _pw.text);
      if (!mounted) return;
      toast(
          context, 'Password changed. Please sign in with your new password.');
      Navigator.pop(context); // back to the sign-in screen
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _useAnotherEmail() {
    _timer?.cancel();
    _otp.clear();
    _pw.clear();
    _pw2.clear();
    setState(() {
      _codeSent = false;
      _wait = 0;
    });
  }

  String? _checkPassword(String? v) {
    final p = v ?? '';
    if (p.length < 8) return 'Use at least 8 characters';
    if (p.length > 32) return 'Use at most 32 characters';
    return null;
  }

  Widget _emailStep() => Form(
        key: _emailForm,
        child: Column(children: [
          AppField(
            controller: _email,
            label: 'Email address',
            hint: 'you@example.com',
            icon: Icons.mail_outline,
            keyboard: TextInputType.emailAddress,
            action: TextInputAction.done,
            autofill: const [AutofillHints.email],
            onSubmitted: (_) => _sendCode(),
            validator: (v) =>
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                    ? null
                    : 'Enter a valid email',
          ),
          const SizedBox(height: 22),
          PrimaryButton('Send code',
              loading: _busy, onPressed: () => _sendCode()),
        ]),
      );

  Widget _resetStep() => Form(
        key: _resetForm,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Code sent to ${_email.text.trim()}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          const SizedBox(height: 14),
          AppField(
            controller: _otp,
            label: '6-digit code',
            hint: '123456',
            icon: Icons.pin_outlined,
            keyboard: TextInputType.number,
            maxLength: 6,
            action: TextInputAction.next,
            autofill: const [AutofillHints.oneTimeCode],
            formatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => RegExp(r'^[0-9]{6}$').hasMatch((v ?? '').trim())
                ? null
                : 'Enter the 6-digit code',
          ),
          const SizedBox(height: 14),
          AppField(
            controller: _pw,
            label: 'New password',
            hint: '8 to 32 characters',
            icon: Icons.lock_outline,
            password: true,
            maxLength: 32,
            action: TextInputAction.next,
            autofill: const [AutofillHints.newPassword],
            validator: _checkPassword,
          ),
          const SizedBox(height: 14),
          AppField(
            controller: _pw2,
            label: 'Confirm new password',
            hint: 'Re-enter your new password',
            icon: Icons.lock_outline,
            password: true,
            maxLength: 32,
            action: TextInputAction.done,
            onSubmitted: (_) => _reset(),
            validator: (v) => v != _pw.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 22),
          PrimaryButton('Change password', loading: _busy, onPressed: _reset),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(
              onPressed: _busy ? null : _useAnotherEmail,
              child: const Text('Use another email'),
            ),
            TextButton(
              onPressed:
                  (_busy || _wait > 0) ? null : () => _sendCode(resend: true),
              child: Text(_wait > 0 ? 'Resend in ${_wait}s' : 'Resend code'),
            ),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: _codeSent ? 'Enter your code' : 'Forgot password',
        subtitle: _codeSent
            ? 'Type the 6-digit code from your email, then choose a new password.'
            : 'Enter your email and we’ll send you a 6-digit code.',
        child: _codeSent ? _resetStep() : _emailStep(),
      );
}
