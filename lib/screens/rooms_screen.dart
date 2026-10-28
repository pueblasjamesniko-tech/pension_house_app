import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/room.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';
import '../widgets/room_card.dart';

enum _Filter { all, available, topRated }

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  late Future<List<Room>> _f = ApiService.instance.rooms();
  _Filter _filter = _Filter.all;

  void _reload() => setState(() => _f = ApiService.instance.rooms());

  List<Room> _apply(List<Room> all) {
    switch (_filter) {
      case _Filter.available:
        return all.where((r) => r.status == 'AVAILABLE').toList();
      case _Filter.topRated:
        double avg(Room r) {
          final s = ApiService.instance.ratingOf(r.id);
          return (s == null || s.total == 0) ? -1 : s.average;
        }

        int count(Room r) => ApiService.instance.ratingOf(r.id)?.total ?? 0;
        final list = [...all];
        list.sort((a, b) {
          final c = avg(b).compareTo(avg(a));
          return c != 0 ? c : count(b).compareTo(count(a));
        });
        return list;
      case _Filter.all:
        return all;
    }
  }

  Widget _chip(String label, IconData icon, _Filter value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon,
            size: 16, color: selected ? Colors.white : AppColors.green),
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        showCheckmark: false,
        selectedColor: AppColors.green,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? AppColors.green : AppColors.line),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.ink),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.user!;
    return AsyncView<List<Room>>(
      future: _f,
      onRetry: _reload,
      loading: const _RoomsSkeleton(),
      builder: (all) {
        final rooms = _apply(all);
        final freeCount = all.where((r) => r.status == 'AVAILABLE').length;
        return RefreshIndicator(
          color: AppColors.green,
          onRefresh: () async {
            _reload();
            await _f;
          },
          child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _Hero(name: user.fullName),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _chip('All rooms', Icons.apps_rounded, _Filter.all),
                    _chip('Available now · $freeCount',
                        Icons.check_circle_outline, _Filter.available),
                    _chip('Top rated', Icons.star_outline_rounded,
                        _Filter.topRated),
                  ]),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 10),
                  child: Text(
                      '${rooms.length} ${rooms.length == 1 ? 'room' : 'rooms'}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.muted)),
                ),
                if (rooms.isEmpty)
                  EmptyState(
                    icon: Icons.bed_outlined,
                    title: all.isEmpty
                        ? 'No rooms yet'
                        : 'No rooms available right now',
                    message: all.isEmpty
                        ? 'Please check back soon.'
                        : 'Try “All rooms” to see every room and book a later time.',
                  ),
                for (final r in rooms) RoomCard(key: ValueKey(r.id), room: r),
              ]),
        );
      },
    );
  }
}

/// Green greeting card at the top of the Rooms tab.
class _Hero extends StatelessWidget {
  final String name;
  const _Hero({required this.name});

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppShadow.lift),
        child: Stack(children: [
          Positioned(
            right: -34,
            top: -50,
            child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                    color: Color(0x33E05A40), shape: BoxShape.circle)),
          ),
          SizedBox(
            width: double.infinity,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_greeting()}, ${firstName(name)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text('Find your stay', style: serif(30, color: Colors.white)),
              const SizedBox(height: 12),
              const Row(children: [
                Icon(Icons.schedule_rounded, size: 15, color: AppColors.gold),
                SizedBox(width: 6),
                Flexible(
                  child: Text('Book by the hour · pay with GCash',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                ),
              ]),
            ]),
          ),
        ]),
      );
}

/// Placeholder shown while rooms load (nicer than a spinner).
class _RoomsSkeleton extends StatelessWidget {
  const _RoomsSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          const Skeleton(height: 118, radius: 22),
          const SizedBox(height: 16),
          const Row(children: [
            Skeleton(width: 90, height: 34, radius: 20),
            SizedBox(width: 8),
            Skeleton(width: 130, height: 34, radius: 20),
          ]),
          const SizedBox(height: 22),
          for (var i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.line),
              ),
              child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(height: 190, radius: 0),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Skeleton(width: 180, height: 18),
                            SizedBox(height: 10),
                            Skeleton(width: 120, height: 12),
                          ]),
                    ),
                  ]),
            ),
        ],
      );
}
