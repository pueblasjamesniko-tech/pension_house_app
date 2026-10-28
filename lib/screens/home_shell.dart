import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/nav.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../widgets/booking_card.dart';
import '../widgets/common.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import 'rooms_screen.dart';
import 'saved_rooms_screen.dart';

class HomeShell extends StatefulWidget {
  final int initialTab;
  const HomeShell({super.key, this.initialTab = tabRooms});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _pages = <Widget>[
    RoomsScreen(),
    BookingsScreen(),
    SavedRoomsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    homeTab.value = widget.initialTab;
    homeTab.addListener(_rebuild);
  }

  @override
  void dispose() {
    homeTab.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  // Colours / icons for the "Booking updates" list.
  IconData _icon(Booking b) => b.cancelled || b.paymentRejected
      ? Icons.cancel_outlined
      : b.completed
          ? Icons.task_alt_rounded
          : b.paymentApproved || b.checkedIn
              ? Icons.check_circle_outline_rounded
              : Icons.schedule_rounded;

  Color _fg(Booking b) => switch (b.tone) {
        BookingTone.good || BookingTone.active => AppColors.success,
        BookingTone.waiting => const Color(0xFF8A5B00),
        BookingTone.bad => AppColors.danger,
        BookingTone.neutral => AppColors.muted,
      };

  Color _bg(Booking b) => switch (b.tone) {
        BookingTone.good || BookingTone.active => AppColors.successSoft,
        BookingTone.waiting => AppColors.goldSoft,
        BookingTone.bad => AppColors.dangerSoft,
        BookingTone.neutral => AppColors.sand,
      };

  /// There is no notifications endpoint for guests (it is staff/admin only),
  /// so "Updates" is built from the guest's own bookings and their statuses.
  void _updates() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.cream,
        shape: sheetShape(),
        builder: (_) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .7),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Handle(),
                    const SizedBox(height: 16),
                    Text('Booking updates', style: serif(22)),
                    const SizedBox(height: 8),
                    Flexible(
                      child: FutureBuilder<List<Booking>>(
                        future: ApiService.instance.myBookings(),
                        builder: (ctx, s) {
                          if (s.hasError) {
                            return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text('${s.error}'));
                          }
                          if (!s.hasData) {
                            return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.green)));
                          }
                          final list = [...s.data!]
                            ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
                          if (list.isEmpty) {
                            return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('You’re all caught up.',
                                    style: TextStyle(color: AppColors.muted)));
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (_, i) {
                              final b = list[i];
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                      color: _bg(b),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Icon(_icon(b), color: _fg(b)),
                                ),
                                title: Text('${b.roomTitle} · ${b.bookingCode}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(b.statusMessage,
                                          style: const TextStyle(
                                              fontSize: 12, height: 1.35)),
                                      const SizedBox(height: 3),
                                      Text('Check-in ${fmtWhen(b.checkIn)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.muted)),
                                    ]),
                                trailing: const Icon(Icons.chevron_right,
                                    color: AppColors.muted),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  showBookingSheet(context, b);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.user!;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(11)),
            child: const Text('NPH',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(Config.appName,
                overflow: TextOverflow.ellipsis, style: serif(17)),
          ),
        ]),
        actions: [
          IconButton(
              tooltip: 'Booking updates',
              onPressed: _updates,
              icon: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.coral)),
          GestureDetector(
            onTap: () => homeTab.value = tabProfile,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: AppColors.coral, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.green,
                child: Text(initials(user.fullName),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
            key: ValueKey(homeTab.value), child: _pages[homeTab.value]),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line))),
        child: NavigationBar(
          selectedIndex: homeTab.value,
          onDestinationSelected: (i) => homeTab.value = i,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.bed_outlined),
                selectedIcon: Icon(Icons.bed_rounded),
                label: 'Rooms'),
            NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Bookings'),
            NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Saved'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
