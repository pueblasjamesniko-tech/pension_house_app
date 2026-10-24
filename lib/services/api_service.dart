import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../models/app_settings.dart';
import '../models/booking.dart';
import '../models/review.dart';
import '../models/room.dart';
import '../models/user.dart';
import 'saved_rooms.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// Every call to the PensionHouse.API lives here.
///
///  AUTH      POST auth/register · POST auth/login
///  ROOMS     GET rooms · GET rooms/available?checkIn=&hours=
///  BOOKINGS  POST bookings · GET bookings/mine · GET bookings/{id}
///            PATCH bookings/{id}/cancel
///  REVIEWS   GET reviews/pending · POST reviews · PUT reviews/{id}
///            GET reviews/mine · GET reviews/room/{roomId}
///  SETTINGS  GET settings (GCash name/number, business info)
///
/// Errors from the API look like { "message": "..." } and are turned into
/// [ApiException] with that message so screens can just show it.
class ApiService {
  ApiService._();
  static final instance = ApiService._();

  String? _token;
  User? user;
  AppSettings? _settings;

  /// Bumps when the server says our token is no longer valid (401).
  final sessionExpired = ValueNotifier<int>(0);

  bool get signedIn => _token != null && user != null;

  // ------------------------------------------------------------ session --

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('token');
    final u = p.getString('user');
    if (t == null || u == null || _isExpired(t)) {
      await p.remove('token');
      await p.remove('user');
      return;
    }
    try {
      user = User.fromJson(jsonDecode(u) as Map<String, dynamic>);
      _token = t;
      await SavedRooms.instance.load(user!.id);
    } catch (_) {
      await logout();
    }
  }

  /// Reads the "exp" claim of the JWT so we never start with a dead token.
  static bool _isExpired(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
          as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! num) return false;
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000)
          .isBefore(DateTime.now().add(const Duration(minutes: 1)));
    } catch (_) {
      return true;
    }
  }

  Future<void> login(String email, String password) async {
    final d = await _send('POST', 'auth/login',
        body: {'email': email.trim(), 'password': password},
        auth: false) as Map<String, dynamic>;

    if (asRole(d['role']) != 'user') {
      throw ApiException(
          'This app is for guests. Staff and admins please use the web system.');
    }
    final u = User.fromJson(d);
    final token = '${d['token'] ?? ''}';
    if (token.isEmpty) throw ApiException('Sign in failed. Please try again.');

    _token = token;
    user = u;
    _settings = null;
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token);
    await p.setString('user', jsonEncode(u.toJson()));
    await SavedRooms.instance.load(u.id);
  }

  /// The API's register does not return a token, so we sign in right after.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? contactNo,
  }) async {
    await _send('POST', 'auth/register', auth: false, body: {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'password': password,
      if (contactNo != null && contactNo.trim().isNotEmpty)
        'contactNo': contactNo.trim(),
    });
    await login(email, password);
  }

  Future<void> logout() async {
    _token = null;
    user = null;
    _settings = null;
    SavedRooms.instance.clear();
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
    await p.remove('user');
  }

  // -------------------------------------------------------------- rooms --

  Future<List<Room>> rooms() async {
    final d = await _send('GET', 'rooms') as List;
    return [
      for (final j in d) Room.fromJson(Map<String, dynamic>.from(j as Map))
    ];
  }

  /// Ids of rooms that are free for the whole stay (no overlapping booking).
  Future<Set<int>> availableRoomIds(DateTime checkIn, int hours) async {
    final d = await _send('GET', 'rooms/available',
        query: {'checkIn': apiDateTime(checkIn), 'hours': '$hours'}) as List;
    return {
      for (final j in d) Room.fromJson(Map<String, dynamic>.from(j as Map)).id
    };
  }

  // ----------------------------------------------------------- bookings --

  Future<List<Booking>> myBookings() async {
    final d = await _send('GET', 'bookings/mine') as List;
    return [
      for (final j in d) Booking.fromJson(Map<String, dynamic>.from(j as Map))
    ];
  }

  Future<Booking> booking(int id) async => Booking.fromJson(
      Map<String, dynamic>.from(await _send('GET', 'bookings/$id') as Map));

  /// Returns the new booking id.
  Future<int> createBooking({
    required int roomId,
    required int rateId,
    required DateTime checkIn,
    required String referenceCode,
  }) async {
    final d = await _send('POST', 'bookings', body: {
      'roomId': roomId,
      'rateId': rateId,
      'checkIn': apiDateTime(checkIn),
      'referenceCode': referenceCode.trim(),
    }) as Map;
    return (d['id'] as num).toInt();
  }

  Future<void> cancelBooking(int id) =>
      _send('PATCH', 'bookings/$id/cancel');

  // ------------------------------------------------------------ reviews --

  /// Booking ids the guest can rate right now (stay is over, not rated yet).
  Future<Set<int>> reviewableBookingIds() async {
    final d = await _send('GET', 'reviews/pending') as List;
    return {for (final j in d) (j['bookingId'] as num).toInt()};
  }

  Future<void> createReview(int bookingId, int rating, String? comment) =>
      _send('POST', 'reviews', body: {
        'bookingId': bookingId,
        'rating': rating,
        'comment': (comment ?? '').trim().isEmpty ? null : comment!.trim(),
      });

  Future<void> updateReview(int id, int rating, String? comment) =>
      _send('PUT', 'reviews/$id', body: {
        'rating': rating,
        'comment': (comment ?? '').trim().isEmpty ? null : comment!.trim(),
      });

  Future<List<Review>> myReviews() async {
    final d = await _send('GET', 'reviews/mine') as List;
    return [
      for (final j in d) Review.fromJson(Map<String, dynamic>.from(j as Map))
    ];
  }

  Future<RoomReviews> roomReviews(int roomId) async {
    final d = Map<String, dynamic>.from(
        await _send('GET', 'reviews/room/$roomId') as Map);
    return RoomReviews(
      ReviewSummary.fromJson(Map<String, dynamic>.from(d['summary'] as Map)),
      [
        for (final j in (d['reviews'] as List? ?? const []))
          Review.fromJson(Map<String, dynamic>.from(j as Map))
      ],
    );
  }

  // ----------------------------------------------------------- settings --

  Future<AppSettings> settings({bool refresh = false}) async {
    if (!refresh && _settings != null) return _settings!;
    final d = await _send('GET', 'settings') as Map;
    return _settings = AppSettings.fromJson(Map<String, dynamic>.from(d));
  }

  // --------------------------------------------------------------- http --

  static String asRole(dynamic r) => '$r'.trim().toLowerCase();

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    var uri = Uri.parse('${Config.baseUrl}/$path');
    if (query != null) uri = uri.replace(queryParameters: query);

    final req = http.Request(method, uri)
      ..headers['Accept'] = 'application/json'
      ..headers.addAll({
        if (body != null) 'Content-Type': 'application/json; charset=utf-8',
        if (auth && _token != null) 'Authorization': 'Bearer $_token',
      });
    if (body != null) req.body = jsonEncode(body);

    final http.Response res;
    try {
      res = await http.Response.fromStream(
          await req.send().timeout(Config.requestTimeout));
    } on TimeoutException {
      throw ApiException(
          'The server took too long to respond. Please try again.');
    } on SocketException {
      throw ApiException(
          "Can't reach the server. Check your Wi-Fi and the API address.");
    } on http.ClientException {
      throw ApiException(
          "Can't reach the server. Check your Wi-Fi and the API address.");
    }

    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {}
    }

    // Token rejected -> sign out and let the app show the login screen.
    if (res.statusCode == 401 && auth && _token != null) {
      await logout();
      sessionExpired.value++;
      throw ApiException(
          'Your session expired. Please sign in again.', res.statusCode);
    }

    if (res.statusCode >= 300) {
      throw ApiException(_errorMessage(data, res.statusCode), res.statusCode);
    }
    return data;
  }

  /// Understands { "message": ... } and ASP.NET validation errors.
  static String _errorMessage(dynamic data, int status) {
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return '${first.first}';
      }
      final t = data['title'];
      if (t is String && t.isNotEmpty) return t;
    }
    switch (status) {
      case 403:
        return "You don't have permission to do that.";
      case 404:
        return 'We could not find that.';
      case 500:
        return 'Something went wrong on the server. Please try again.';
      default:
        return 'Request failed ($status).';
    }
  }
}
