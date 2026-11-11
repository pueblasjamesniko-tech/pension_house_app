import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  static const _maxBytes = 5 * 1024 * 1024; // same limit as the API

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();

  late Future<List<String>> _types = ApiService.instance.idTypes();
  String? _idType;
  Uint8List? _idBytes;
  String _idName = 'id.jpg';
  String? _idError;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _mobile, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- ID photo -------------------------------------------------------

  static bool _isPng(Uint8List b) =>
      b.length >= 4 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47;

  static bool _isJpg(Uint8List b) =>
      b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: source, maxWidth: 1800, imageQuality: 85);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!_isJpg(bytes) && !_isPng(bytes)) {
        setState(() => _idError = 'Please use a JPG or PNG photo.');
        return;
      }
      if (bytes.isEmpty || bytes.length > _maxBytes) {
        setState(() => _idError = 'The photo must be 5 MB or smaller.');
        return;
      }
      setState(() {
        _idBytes = bytes;
        _idName = _isPng(bytes) ? 'id.png' : 'id.jpg';
        _idError = null;
      });
    } catch (_) {
      if (mounted) {
        toast(context,
            'Could not open the camera or gallery. Check the app permissions.',
            error: true);
      }
    }
  }

  void _chooseSource() => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.cream,
        shape: sheetShape(),
        builder: (sheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Handle(),
              const SizedBox(height: 16),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Add a photo of your ID', style: serif(20))),
              const SizedBox(height: 6),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                    backgroundColor: AppColors.greenSoft,
                    child: Icon(Icons.photo_camera_outlined,
                        color: AppColors.green)),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(sheet);
                  _pick(ImageSource.camera);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                    backgroundColor: AppColors.greenSoft,
                    child: Icon(Icons.photo_library_outlined,
                        color: AppColors.green)),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(sheet);
                  _pick(ImageSource.gallery);
                },
              ),
            ]),
          ),
        ),
      );

  // ---- submit ---------------------------------------------------------

  Future<void> _submit() async {
    final formOk = _form.currentState!.validate();
    if (_idBytes == null) {
      setState(() => _idError = 'Add a clear photo of your ID.');
    }
    if (!formOk || _idBytes == null || _idType == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      // Registers (multipart with the ID photo), then signs in automatically.
      await ApiService.instance.register(
        fullName: _name.text,
        email: _email.text,
        password: _pw.text,
        contactNo: _mobile.text,
        idType: _idType!,
        idImage: _idBytes!,
        idFileName: _idName,
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

  // ---- pieces ---------------------------------------------------------

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 12),
        child: Row(children: [
          Text(text.toUpperCase(), style: overline(color: AppColors.green)),
          const SizedBox(width: 10),
          const Expanded(child: Divider()),
        ]),
      );

  Widget _idTypeField() => FutureBuilder<List<String>>(
        future: _types,
        builder: (_, s) {
          if (s.hasError) {
            return Panel(
              color: AppColors.coralSoft,
              borderColor: Colors.transparent,
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                    child: Text('${s.error}',
                        style: const TextStyle(fontSize: 12))),
                TextButton(
                    onPressed: () =>
                        setState(() => _types = ApiService.instance.idTypes()),
                    child: const Text('Retry')),
              ]),
            );
          }
          if (!s.hasData) return const Skeleton(height: 50, radius: 12);
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ID type',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _idType,
                  isExpanded: true,
                  menuMaxHeight: 320,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  decoration: const InputDecoration(
                    hintText: 'Choose an ID',
                    prefixIcon: Icon(Icons.badge_outlined,
                        size: 19, color: AppColors.muted),
                  ),
                  items: [
                    for (final t in s.data!)
                      DropdownMenuItem(
                          value: t,
                          child: Text(t,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14))),
                  ],
                  onChanged: (v) => setState(() => _idType = v),
                  validator: (v) => v == null ? 'Choose your ID type' : null,
                ),
              ]);
        },
      );

  Widget _photoBox() {
    final has = _idBytes != null;
    final err = _idError != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Photo of your ID',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Material(
        color: AppColors.greenSoft,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
            side: BorderSide(
                color: err ? AppColors.coral : AppColors.line,
                width: err ? 1.5 : 1)),
        child: InkWell(
          onTap: _chooseSource,
          child: SizedBox(
            height: 170,
            width: double.infinity,
            child: has
                ? Stack(fit: StackFit.expand, children: [
                    Image.memory(_idBytes!, fit: BoxFit.cover, cacheWidth: 900),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 14, color: AppColors.green),
                              SizedBox(width: 6),
                              Text('Change photo',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600)),
                            ]),
                      ),
                    ),
                  ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.add_a_photo_outlined,
                                color: AppColors.green)),
                        const SizedBox(height: 10),
                        const Text('Tap to add a photo of your ID',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        const Text('JPG or PNG · up to 5 MB',
                            style: TextStyle(
                                fontSize: 11.5, color: AppColors.muted)),
                      ]),
          ),
        ),
      ),
      if (err)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(_idError!,
              style: const TextStyle(fontSize: 11.5, color: AppColors.danger)),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Create account',
        subtitle: 'Verify your ID once, then book in a few taps.',
        child: Form(
          key: _form,
          child: AutofillGroup(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Your details'),
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
                validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch((v ?? '').trim())
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
              _label('Password'),
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
                validator: (v) =>
                    v != _pw.text ? 'Passwords do not match' : null,
              ),
              _label('ID verification'),
              _idTypeField(),
              const SizedBox(height: 14),
              _photoBox(),
              const SizedBox(height: 12),
              const Panel(
                color: AppColors.goldSoft,
                borderColor: Colors.transparent,
                padding: EdgeInsets.all(12),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 18, color: Color(0xFF8A5B00)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'Your ID is stored privately. Only the pension house admin can view it.',
                            style: TextStyle(fontSize: 12, height: 1.45)),
                      ),
                    ]),
              ),
              const SizedBox(height: 22),
              PrimaryButton('Create account',
                  loading: _busy, onPressed: _submit),
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
