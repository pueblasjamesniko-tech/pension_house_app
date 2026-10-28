import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check();
    });
  }

  DateTime get _endTime => _start.add(Duration(hours: _rate?.hours ?? 0));
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

  void _setDay(DateTime d) {
    var s = DateTime(d.year, d.month, d.day, _start.hour, _start.minute);
    // Picking today with a time that already passed -> jump to the next hour.
    if (s.isBefore(DateTime.now()) && _sameDay(s, DateTime.now())) {
      s = _nextHour();
    }
    setState(() => _start = s);
    _check();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);
    final d = await showDatePicker(
        context: context,
        initialDate: _start.isBefore(first) ? first : _start,
        firstDate: first,
        lastDate: first.add(const Duration(days: 90)));
    if (d != null) _setDay(d);
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

  // ---- small pieces ----------------------------------------------------

  Widget _infoChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: AppColors.green),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ]),
      );

  Widget _dot(Color c) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _endpoint(String label, DateTime d, {bool right = false}) => Column(
          crossAxisAlignment:
              right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(label, style: overline()),
            const SizedBox(height: 4),
            Text(fmtTime(d), style: serif(21)),
            Text(fmtDay(d),
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ]);

  Widget _banner() {
    Widget box(Color bg, Color fg, Widget icon, String text) => Container(
          margin: const EdgeInsets.only(top: 14),
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
      return box(
          AppColors.dangerSoft,
          AppColors.danger,
          const Icon(Icons.build_outlined, size: 18, color: AppColors.danger),
          r.isMaintenance
              ? 'This room is under maintenance and can’t be booked right now.'
              : 'Rates for this room aren’t available yet.');
    }
    if (_timePassed) {
      return box(
          AppColors.dangerSoft,
          AppColors.danger,
          const Icon(Icons.schedule, size: 18, color: AppColors.danger),
          'That check-in time has already passed. Pick a later time.');
    }
    if (_checking) {
      return box(
          AppColors.sand,
          AppColors.muted,
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.green)),
          'Checking availability…');
    }
    if (_available == true) {
      return box(
          AppColors.successSoft,
          AppColors.success,
          const Icon(Icons.check_circle, size: 18, color: AppColors.success),
          'Available for your selected time.');
    }
    if (_available == false) {
      return box(
          AppColors.dangerSoft,
          AppColors.danger,
          const Icon(Icons.event_busy, size: 18, color: AppColors.danger),
          'Not available for this time. Try another time or a different room.');
    }
    return const SizedBox.shrink();
  }

  Widget _daySelector() {
    final t = DateTime.now();
    final days = List.generate(14, (i) => DateTime(t.year, t.month, t.day + i));
    final inStrip = days.any((d) => _sameDay(d, _start));

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i < days.length) {
            return _DayChip(
              day: days[i],
              isToday: i == 0,
              selected: _sameDay(days[i], _start),
              onTap: () => _setDay(days[i]),
            );
          }
          return _MoreDaysChip(
            selected: !inStrip,
            label: inStrip ? 'More' : DateFormat('MMM d').format(_start),
            onTap: _pickDate,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = r.photos.isEmpty ? 1 : r.photos.length;
    final freeAt = r.status == 'OCCUPIED' ? r.currentCheckOut : null;

    return Scaffold(
      body: CustomScrollView(slivers: [
        // ---- photo gallery that collapses while scrolling ----
        SliverAppBar(
          pinned: true,
          expandedHeight: 300,
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.cream,
          shape: const Border(),
          leadingWidth: 60,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.pop(context)),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SaveButton(roomId: r.id),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(22),
            child: Container(
              height: 22,
              decoration: const BoxDecoration(
                  color: AppColors.cream,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24))),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(fit: StackFit.expand, children: [
              PageView.builder(
                itemCount: count,
                onPageChanged: (i) => setState(() => _img = i),
                itemBuilder: (_, i) =>
                    RoomImage(url: r.photos.isEmpty ? null : r.photos[i]),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 100,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x66000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
              ),
              if (count > 1)
                Positioned(
                  right: 16,
                  bottom: 36,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: const Color(0x99000000),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('${_img + 1} / $count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ---- title ----
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(r.title, style: serif(27))),
                const SizedBox(width: 8),
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: roomStatusPill(r)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line)),
                  child: RatingBadge(roomId: r.id),
                ),
                _infoChip(Icons.meeting_room_outlined, 'Room ${r.roomNo}'),
                _infoChip(Icons.people_outline,
                    'Fits ${r.capacity} guest${r.capacity == 1 ? '' : 's'}'),
              ]),
              if (freeAt != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.schedule_rounded,
                        size: 18, color: Color(0xFF8A5B00)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'A guest is staying now. This room is free again ${fmtWhen(freeAt)}.',
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: Color(0xFF8A5B00))),
                    ),
                  ]),
                ),
              ],
              if (r.description.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('About this room', style: serif(19)),
                const SizedBox(height: 8),
                Text(r.description,
                    style: const TextStyle(fontSize: 13, height: 1.6)),
              ],

              // ---- 1. how long ----
              const SizedBox(height: 26),
              Text('1 · How long will you stay?', style: serif(19)),
              const SizedBox(height: 12),
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

              // ---- 2. when ----
              const SizedBox(height: 26),
              Text('2 · When are you arriving?', style: serif(19)),
              const SizedBox(height: 12),
              _daySelector(),
              const SizedBox(height: 10),
              _Tile('CHECK-IN TIME', fmtTime(_start),
                  icon: Icons.access_time_rounded, onTap: _pickTime),

              // ---- 3. summary ----
              if (_rate != null) ...[
                const SizedBox(height: 26),
                Text('3 · Your stay', style: serif(19)),
                const SizedBox(height: 12),
                Panel(
                  child: Column(children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _endpoint('CHECK-IN', _start),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(children: [
                                Text(hoursLabel(_rate!.hours),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.coral)),
                                const SizedBox(height: 8),
                                Row(children: [
                                  _dot(AppColors.green),
                                  Expanded(
                                      child: Container(
                                          height: 1.5, color: AppColors.line)),
                                  _dot(AppColors.coral),
                                ]),
                              ]),
                            ),
                          ),
                          _endpoint('CHECK-OUT', _endTime, right: true),
                        ]),
                    _banner(),
                    const Divider(height: 28),
                    KeyValue(
                        _rate!.label.isEmpty
                            ? hoursLabel(_rate!.hours)
                            : _rate!.label,
                        peso(_rate!.price)),
                    KeyValue('Total', peso(_rate!.price), bold: true),
                  ]),
                ),
              ],

              RoomReviewsSection(roomId: r.id),
            ]),
          ),
        ),
      ]),

      // ---- sticky reserve bar ----
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL', style: overline()),
                    const SizedBox(height: 2),
                    Text(_rate == null ? '—' : peso(_rate!.price),
                        style: serif(23)),
                  ]),
              const SizedBox(width: 20),
              Expanded(
                  child: PrimaryButton('Reserve',
                      icon: Icons.arrow_forward_rounded,
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
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.coralSoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? AppColors.coral : AppColors.line,
                width: selected ? 1.6 : 1),
          ),
          child: Column(children: [
            Text(rate.label.isEmpty ? hoursLabel(rate.hours) : rate.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(peso(rate.price),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.coral : AppColors.green)),
          ]),
        ),
      );
}

class _DayChip extends StatelessWidget {
  final DateTime day;
  final bool isToday, selected;
  final VoidCallback onTap;
  const _DayChip(
      {required this.day,
      required this.isToday,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sub = selected ? Colors.white70 : AppColors.muted;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 60,
        decoration: BoxDecoration(
          color: selected ? AppColors.green : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: selected ? AppColors.green : AppColors.line),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(isToday ? 'TODAY' : DateFormat('EEE').format(day).toUpperCase(),
              style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: .6,
                  fontWeight: FontWeight.w600,
                  color: sub)),
          const SizedBox(height: 3),
          Text('${day.day}',
              style:
                  serif(21, color: selected ? Colors.white : AppColors.green)),
          const SizedBox(height: 1),
          Text(DateFormat('MMM').format(day),
              style: TextStyle(fontSize: 10, color: sub)),
        ]),
      ),
    );
  }
}

class _MoreDaysChip extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;
  const _MoreDaysChip(
      {required this.selected, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 66,
          decoration: BoxDecoration(
            color: selected ? AppColors.green : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: selected ? AppColors.green : AppColors.line),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.calendar_month_rounded,
                size: 22, color: selected ? Colors.white : AppColors.green),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.ink)),
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
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.line)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(icon, size: 20, color: AppColors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: overline()),
                        const SizedBox(height: 3),
                        Text(value,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right, color: AppColors.muted),
              ]),
            ),
          ),
        ),
      );
}
