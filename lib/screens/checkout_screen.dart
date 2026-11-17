import 'dart:typed_data';
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
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => BookingSuccessScreen(bookingId: id)));
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- pieces ----------------------------------------------------------

  Widget _when(String label, DateTime d, {bool right = false}) => Expanded(
        child: Column(
            crossAxisAlignment:
                right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(label, style: overline()),
              const SizedBox(height: 4),
              Text(fmtTime(d), style: serif(21)),
              Text(fmtDay(d),
                  style:
                      const TextStyle(fontSize: 11.5, color: AppColors.muted)),
            ]),
      );

  Widget _summary(String guest) {
    final r = widget.room;
    final rate = widget.rate;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(
            width: 76,
            height: 60,
            child: RoomImage(url: r.cover, radius: BorderRadius.circular(12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, style: serif(18)),
              const SizedBox(height: 2),
              Text('Room ${r.roomNo}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
        ]),
        const Divider(height: 28),
        Row(children: [
          _when('CHECK-IN', widget.checkIn),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.coralSoft,
                borderRadius: BorderRadius.circular(20)),
            child: Text(hoursLabel(rate.hours),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.coral)),
          ),
          _when('CHECK-OUT', _checkOut, right: true),
        ]),
        const Divider(height: 28),
        KeyValue('Guest', guest),
        KeyValue(
            'Stay', rate.label.isEmpty ? hoursLabel(rate.hours) : rate.label),
        const Divider(height: 18),
        KeyValue('Total to pay', peso(rate.price), bold: true),
      ]),
    );
  }

  /// The GCash number card and the owner's QR code. Either can be missing.
  Widget _gcash(AppSettings s) {
    final number = s.gcashNumber;
    final hasQr = s.hasGcashQr && s.gcashQrVersion != null;

    if (number == null && !hasQr) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.goldSoft, borderRadius: BorderRadius.circular(12)),
        child: const Text(
            'GCash details are not set yet. Please contact the front desk.',
            style: TextStyle(fontSize: 12.5)),
      );
    }
    return Column(children: [
      if (hasQr) _GcashQr(version: s.gcashQrVersion!, name: s.gcashName),
      if (hasQr && number != null) const SizedBox(height: 12),
      if (number != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppShadow.soft),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hasQr ? 'OR SEND TO THIS NUMBER' : 'GCASH NUMBER',
                        style: overline(color: Colors.white60)),
                    const SizedBox(height: 4),
                    Text(number, style: mono(20, color: Colors.white)),
                    if (s.gcashName != null) ...[
                      const SizedBox(height: 2),
                      Text(s.gcashName!,
                          style: const TextStyle(
                              fontSize: 12.5, color: Colors.white70)),
                    ],
                  ]),
            ),
            IconButton(
              tooltip: 'Copy number',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: number));
                toast(context, 'GCash number copied');
              },
              icon:
                  const Icon(Icons.copy_rounded, size: 20, color: Colors.white),
            ),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.user!;
    final rate = widget.rate;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _form,
        child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            children: [
              _summary(user.fullName),
              const SizedBox(height: 16),

              // ---- GCash payment, in 3 steps ----
              Panel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pay with GCash', style: serif(20)),
                      const SizedBox(height: 16),
                      _Step(
                        n: 1,
                        title:
                            'Scan the QR or send exactly ${peso(rate.price)}',
                        child: Column(children: [
                          FutureBuilder<AppSettings>(
                            future: _settings,
                            builder: (_, s) {
                              if (s.hasData) return _gcash(s.data!);
                              if (s.hasError) {
                                return Column(children: [
                                  Text('${s.error}',
                                      style: const TextStyle(fontSize: 12.5)),
                                  TextButton(
                                      onPressed: () => setState(() =>
                                          _settings = ApiService.instance
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
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: rate.price.toStringAsFixed(2)));
                                toast(context, 'Amount copied');
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: Text('Copy amount (${peso(rate.price)})'),
                            ),
                          ),
                        ]),
                      ),
                      _Step(
                        n: 2,
                        title:
                            'Enter the reference number from your GCash receipt',
                        child: AppField(
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
                            if (t.isEmpty) {
                              return 'Enter your GCash reference number';
                            }
                            if (t.length < 6) {
                              return 'That reference number looks too short';
                            }
                            if (t.length > 50) {
                              return 'That reference number is too long';
                            }
                            return null;
                          },
                        ),
                      ),
                      const _Step(
                        n: 3,
                        title: 'Tap “Confirm booking”',
                        last: true,
                        child: Text(
                            'Each reference number can only be used once. Our staff will then verify your payment.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                height: 1.45)),
                      ),
                    ]),
              ),
              const SizedBox(height: 12),
              const Panel(
                color: AppColors.goldSoft,
                borderColor: Colors.transparent,
                padding: EdgeInsets.all(12),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Color(0xFF8A5B00)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'Your booking stays “awaiting payment check” until staff verify your GCash payment. You can follow its status under Bookings.',
                            style: TextStyle(fontSize: 12, height: 1.45)),
                      ),
                    ]),
              ),
              const SizedBox(height: 8),
            ]),
      ),

      // ---- sticky confirm bar ----
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL', style: overline()),
                    const SizedBox(height: 2),
                    Text(peso(rate.price), style: serif(23)),
                  ]),
              const SizedBox(width: 20),
              Expanded(
                  child: PrimaryButton('Confirm booking',
                      icon: Icons.check_rounded,
                      loading: _busy,
                      onPressed: _submit)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// One numbered step with a line connecting it to the next one.
class _Step extends StatelessWidget {
  final int n;
  final String title;
  final Widget? child;
  final bool last;
  const _Step(
      {required this.n, required this.title, this.child, this.last = false});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 26,
            child: Column(children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.green, shape: BoxShape.circle),
                child: Text('$n',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              if (!last)
                Expanded(
                    child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: AppColors.line)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w600)),
                    ),
                    if (child != null) ...[
                      const SizedBox(height: 10),
                      child!,
                    ],
                  ]),
            ),
          ),
        ]),
      );
}

/// The owner's GCash QR code. Tap it to see it bigger (easier to scan from
/// another phone).
class _GcashQr extends StatefulWidget {
  final String version;
  final String? name;
  const _GcashQr({required this.version, this.name});
  @override
  State<_GcashQr> createState() => _GcashQrState();
}

class _GcashQrState extends State<_GcashQr> {
  late Future<Uint8List> _img = ApiService.instance.gcashQr(widget.version);

  void _retry() =>
      setState(() => _img = ApiService.instance.gcashQr(widget.version));

  void _enlarge(Uint8List bytes) => showDialog<void>(
        context: context,
        builder: (c) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: Text('GCash QR', style: serif(20))),
                IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(c),
                    icon: const Icon(Icons.close_rounded)),
              ]),
              Flexible(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Pinch to zoom',
                  style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line)),
        child: FutureBuilder<Uint8List>(
          future: _img,
          builder: (_, s) {
            if (s.hasData) {
              return Column(children: [
                GestureDetector(
                  onTap: () => _enlarge(s.data!),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Image.memory(s.data!, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 10),
                if (widget.name != null)
                  Text(widget.name!,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                const Text('Scan with GCash · tap to enlarge',
                    style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
              ]);
            }
            if (s.hasError) {
              return Column(children: [
                Text('${s.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5)),
                TextButton(onPressed: _retry, child: const Text('Try again')),
              ]);
            }
            return const SizedBox(
                height: 180,
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.green)));
          },
        ),
      );
}
