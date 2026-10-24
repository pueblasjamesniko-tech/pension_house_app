import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/room.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';
import '../widgets/room_card.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  late Future<List<Room>> _f = ApiService.instance.rooms();
  bool _onlyAvailable = false;

  void _reload() => setState(() => _f = ApiService.instance.rooms());

  Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.green,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.line),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.ink),
      );

  @override
  Widget build(BuildContext context) => AsyncView<List<Room>>(
        future: _f,
        onRetry: _reload,
        builder: (all) {
          final rooms = _onlyAvailable
              ? all.where((r) => r.status == 'AVAILABLE').toList()
              : all;
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
                  SectionTitle('Our rooms',
                      '${all.length} room${all.length == 1 ? '' : 's'} · pick a stay that fits you'),
                  const SizedBox(height: 12),
                  Row(children: [
                    _chip('All', !_onlyAvailable,
                        () => setState(() => _onlyAvailable = false)),
                    const SizedBox(width: 8),
                    _chip('Available now', _onlyAvailable,
                        () => setState(() => _onlyAvailable = true)),
                  ]),
                  const SizedBox(height: 14),
                  if (rooms.isEmpty)
                    EmptyState(
                      icon: Icons.bed_outlined,
                      title: all.isEmpty
                          ? 'No rooms yet'
                          : 'No rooms available right now',
                      message: all.isEmpty
                          ? 'Please check back soon.'
                          : 'Try "All" to see every room and book a later time.',
                    ),
                  for (final r in rooms) RoomCard(key: ValueKey(r.id), room: r),
                ]),
          );
        },
      );
}
