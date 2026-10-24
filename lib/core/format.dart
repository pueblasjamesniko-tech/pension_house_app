import 'package:intl/intl.dart';

String peso(num n) {
  final whole = n == n.roundToDouble();
  return NumberFormat.currency(symbol: '₱', decimalDigits: whole ? 0 : 2)
      .format(n);
}

/// "Today, 2:00 PM" · "Tomorrow, 9:00 AM" · "Oct 30, 2:00 PM"
String fmtWhen(DateTime d) {
  final now = DateTime.now();
  final days = DateTime(d.year, d.month, d.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  final day = days == 0
      ? 'Today'
      : days == 1
          ? 'Tomorrow'
          : DateFormat('MMM d').format(d);
  return '$day, ${DateFormat('h:mm a').format(d)}';
}

String fmtDay(DateTime d) => DateFormat('EEE, MMM d').format(d);
String fmtTime(DateTime d) => DateFormat('h:mm a').format(d);
String fmtShort(DateTime d) => DateFormat('MMM d, yyyy').format(d);

/// Format sent to the API (local time, no time-zone suffix).
String apiDateTime(DateTime d) => DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(d);

String hoursLabel(int h) => h == 1 ? '1 hour' : '$h hours';

String initials(String name) {
  final p =
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
  return p.isEmpty ? '?' : p.map((w) => w[0].toUpperCase()).join();
}

String firstName(String name) {
  final t = name.trim();
  return t.isEmpty ? 'there' : t.split(RegExp(r'\s+')).first;
}
