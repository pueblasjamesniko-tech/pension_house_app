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
                    Center(
                        child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                                color: AppColors.line,
                                borderRadius: BorderRadius.circular(4)))),
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
                          final list = [...s.data!]..sort(
                              (a, b) => b.checkIn.compareTo(a.checkIn));
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
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.greenSoft,
                                  child: Icon(
                                      b.cancelled || b.paymentRejected
                                          ? Icons.cancel_outlined
                                          : b.completed
                                              ? Icons.task_alt
                                              : b.paymentApproved || b.checkedIn
                                                  ? Icons.check_circle_outline
                                                  : Icons.schedule,
                                      color: AppColors.green),
                                ),
                                title: Text('${b.roomTitle} · ${b.bookingCode}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(b.statusMessage,
                                    style: const TextStyle(fontSize: 12)),
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
            width: 34,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppColors.green, borderRadius: BorderRadius.circular(8)),
            child: const Text('NPH',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(Config.appName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.green,
              child: Text(initials(user.fullName),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: _pages[homeTab.value],
      bottomNavigationBar: NavigationBar(
        selectedIndex: homeTab.value,
        onDestinationSelected: (i) => homeTab.value = i,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.bed_outlined), label: 'Rooms'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined), label: 'Bookings'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border), label: 'Saved'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
