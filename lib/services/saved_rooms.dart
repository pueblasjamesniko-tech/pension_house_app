import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The API has no "favorites" endpoint, so saved rooms are kept on the phone
/// (per signed-in guest).
class SavedRooms extends ChangeNotifier {
  SavedRooms._();
  static final instance = SavedRooms._();

  int? _userId;
  Set<int> _ids = {};

  Set<int> get ids => Set.unmodifiable(_ids);
  bool has(int roomId) => _ids.contains(roomId);

  String get _key => 'saved_rooms_$_userId';

  Future<void> load(int userId) async {
    _userId = userId;
    final p = await SharedPreferences.getInstance();
    _ids = {
      for (final s in p.getStringList(_key) ?? const <String>[])
        if (int.tryParse(s) != null) int.parse(s)
    };
    notifyListeners();
  }

  void clear() {
    _userId = null;
    _ids = {};
    notifyListeners();
  }

  Future<void> toggle(int roomId) async {
    if (_userId == null) return;
    _ids = {..._ids};
    if (!_ids.remove(roomId)) _ids.add(roomId);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, [for (final i in _ids) '$i']);
  }
}
