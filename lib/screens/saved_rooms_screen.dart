import 'package:flutter/material.dart';
import '../core/nav.dart';
import '../core/theme.dart';
import '../models/room.dart';
import '../services/api_service.dart';
import '../services/saved_rooms.dart';
import '../widgets/common.dart';
import '../widgets/room_card.dart';

class SavedRoomsScreen extends StatefulWidget {
  const SavedRoomsScreen({super.key});
  @override
  State<SavedRoomsScreen> createState() => _SavedRoomsScreenState();
}

class _SavedRoomsScreenState extends State<SavedRoomsScreen> {
  late Future<List<Room>> _f = ApiService.instance.rooms();
  void _reload() => setState(() => _f = ApiService.instance.rooms());

  @override
  Widget build(BuildContext context) => AsyncView<List<Room>>(
        future: _f,
        onRetry: _reload,
        builder: (all) => ListenableBuilder(
          listenable: SavedRooms.instance,
          builder: (_, __) {
            final rooms =
                all.where((r) => SavedRooms.instance.has(r.id)).toList();
            return RefreshIndicator(
              color: AppColors.green,
              onRefresh: () async {
                _reload();
                await _f;
              },
              child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    SectionTitle(
                        'Saved rooms',
                        rooms.isEmpty
                            ? 'Keep your favourites here'
                            : '${rooms.length} saved'),
                    const SizedBox(height: 14),
                    if (rooms.isEmpty)
                      EmptyState(
                        icon: Icons.favorite_border,
                        title: 'No saved rooms',
                        message:
                            'Tap the heart on a room to keep it here for later.',
                        action: 'Browse rooms',
                        onAction: () => homeTab.value = tabRooms,
                      ),
                    for (final r in rooms)
                      RoomCard(key: ValueKey(r.id), room: r),
                  ]),
            );
          },
        ),
      );
}
