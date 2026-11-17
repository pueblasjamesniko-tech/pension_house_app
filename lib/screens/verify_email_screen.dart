import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

/// Shown after registering (or when an unverified guest tries to sign in).
/// The guest types the 6-digit code from their email, then is signed in.
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String password; // used to sign in right after the code is accepted
  final int startWait; // seconds before "Resend code" works
  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.password,
    this.startWait = 60,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _form = GlobalKey<FormState>();
  final _otp = TextEditingController();

  bool _busy = false;
  int _wait = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.startWait);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
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

  Future<void> _verify() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ApiService.instance.verifyEmail(widget.email, _otp.text);
      await ApiService.instance.login(widget.email, widget.password);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final seconds =
          await ApiService.instance.resendVerification(widget.email);
      if (!mounted) return;
      _startCountdown(seconds);
      toast(context, 'A new 6-digit code is on its way.');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Verify your email',
        subtitle:
            'Type the 6-digit code we sent to your email to finish creating your account.',
        child: Form(
          key: _form,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Code sent to ${widget.email}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
            const SizedBox(height: 14),
            AppField(
              controller: _otp,
              label: '6-digit code',
              hint: '123456',
              icon: Icons.pin_outlined,
              keyboard: TextInputType.number,
              maxLength: 6,
              action: TextInputAction.done,
              autofill: const [AutofillHints.oneTimeCode],
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _verify(),
              validator: (v) => RegExp(r'^[0-9]{6}$').hasMatch((v ?? '').trim())
                  ? null
                  : 'Enter the 6-digit code',
            ),
            const SizedBox(height: 22),
            PrimaryButton('Verify email', loading: _busy, onPressed: _verify),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: (_busy || _wait > 0) ? null : _resend,
                child: Text(_wait > 0 ? 'Resend in ${_wait}s' : 'Resend code'),
              ),
            ),
          ]),
        ),
      );
}
