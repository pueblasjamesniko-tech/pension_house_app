import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _mobile, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      // Registers, then signs in automatically.
      await ApiService.instance.register(
        fullName: _name.text,
        email: _email.text,
        password: _pw.text,
        contactNo: _mobile.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Create account',
        subtitle: 'It takes less than a minute.',
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: Column(children: [
              AppField(
                controller: _name,
                label: 'Full name',
                hint: 'Juan Dela Cruz',
                icon: Icons.person_outline,
                maxLength: 100,
                capitalization: TextCapitalization.words,
                action: TextInputAction.next,
                autofill: const [AutofillHints.name],
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 14),
              AppField(
                controller: _email,
                label: 'Email address',
                hint: 'you@example.com',
                icon: Icons.mail_outline,
                maxLength: 150,
                keyboard: TextInputType.emailAddress,
                action: TextInputAction.next,
                autofill: const [AutofillHints.email],
                validator: (v) =>
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                        ? null
                        : 'Enter a valid email',
              ),
              const SizedBox(height: 14),
              AppField(
                controller: _mobile,
                label: 'Mobile number (optional)',
                hint: '09XX XXX XXXX',
                icon: Icons.phone_outlined,
                maxLength: 20,
                keyboard: TextInputType.phone,
                action: TextInputAction.next,
                autofill: const [AutofillHints.telephoneNumber],
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  return RegExp(r'^[0-9+\-\s]{7,20}$').hasMatch(t)
                      ? null
                      : 'Enter a valid mobile number';
                },
              ),
              const SizedBox(height: 14),
              AppField(
                controller: _pw,
                label: 'Password',
                hint: 'At least 6 characters',
                icon: Icons.lock_outline,
                password: true,
                maxLength: 100,
                action: TextInputAction.next,
                autofill: const [AutofillHints.newPassword],
                validator: (v) =>
                    (v ?? '').length < 6 ? 'Use at least 6 characters' : null,
              ),
              const SizedBox(height: 14),
              AppField(
                controller: _pw2,
                label: 'Confirm password',
                hint: 'Re-enter your password',
                icon: Icons.lock_outline,
                password: true,
                action: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    v != _pw.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 22),
              PrimaryButton('Create account', loading: _busy, onPressed: _submit),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account?',
                    style: TextStyle(fontSize: 13, color: AppColors.muted)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Sign in'),
                ),
              ]),
            ]),
          ),
        ),
      );
}
