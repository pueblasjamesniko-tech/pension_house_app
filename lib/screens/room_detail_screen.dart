import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/room.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';
import '../widgets/room_card.dart';
import '../widgets/room_reviews.dart';
import '../widgets/save_button.dart';
import 'checkout_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  const RoomDetailScreen({super.key, required this.room});
  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  Room get r => widget.room;

  late RoomRate? _rate = r.rates.isEmpty ? null : r.rates.first;
  late DateTime _start = _nextHour();
  int _img = 0;

  // Availability (asks the API whether the room is free for the whole stay)
  bool _checking = false;
  bool? _available;
  int _seq = 0;

  static DateTime _nextHour() {
    final n = DateTime.now().add(const Duration(hours: 1));
    return DateTime(n.year, n.month, n.day, n.hour);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check();
    });
  }

  DateTime get _end => _start.add(Duration(hours: _rate?.hours ?? 0));
  bool get _timePassed =>
      _start.isBefore(DateTime.now().subtract(const Duration(minutes: 5)));

  bool get _canReserve =>
      r.bookable &&
      _rate != null &&
      !_timePassed &&
      !_checking &&
      _available != false;

  Future<void> _check() async {
    if (!r.bookable || _rate == null || _timePassed) {
      setState(() {
        _available = null;
        _checking = false;
      });
      return;
    }
    final seq = ++_seq;
    setState(() {
      _checking = true;
      _available = null;
    });
    try {
      final ids =
          await ApiService.instance.availableRoomIds(_start, _rate!.hours);
      if (!mounted || seq != _seq) return;
      setState(() {
        _available = ids.contains(r.id);
        _checking = false;
      });
    } on ApiException {
      // Could not check - the server still validates when booking.
      if (!mounted || seq != _seq) return;
      setState(() {
        _available = null;
        _checking = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);
    final d = await showDatePicker(
        context: context,
        initialDate: _start.isBefore(first) ? first : _start,
        firstDate: first,
        lastDate: first.add(const Duration(days: 90)));
    if (d == null) return;
    setState(() => _start =
        DateTime(d.year, d.month, d.day, _start.hour, _start.minute));
    _check();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (t == null) return;
    setState(() => _start =
        DateTime(_start.year, _start.month, _start.day, t.hour, t.minute));
    _check();
  }

  void _reserve() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              CheckoutScreen(room: r, rate: _rate!, checkIn: _start)));

  Widget _banner() {
    Widget box(Color bg, Color fg, Widget icon, String text) => Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            icon,
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: TextStyle(fontSize: 12.5, color: fg, height: 1.35))),
          ]),
        );

    if (!r.bookable) {
      return box(AppColors.dangerSoft, AppColors.danger,
          const Icon(Icons.build_outlined, size: 18, color: AppColors.danger),
          r.isMaintenance
              ? 'This room is under maintenance and can’t be booked right now.'
              : 'Rates for this room aren’t available yet.');
    }
    if (_timePassed) {
      return box(AppColors.dangerSoft, AppColors.danger,
          const Icon(Icons.schedule, size: 18, color: AppColors.danger),
          'That check-in time has already passed. Pick a later time.');
    }
    if (_checking) {
      return box(
          Colors.white,
          AppColors.muted,
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.green)),
          'Checking availability…');
    }
    if (_available == true) {
      return box(AppColors.successSoft, AppColors.success,
          const Icon(Icons.check_circle, size: 18, color: AppColors.success),
          'Available for your selected time.');
    }
    if (_available == false) {
      return box(AppColors.dangerSoft, AppColors.danger,
          const Icon(Icons.event_busy, size: 18, color: AppColors.danger),
          'Not available for this time. Try another time or a different room.');
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final count = r.photos.isEmpty ? 1 : r.photos.length;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        // ---- photos ----
        SizedBox(
          height: 280,
          child: Stack(children: [
            PageView.builder(
              itemCount: count,
              onPageChanged: (i) => setState(() => _img = i),
              itemBuilder: (_, i) =>
                  RoomImage(url: r.photos.isEmpty ? null : r.photos[i]),
            ),
            Positioned(
              top: top + 8,
              left: 12,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back_rounded,
                          size: 20, color: AppColors.green)),
                ),
              ),
            ),
            Positioned(
                top: top + 8, right: 12, child: SaveButton(roomId: r.id)),
            if (count > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _img ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: i == _img ? Colors.white : Colors.white60,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                ]),
              ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(r.title, style: serif(26))),
              roomStatusPill(r),
            ]),
            const SizedBox(height: 4),
            Text(r.meta,
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
            if (r.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(r.description,
                  style: const TextStyle(fontSize: 13, height: 1.55)),
            ],

            // ---- choose stay ----
            const SizedBox(height: 22),
            Text('Choose your stay', style: serif(19)),
            const SizedBox(height: 10),
            if (r.rates.isEmpty)
              const Text('No rates have been set for this room yet.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted))
            else
              LayoutBuilder(builder: (_, c) {
                final w = (c.maxWidth - 16) / 3;
                return Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final x in r.rates)
                    SizedBox(
                      width: w,
                      child: _RateTile(
                        rate: x,
                        selected: x.id == _rate?.id,
                        onTap: () {
                          setState(() => _rate = x);
                          _check();
                        },
                      ),
                    ),
                ]);
              }),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _Tile('CHECK-IN DATE', fmtDay(_start),
                      icon: Icons.calendar_today_outlined, onTap: _pickDate)),
              const SizedBox(width: 8),
              Expanded(
                  child: _Tile('CHECK-IN TIME', fmtTime(_start),
                      icon: Icons.access_time, onTap: _pickTime)),
            ]),
            const SizedBox(height: 8),
            _Tile('CHECK-OUT', _rate == null ? '—' : fmtWhen(_end),
                icon: Icons.logout_outlined),
            _banner(),

            if (_rate != null) ...[
              const SizedBox(height: 14),
              Panel(
                child: Column(children: [
                  KeyValue(_rate!.label.isEmpty ? hoursLabel(_rate!.hours) : _rate!.label,
                      peso(_rate!.price)),
                  const Divider(height: 18),
                  KeyValue('Total', peso(_rate!.price), bold: true),
                ]),
              ),
            ],

            RoomReviewsSection(roomId: r.id),
            const SizedBox(height: 12),
          ]),
        ),
      ]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total',
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    Text(_rate == null ? '—' : peso(_rate!.price),
                        style: serif(22)),
                  ]),
              const SizedBox(width: 20),
              Expanded(
                  child: PrimaryButton('Reserve',
                      onPressed: _canReserve ? _reserve : null)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RateTile extends StatelessWidget {
  final RoomRate rate;
  final bool selected;
  final VoidCallback onTap;
  const _RateTile(
      {required this.rate, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.coralSoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.coral : AppColors.line,
                width: selected ? 1.5 : 1),
          ),
          child: Column(children: [
            Text(rate.label.isEmpty ? hoursLabel(rate.hours) : rate.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(peso(rate.price),
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.coral : AppColors.muted)),
          ]),
        ),
      );
}

class _Tile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final VoidCallback? onTap;
  const _Tile(this.label, this.value, {required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.line)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(icon, size: 18, color: AppColors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 9.5,
                                letterSpacing: .7,
                                color: AppColors.muted)),
                        const SizedBox(height: 2),
                        Text(value,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                ),
              ]),
            ),
          ),
        ),
      );
}
