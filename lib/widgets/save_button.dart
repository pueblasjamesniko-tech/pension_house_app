import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/saved_rooms.dart';

/// Heart button. Saved rooms are stored on the phone (see SavedRooms).
class SaveButton extends StatelessWidget {
  final int roomId;
  const SaveButton({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: SavedRooms.instance,
        builder: (_, __) {
          final saved = SavedRooms.instance.has(roomId);
          return Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black26,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => SavedRooms.instance.toggle(roomId),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(saved ? Icons.favorite : Icons.favorite_border,
                    size: 20, color: AppColors.coral),
              ),
            ),
          );
        },
      );
}
