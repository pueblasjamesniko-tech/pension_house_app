import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/nav.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

class BookingSuccessScreen extends StatefulWidget {
  final int bookingId;
  const BookingSuccessScreen({super.key, required this.bookingId});
  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  late Future<Booking> _f = ApiService.instance.booking(widget.bookingId);

  void _home() => Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => const HomeShell(initialTab: tabBookings)),
      (_) => false);

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.user!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home();
      },
      child: Scaffold(
        body: SafeArea(
          child: AsyncView<Booking>(
            future: _f,
            onRetry: () =>
                setState(() => _f = ApiService.instance.booking(widget.bookingId)),
            builder: (b) => ListView(padding: const EdgeInsets.all(24), children: [
              const SizedBox(height: 16),
              const Center(
                child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.green,
                    child: Icon(Icons.check_rounded, color: Colors.white, size: 40)),
              ),
              const SizedBox(height: 18),
              Text('Booking received, ${firstName(user.fullName)}!',
                  textAlign: TextAlign.center, style: serif(25)),
              const SizedBox(height: 8),
              const Text(
                  'Our staff will verify your GCash payment shortly. You can follow the status under Bookings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.muted)),
              const SizedBox(height: 22),
              Panel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BOOKING CODE',
                          style: TextStyle(
                              fontSize: 10,
                              letterSpacing: .8,
                              color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(b.bookingCode, style: serif(24)),
                      const Divider(height: 26),
                      KeyValue('Room', '${b.roomTitle} · ${b.roomNo}'),
                      KeyValue('Check-in', fmtWhen(b.checkIn)),
                      KeyValue('Check-out', fmtWhen(b.checkOut)),
                      if (b.referenceCode != null)
                        KeyValue('GCash ref.', b.referenceCode!),
                      KeyValue('Status', b.statusLabel),
                      const Divider(height: 18),
                      KeyValue('Total', peso(b.totalAmount), bold: true),
                    ]),
              ),
              const SizedBox(height: 22),
              PrimaryButton('View my bookings', onPressed: _home),
            ]),
          ),
        ),
      ),
    );
  }
}
