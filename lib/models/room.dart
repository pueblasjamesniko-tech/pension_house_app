import '../core/config.dart';
import 'json_utils.dart';

/// One price option of a room, e.g. "3 hours" - ₱500
class RoomRate {
  final int id, hours;
  final String label;
  final double price;

  const RoomRate({
    required this.id,
    required this.hours,
    required this.label,
    required this.price,
  });

  factory RoomRate.fromJson(Map<String, dynamic> j) => RoomRate(
        id: asInt(j['id']),
        hours: asInt(j['hours']),
        label: asStr(j['label']),
        price: asDouble(j['price']),
      );
}

/// Matches the API's Room.
class Room {
  final int id, capacity;
  final String roomNo, title, description;

  /// AVAILABLE · OCCUPIED · MAINTENANCE
  final String status;
  final bool isMaintenance;
  final List<String> photos;
  final List<RoomRate> rates;
  final DateTime? currentCheckOut;

  const Room({
    required this.id,
    required this.capacity,
    required this.roomNo,
    required this.title,
    required this.description,
    required this.status,
    required this.isMaintenance,
    required this.photos,
    required this.rates,
    this.currentCheckOut,
  });

  RoomRate? get cheapest =>
      rates.isEmpty ? null : rates.reduce((a, b) => a.price <= b.price ? a : b);

  String? get cover => photos.isEmpty ? null : photos.first;

  bool get bookable => !isMaintenance && rates.isNotEmpty;

  String get meta =>
      'Room $roomNo · fits $capacity guest${capacity == 1 ? '' : 's'}';

  factory Room.fromJson(Map<String, dynamic> j) {
    // Photos are saved by the admin as web addresses; make each one openable
    // from this phone (see Config.resolvePhoto) and drop empties/duplicates.
    final photos = <String>[];
    void add(Object? raw) {
      final u = Config.resolvePhoto(raw == null ? null : '$raw');
      if (u != null && !photos.contains(u)) photos.add(u);
    }

    final cover = asStrOrNull(j['imageUrl']);
    for (final p in (j['photos'] as List? ?? const [])) {
      add(p is Map ? (p['url'] ?? p['Url']) : p);
    }
    if (photos.isEmpty) add(cover);

    final rates = [
      for (final r in (j['rates'] as List? ?? const []))
        if ((r as Map)['isActive'] != false)
          RoomRate.fromJson(Map<String, dynamic>.from(r))
    ]..sort((a, b) => a.hours.compareTo(b.hours));

    return Room(
      id: asInt(j['id']),
      capacity: asInt(j['capacity'], 1),
      roomNo: asStr(j['roomNo']),
      title: asStr(j['title']),
      description: asStr(j['description']),
      status: asStr(j['status'], 'AVAILABLE').toUpperCase(),
      isMaintenance: j['isMaintenance'] == true,
      photos: photos,
      rates: rates,
      currentCheckOut: asDateOrNull(j['currentCheckOut']),
    );
  }
}
