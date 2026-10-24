import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/room.dart';
import '../screens/room_detail_screen.dart';
import 'common.dart';
import 'save_button.dart';

Pill roomStatusPill(Room r) {
  if (r.isMaintenance || r.status == 'MAINTENANCE') {
    return Pill.bad('Under maintenance');
  }
  if (r.status == 'OCCUPIED') return Pill.warn('Occupied now');
  return Pill.good('Available');
}

class RoomCard extends StatelessWidget {
  final Room room;
  const RoomCard({super.key, required this.room});

  void _open(BuildContext c) => Navigator.push(
      c, MaterialPageRoute(builder: (_) => RoomDetailScreen(room: room)));

  @override
  Widget build(BuildContext context) {
    final cheapest = room.cheapest;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(color: Color(0x0F0F3D3A), blurRadius: 14, offset: Offset(0, 6))
        ],
      ),
      child: InkWell(
        onTap: () => _open(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            RoomImage(url: room.cover, height: 170),
            Positioned(top: 12, left: 12, child: roomStatusPill(room)),
            Positioned(top: 10, right: 10, child: SaveButton(roomId: room.id)),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.title, style: serif(18)),
              const SizedBox(height: 2),
              Text(room.meta,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 10),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    cheapest == null
                        ? const Text('Rates unavailable',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.muted))
                        : Text.rich(TextSpan(children: [
                            const TextSpan(
                                text: 'From ',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                            TextSpan(
                                text: peso(cheapest.price), style: serif(18)),
                            TextSpan(
                                text: '  / ${hoursLabel(cheapest.hours)}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                          ])),
                    FilledButton(
                      onPressed: () => _open(context),
                      style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 16)),
                      child: const Text('View room',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
