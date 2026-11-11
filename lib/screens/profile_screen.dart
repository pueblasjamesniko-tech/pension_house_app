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
                  const Handle(),
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

  // ---- pieces ----------------------------------------------------------

  Widget _header(String name, String email) => Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
        decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppShadow.lift),
        child: Stack(children: [
          Positioned(
            right: -60,
            top: -80,
            child: Container(
                width: 170,
                height: 170,
                decoration: const BoxDecoration(
                    color: Color(0x33E05A40), shape: BoxShape.circle)),
          ),
          SizedBox(
            width: double.infinity,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.coral,
                  child: Text(initials(name),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 14),
              Text(name,
                  textAlign: TextAlign.center,
                  style: serif(24, color: Colors.white)),
              const SizedBox(height: 3),
              Text(email,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 12.5, color: Colors.white70)),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Your account',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ]),
      );

  Widget _stat(IconData icon, String n, String label) => Expanded(
        child: Panel(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Icon(icon, size: 18, color: AppColors.coral),
            const SizedBox(height: 6),
            Text(n, style: serif(24)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ),
      );

  Widget _tile(IconData icon, String label, VoidCallback onTap,
          {bool danger = false}) =>
      ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: danger ? AppColors.dangerSoft : AppColors.greenSoft,
              borderRadius: BorderRadius.circular(11)),
          child: Icon(icon,
              size: 20, color: danger ? AppColors.danger : AppColors.green),
        ),
        title: Text(label,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: danger ? AppColors.danger : AppColors.ink)),
        trailing: danger
            ? null
            : const Icon(Icons.chevron_right, color: AppColors.muted),
      );

  /// Rounded white block holding several tiles separated by lines.
  Widget _group(List<Widget> tiles) => Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(color: AppColors.line)),
        child: Column(children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const Divider(indent: 66),
            tiles[i],
          ],
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.user!;
    return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _header(user.fullName, user.email),
          const SizedBox(height: 14),
          FutureBuilder<List<Booking>>(
            future: _f,
            builder: (_, s) {
              final b = s.data ?? const <Booking>[];
              return ListenableBuilder(
                listenable: SavedRooms.instance,
                builder: (_, __) => Row(children: [
                  _stat(Icons.event_available_outlined,
                      '${b.where((x) => !x.isPast).length}', 'Upcoming'),
                  const SizedBox(width: 8),
                  _stat(Icons.task_alt_rounded,
                      '${b.where((x) => x.completed).length}', 'Past stays'),
                  const SizedBox(width: 8),
                  _stat(Icons.favorite_border_rounded,
                      '${SavedRooms.instance.ids.length}', 'Saved'),
                ]),
              );
            },
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('MY ACTIVITY', style: overline()),
          ),
          _group([
            _tile(Icons.calendar_today_outlined, 'My bookings',
                () => homeTab.value = tabBookings),
            _tile(Icons.star_outline_rounded, 'My reviews', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyReviewsScreen()));
            }),
            _tile(Icons.favorite_border, 'Saved rooms',
                () => homeTab.value = tabSaved),
          ]),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('PENSION HOUSE', style: overline()),
          ),
          _group([
            _tile(Icons.info_outline, 'Contact & payment details', _about),
          ]),
          const SizedBox(height: 20),
          _group([
            _tile(Icons.logout, 'Sign out', _signOut, danger: true),
          ]),
          const SizedBox(height: 22),
          const Center(
            child: Text('Norberto Pension House',
                style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ),
        ]);
  }
}
