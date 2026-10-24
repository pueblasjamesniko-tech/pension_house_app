import 'package:flutter/material.dart';

/// 0 Rooms · 1 Bookings · 2 Saved · 3 Profile
const tabRooms = 0, tabBookings = 1, tabSaved = 2, tabProfile = 3;
final homeTab = ValueNotifier<int>(tabRooms);

final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();
