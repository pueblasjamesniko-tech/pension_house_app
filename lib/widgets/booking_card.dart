import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import 'common.dart';
import 'review_sheet.dart';

Pill bookingPill(Booking b) {
  switch (b.tone) {
    case BookingTone.good:
      return Pill.good(b.statusLabel);
    case BookingTone.active:
      return Pill.good(b.statusLabel);
    case BookingTone.bad:
      return Pill.bad(b.statusLabel);
    case BookingTone.waiting:
      return Pill.warn(b.statusLabel);
    case BookingTone.neutral:
      return Pill.neutral(b.statusLabel);
  }
}

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool canRate;
  final VoidCallback? onChanged;
  const BookingCard(this.booking,
      {super.key, this.canRate = false, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final dark = !b.isPast;
    final fg = dark ? Colors.white : AppColors.ink;
    final sub = dark ? Colors.white70 : AppColors.muted;

    Widget info(String label, String value) => Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(),
                style: TextStyle(fontSize: 10, letterSpacing: .7, color: sub)),
            const SizedBox(height: 3),
            Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
          ]),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: dark ? AppColors.green : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: dark ? null : Border.all(color: AppColors.line),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => showBookingSheet(context, b,
              canRate: canRate, onChanged: onChanged),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    bookingPill(b),
                    const Spacer(),
                    Text(b.bookingCode,
                        style: TextStyle(
                            fontSize: 11.5,
                            letterSpacing: .4,
                            color: sub,
                            fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 12),
                  Text(b.roomTitle, style: serif(21, color: fg)),
                  Text('Room ${b.roomNo}',
                      style: TextStyle(fontSize: 12, color: sub)),
                  const SizedBox(height: 16),
                  Row(children: [
                    info('Check-in', fmtWhen(b.checkIn)),
                    info('Check-out', fmtWhen(b.checkOut)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    info('Stay', b.rateLabel.isEmpty ? hoursLabel(b.hours) : b.rateLabel),
                    info('Total', peso(b.totalAmount)),
                  ]),
                  if (canRate) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final ok = await showReviewSheet(context,
                              roomTitle: b.roomTitle, bookingId: b.id);
                          if (ok) {
                            if (context.mounted) {
                              toast(context, 'Thanks for your review!');
                            }
                            onChanged?.call();
                          }
                        },
                        icon: const Icon(Icons.star_rounded, size: 18),
                        label: const Text('Rate your stay'),
                      ),
                    ),
                  ],
                ]),
          ),
        ),
      ),
    );
  }
}

void showBookingSheet(BuildContext context, Booking b,
    {bool canRate = false, VoidCallback? onChanged}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: sheetShape(),
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Text(b.roomTitle, style: serif(23))),
                bookingPill(b),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('Booking ${b.bookingCode}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: b.bookingCode));
                    toast(context, 'Booking code copied');
                  },
                  child: const Icon(Icons.copy_rounded,
                      size: 14, color: AppColors.muted),
                ),
              ]),
              const SizedBox(height: 14),
              Panel(
                child: Column(children: [
                  KeyValue('Room', '${b.roomTitle} · ${b.roomNo}'),
                  KeyValue('Check-in', fmtWhen(b.checkIn)),
                  KeyValue('Check-out', fmtWhen(b.checkOut)),
                  KeyValue('Stay', b.rateLabel.isEmpty ? hoursLabel(b.hours) : b.rateLabel),
                  const Divider(height: 18),
                  KeyValue('Payment', 'GCash · ${b.paymentLabel}'),
                  if (b.referenceCode != null)
                    KeyValue('GCash ref.', b.referenceCode!),
                  KeyValue('Total', peso(b.totalAmount), bold: true),
                ]),
              ),
              const SizedBox(height: 12),
              Panel(
                color: b.paymentRejected ? AppColors.dangerSoft : AppColors.goldSoft,
                borderColor: Colors.transparent,
                padding: const EdgeInsets.all(12),
                child: Text(b.statusMessage,
                    style: const TextStyle(fontSize: 12, height: 1.4)),
              ),
              if (canRate) ...[
                const SizedBox(height: 14),
                PrimaryButton('Rate your stay', onPressed: () async {
                  Navigator.pop(sheet);
                  final ok = await showReviewSheet(context,
                      roomTitle: b.roomTitle, bookingId: b.id);
                  if (ok) {
                    if (context.mounted) toast(context, 'Thanks for your review!');
                    onChanged?.call();
                  }
                }),
              ],
              if (b.canCancel) ...[
                const SizedBox(height: 12),
                PrimaryButton('Cancel booking',
                    outlined: true,
                    onPressed: () => _cancel(context, sheet, b, onChanged)),
              ],
            ]),
      ),
    ),
  );
}

Future<void> _cancel(BuildContext context, BuildContext sheet, Booking b,
    VoidCallback? onChanged) async {
  final ok = await confirmDialog(sheet,
      title: 'Cancel this booking?',
      message:
          'Your booking ${b.bookingCode} will be cancelled. If you already paid through GCash, please contact the front desk about your payment.',
      confirm: 'Cancel booking',
      cancel: 'Keep booking',
      danger: true);
  if (!ok) return;
  try {
    await ApiService.instance.cancelBooking(b.id);
    if (sheet.mounted) Navigator.pop(sheet);
    if (context.mounted) toast(context, 'Booking cancelled.');
    onChanged?.call();
  } on ApiException catch (e) {
    if (context.mounted) toast(context, e.message, error: true);
  }
}
