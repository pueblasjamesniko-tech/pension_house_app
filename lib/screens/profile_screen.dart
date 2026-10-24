import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/nav.dart';
import '../core/theme.dart';
import '../models/app_settings.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/saved_rooms.dart';
import '../widgets/common.dart';
import 'login_screen.dart';
import 'my_reviews_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<List<Booking>> _f = ApiService.instance.myBookings();

  Future<void> _signOut() async {
    final ok = await confirmDialog(context,
        title: 'Sign out?',
        message: 'You’ll need to sign in again to manage your bookings.',
        confirm: 'Sign out');
    if (!ok) return;
    await ApiService.instance.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _about() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.cream,
        shape: sheetShape(),
        builder: (_) => SafeArea(
          child: Padding(
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
                  Text('Contact & payment', style: serif(22)),
                  const SizedBox(height: 12),
                  FutureBuilder<AppSettings>(
                    future: ApiService.instance.settings(),
                    builder: (_, s) {
                      if (s.hasError) return Text('${s.error}');
                      if (!s.hasData) {
                        return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.green)));
                      }
                      final d = s.data!;
                      return Panel(
                        child: Column(children: [
                          if (d.businessName != null)
                            KeyValue('Pension house', d.businessName!),
                          if (d.businessAddress != null)
                            KeyValue('Address', d.businessAddress!),
                          if (d.businessContact != null)
                            KeyValue('Contact', d.businessContact!),
                          if (d.gcashNumber != null)
                            KeyValue('GCash number', d.gcashNumber!),
                          if (d.gcashName != null)
                            KeyValue('GCash name', d.gcashName!),
                          if (d.businessName == null &&
                              d.businessAddress == null &&
                              d.businessContact == null &&
                              d.gcashNumber == null)
                            const Text('No details have been added yet.',
                                style: TextStyle(
                                    fontSize: 12.5, color: AppColors.muted)),
                        ]),
                      );
                    },
                  ),
                ]),
          ),
        ),
      );

  Widget _stat(String n, String label) => Expanded(
        child: Panel(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Text(n, style: serif(24)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ),
      );

  Widget _tile(IconData icon, String label, VoidCallback onTap,
          {bool danger = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.line)),
          child: ListTile(
            onTap: onTap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: Icon(icon,
                size: 21, color: danger ? AppColors.danger : AppColors.green),
            title: Text(label,
                style: TextStyle(
                    fontSize: 13.5,
                    color: danger ? AppColors.danger : AppColors.ink)),
            trailing: danger
                ? null
                : const Icon(Icons.chevron_right, color: AppColors.muted),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.user!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SizedBox(height: 8),
      Center(
        child: CircleAvatar(
          radius: 42,
          backgroundColor: AppColors.green,
          child: Text(initials(user.fullName),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(height: 12),
      Text(user.fullName, textAlign: TextAlign.center, style: serif(24)),
      const SizedBox(height: 2),
      Text(user.email,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
      const SizedBox(height: 18),
      FutureBuilder<List<Booking>>(
        future: _f,
        builder: (_, s) {
          final b = s.data ?? const <Booking>[];
          return ListenableBuilder(
            listenable: SavedRooms.instance,
            builder: (_, __) => Row(children: [
              _stat('${b.where((x) => !x.isPast).length}', 'Upcoming'),
              const SizedBox(width: 8),
              _stat('${b.where((x) => x.completed).length}', 'Past stays'),
              const SizedBox(width: 8),
              _stat('${SavedRooms.instance.ids.length}', 'Saved'),
            ]),
          );
        },
      ),
      const SizedBox(height: 18),
      _tile(Icons.calendar_today_outlined, 'My bookings',
          () => homeTab.value = tabBookings),
      _tile(Icons.star_outline_rounded, 'My reviews', () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyReviewsScreen()));
      }),
      _tile(Icons.favorite_border, 'Saved rooms',
          () => homeTab.value = tabSaved),
      _tile(Icons.info_outline, 'Contact & payment details', _about),
      _tile(Icons.logout, 'Sign out', _signOut, danger: true),
    ]);
  }
}
