import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/common.dart';
import 'forgot_password_screen.dart';
import 'home_shell.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ApiService.instance.login(_email.text, _pw.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'EMAIL_NOT_VERIFIED') {
        // Right password, but the email was never verified: the API just sent a new code.
        toast(context, e.message);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VerifyEmailScreen(
                    email: _email.text.trim(), password: _pw.text)));
      } else {
        toast(context, e.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _forgotPassword() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              ForgotPasswordScreen(initialEmail: _email.text.trim())));

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Sign in',
        subtitle: 'Welcome back — enter your details below.',
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: Column(children: [
              AppField(
                controller: _email,
                label: 'Email address',
                hint: 'you@example.com',
                icon: Icons.mail_outline,
                keyboard: TextInputType.emailAddress,
                action: TextInputAction.next,
                autofill: const [AutofillHints.email],
                validator: (v) {
                  final t = (v ?? '').trim();
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                      ? null
                      : 'Enter a valid email';
                },
              ),
              const SizedBox(height: 14),
              AppField(
                controller: _pw,
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline,
                password: true,
                action: TextInputAction.done,
                autofill: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Enter your password' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _forgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 10),
              PrimaryButton('Sign in', loading: _busy, onPressed: _submit),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('New here?',
                    style: TextStyle(fontSize: 13, color: AppColors.muted)),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text('Create an account'),
                ),
              ]),
            ]),
          ),
        ),
      );
}
