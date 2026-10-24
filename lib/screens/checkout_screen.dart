import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/app_settings.dart';
import '../models/room.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';
import 'booking_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Room room;
  final RoomRate rate;
  final DateTime checkIn;
  const CheckoutScreen(
      {super.key,
      required this.room,
      required this.rate,
      required this.checkIn});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _ref = TextEditingController();
  late Future<AppSettings> _settings = ApiService.instance.settings();
  bool _busy = false;

  DateTime get _checkOut =>
      widget.checkIn.add(Duration(hours: widget.rate.hours));

  @override
  void dispose() {
    _ref.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final id = await ApiService.instance.createBooking(
        roomId: widget.room.id,
        rateId: widget.rate.id,
        checkIn: widget.checkIn,
        referenceCode: _ref.text.replaceAll(RegExp(r'\s'), ''),
      );
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => BookingSuccessScreen(bookingId: id)));
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _stepNumber(int n) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: AppColors.green, shape: BoxShape.circle),
        child: Text('$n',
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _gcash(AppSettings s) {
    final number = s.gcashNumber;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.greenSoft,
            borderRadius: BorderRadius.circular(12)),
        child: number == null
            ? const Text(
                'GCash details are not set yet. Please contact the front desk.',
                style: TextStyle(fontSize: 12.5))
            : Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GCASH NUMBER',
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: .7,
                                color: AppColors.muted)),
                        const SizedBox(height: 2),
                        Text(number, style: serif(21)),
                        if (s.gcashName != null)
                          Text(s.gcashName!,
                              style: const TextStyle(
                                  fontSize: 12.5, color: AppColors.ink)),
                      ]),
                ),
                IconButton.filledTonal(
                  tooltip: 'Copy number',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: number));
                    toast(context, 'GCash number copied');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                ),
              ]),
      ),
      // Optional QR: add assets/gcash_qr.png to your project to show it here.
      Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Image.asset('assets/gcash_qr.png',
              width: 170,
              errorBuilder: (_, __, ___) => const SizedBox.shrink()),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.user!;
    final r = widget.room;
    final rate = widget.rate;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _form,
        child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            children: [
              // ---- stay summary ----
              Panel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        SizedBox(
                          width: 72,
                          height: 56,
                          child: RoomImage(
                              url: r.cover, radius: BorderRadius.circular(10)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.title, style: serif(17)),
                                Text('Room ${r.roomNo}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.muted)),
                              ]),
                        ),
                      ]),
                      const Divider(height: 26),
                      KeyValue('Guest', user.fullName),
                      KeyValue('Check-in', fmtWhen(widget.checkIn)),
                      KeyValue('Check-out', fmtWhen(_checkOut)),
                      KeyValue(
                          'Stay',
                          rate.label.isEmpty
                              ? hoursLabel(rate.hours)
                              : rate.label),
                      const Divider(height: 18),
                      KeyValue('Total to pay', peso(rate.price), bold: true),
                    ]),
              ),
              const SizedBox(height: 14),

              // ---- GCash payment ----
              Panel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pay with GCash', style: serif(19)),
                      const SizedBox(height: 14),
                      Row(children: [
                        _stepNumber(1),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(TextSpan(children: [
                            const TextSpan(text: 'Send exactly '),
                            TextSpan(
                                text: peso(rate.price),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.coral)),
                            const TextSpan(text: ' to the GCash account below.'),
                          ]), style: const TextStyle(fontSize: 13)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      FutureBuilder<AppSettings>(
                        future: _settings,
                        builder: (_, s) {
                          if (s.hasData) return _gcash(s.data!);
                          if (s.hasError) {
                            return Column(children: [
                              Text('${s.error}',
                                  style: const TextStyle(fontSize: 12.5)),
                              TextButton(
                                  onPressed: () => setState(() => _settings =
                                      ApiService.instance
                                          .settings(refresh: true)),
                                  child: const Text('Try again')),
                            ]);
                          }
                          return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.green)));
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(children: [
                        _stepNumber(2),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                              'Enter the reference number from your GCash receipt.',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      AppField(
                        controller: _ref,
                        label: 'GCash reference number',
                        hint: 'e.g. 1234 567 890123',
                        icon: Icons.receipt_long_outlined,
                        maxLength: 60,
                        action: TextInputAction.done,
                        capitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _submit(),
                        formatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9\- ]'))
                        ],
                        validator: (v) {
                          final t = (v ?? '').replaceAll(RegExp(r'\s'), '');
                          if (t.isEmpty) return 'Enter your GCash reference number';
                          if (t.length < 6) return 'That reference number looks too short';
                          if (t.length > 50) return 'That reference number is too long';
                          return null;
                        },
                      ),
                    ]),
              ),
              const SizedBox(height: 12),
              Panel(
                color: AppColors.goldSoft,
                borderColor: Colors.transparent,
                padding: const EdgeInsets.all(12),
                child: const Text(
                    'Your booking stays “awaiting payment check” until our staff verifies your GCash payment. You can follow its status under Bookings.',
                    style: TextStyle(fontSize: 12, height: 1.45)),
              ),
              const SizedBox(height: 16),
              PrimaryButton('Confirm booking', loading: _busy, onPressed: _submit),
              const SizedBox(height: 8),
            ]),
      ),
    );
  }
}
