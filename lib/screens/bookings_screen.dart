import 'package:flutter/material.dart';
import '../core/nav.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../widgets/booking_card.dart';
import '../widgets/common.dart';

class _Data {
  final List<Booking> bookings;
  final Set<int> reviewable;
  const _Data(this.bookings, this.reviewable);
}

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late Future<_Data> _f = _load();
  bool _past = false;

  Future<_Data> _load() async {
    final api = ApiService.instance;
    final bookings = await api.myBookings();
    // Reviews are a bonus: never let a failure here hide the bookings.
    Set<int> reviewable = {};
    try {
      reviewable = await api.reviewableBookingIds();
    } on ApiException catch (e) {
      if (e.status == 401) rethrow;
    }
    return _Data(bookings, reviewable);
  }

  void _reload() => setState(() => _f = _load());

  @override
  Widget build(BuildContext context) => AsyncView<_Data>(
        future: _f,
        onRetry: _reload,
        builder: (d) {
          final upcoming = d.bookings.where((b) => !b.isPast).toList()
            ..sort((a, b) => a.checkIn.compareTo(b.checkIn));
          final past = d.bookings.where((b) => b.isPast).toList()
            ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
          final list = _past ? past : upcoming;

          return RefreshIndicator(
            color: AppColors.green,
            onRefresh: () async {
              _reload();
              await _f;
            },
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  SectionTitle(
                      'My bookings',
                      d.bookings.isEmpty
                          ? 'No bookings yet'
                          : '${upcoming.length} upcoming · ${past.length} past'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                            value: false,
                            label: Text('Upcoming (${upcoming.length})')),
                        ButtonSegment(
                            value: true, label: Text('Past (${past.length})')),
                      ],
                      selected: {_past},
                      onSelectionChanged: (s) =>
                          setState(() => _past = s.first),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (list.isEmpty)
                    EmptyState(
                      icon: _past ? Icons.history : Icons.event_available_outlined,
                      title: _past
                          ? 'No past stays yet'
                          : 'You have no upcoming stay',
                      message: _past
                          ? 'Completed and cancelled bookings will show up here.'
                          : 'Pick a room and book your stay in a few taps.',
                      action: _past ? null : 'Browse rooms',
                      onAction: _past ? null : () => homeTab.value = tabRooms,
                    ),
                  for (final b in list)
                    BookingCard(b,
                        key: ValueKey(b.id),
                        canRate: d.reviewable.contains(b.id),
                        onChanged: _reload),
                ]),
          );
        },
      );
}
