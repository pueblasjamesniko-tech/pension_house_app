import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/room.dart';
import '../screens/room_detail_screen.dart';
import '../services/api_service.dart';
import 'common.dart';
import 'save_button.dart';

Pill roomStatusPill(Room r) {
  if (r.isMaintenance || r.status == 'MAINTENANCE') {
    return Pill.bad('Under maintenance');
  }
  if (r.status == 'OCCUPIED') return Pill.warn('Occupied now');
  return Pill.good('Available');
}

/// ★ 4.6 (12)  ·  shows "New" when nobody has rated the room yet.
class RatingBadge extends StatelessWidget {
  final int roomId;
  const RatingBadge({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final s = ApiService.instance.ratingOf(roomId);
    if (s == null || s.total == 0) {
      return const Text('New',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star_rounded, size: 18, color: AppColors.gold),
      const SizedBox(width: 2),
      Text(s.average.toStringAsFixed(1),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(width: 3),
      Text('(${s.total})',
          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ]);
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta(this.icon, this.text);
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]);
}

class RoomCard extends StatelessWidget {
  final Room room;
  const RoomCard({super.key, required this.room});

  void _open(BuildContext c) => Navigator.push(
      c, MaterialPageRoute(builder: (_) => RoomDetailScreen(room: room)));

  @override
  Widget build(BuildContext context) {
    final cheapest = room.cheapest;
    final freeAt = room.status == 'OCCUPIED' ? room.currentCheckOut : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadow.lift),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(color: AppColors.line)),
        child: InkWell(
          onTap: () => _open(context),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ---- photo with price on it ----
            Stack(children: [
              RoomImage(url: room.cover, height: 190),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xA6000000)],
                        stops: [0.45, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(top: 12, left: 12, child: roomStatusPill(room)),
              if (room.photos.length > 1)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0x99000000),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.photo_library_outlined,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                      Text('${room.photos.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              Positioned(
                  top: 10, right: 10, child: SaveButton(roomId: room.id)),
              Positioned(
                left: 16,
                bottom: 12,
                child: cheapest == null
                    ? const Text('Rates unavailable',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text('FROM',
                                style: overline(color: Colors.white70)),
                            Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: peso(cheapest.price),
                                  style: serif(22, color: Colors.white)),
                              TextSpan(
                                  text: '  / ${hoursLabel(cheapest.hours)}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white70)),
                            ])),
                          ]),
              ),
            ]),

            // ---- details ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Text(room.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: serif(19))),
                          const SizedBox(width: 8),
                          RatingBadge(roomId: room.id),
                        ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _Meta(Icons.meeting_room_outlined, 'Room ${room.roomNo}'),
                      const SizedBox(width: 16),
                      _Meta(Icons.people_outline,
                          '${room.capacity} guest${room.capacity == 1 ? '' : 's'}'),
                      const Spacer(),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                            color: AppColors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded,
                            size: 19, color: Colors.white),
                      ),
                    ]),
                    if (freeAt != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                            color: AppColors.goldSoft,
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: Color(0xFF8A5B00)),
                          const SizedBox(width: 6),
                          Text('Free again ${fmtWhen(freeAt)}',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8A5B00))),
                        ]),
                      ),
                    ],
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}
