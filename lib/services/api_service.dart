import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:typed_data';
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
///  AUTH      GET auth/id-types · POST auth/register (multipart) · POST auth/login
///            POST guest-auth/forgot-password · POST guest-auth/reset-password
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

  /// The ID types the API accepts (fills the dropdown on the register screen).
  Future<List<String>> idTypes() async {
    final d = await _send('GET', 'auth/id-types', auth: false) as List;
    return [for (final t in d) '$t'];
  }

  /// The API's register is multipart/form-data and REQUIRES an ID type and a
  /// JPG/PNG photo of the ID. It does not return a token, so we sign in after.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String idType,
    required Uint8List idImage,
    required String idFileName,
    String? contactNo,
  }) async {
    final req = http.MultipartRequest(
        'POST', Uri.parse('${Config.baseUrl}/auth/register'))
      ..headers['Accept'] = 'application/json'
      ..fields['FullName'] = fullName.trim()
      ..fields['Email'] = email.trim()
      ..fields['Password'] = password
      ..fields['IdType'] = idType;
    if (contactNo != null && contactNo.trim().isNotEmpty) {
      req.fields['ContactNo'] = contactNo.trim();
    }
    req.files.add(
        http.MultipartFile.fromBytes('IdImage', idImage, filename: idFileName));

    // Uploading a photo can take longer than a normal request.
    await _execute(req, auth: false, timeout: const Duration(seconds: 60));
    await login(email, password);
  }

  /// Forgot password, step 1: the API emails a 6-digit code.
  /// It answers the same for every email (so nobody can find out which emails
  /// have an account). Returns how many seconds to wait before asking again.
  Future<int> forgotPassword(String email) async {
    final d = await _send('POST', 'guest-auth/forgot-password',
        body: {'email': email.trim()}, auth: false);
    if (d is Map && d['resendInSeconds'] is num) {
      return (d['resendInSeconds'] as num).toInt();
    }
    return 60;
  }

  /// Forgot password, step 2: the emailed code + the new password.
  Future<void> resetPassword(String email, String otp, String newPassword) =>
      _send('POST', 'guest-auth/reset-password',
          body: {
            'email': email.trim(),
            'otp': otp.trim(),
            'newPassword': newPassword,
          },
          auth: false);

  Future<void> logout() async {
    _token = null;
    user = null;
    _settings = null;
    _ratings.clear();
    SavedRooms.instance.clear();
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
    await p.remove('user');
  }

  // -------------------------------------------------------------- rooms --

  Future<List<Room>> rooms() async {
    final d = await _send('GET', 'rooms') as List;
    final list = [
      for (final j in d) Room.fromJson(Map<String, dynamic>.from(j as Map))
    ];
    await _loadRatings(list); // so room cards can show stars right away
    return list;
  }

  // Ratings cache: roomId -> summary (average + number of reviews)
  final Map<int, ReviewSummary> _ratings = {};
  ReviewSummary? ratingOf(int roomId) => _ratings[roomId];

  Future<void> _loadRatings(List<Room> rooms) async {
    await Future.wait(rooms.map((r) async {
      try {
        final d = Map<String, dynamic>.from(
            await _send('GET', 'reviews/room/${r.id}') as Map);
        _ratings[r.id] = ReviewSummary.fromJson(
            Map<String, dynamic>.from(d['summary'] as Map));
      } catch (_) {
        // A rating that fails to load must never break the rooms list.
      }
    }));
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

  Future<void> cancelBooking(int id) => _send('PATCH', 'bookings/$id/cancel');

  // ------------------------------------------------------------ reviews --

  /// Booking ids the guest can rate right now (stay is over, not rated yet).
  Future<Set<int>> reviewableBookingIds() async {
    final d = await _send('GET', 'reviews/pending') as List;
    return {for (final j in d) (j['bookingId'] as num).toInt()};
  }

  Future<void> createReview(int bookingId, int rating, String? comment) async {
    await _send('POST', 'reviews', body: {
      'bookingId': bookingId,
      'rating': rating,
      'comment': (comment ?? '').trim().isEmpty ? null : comment!.trim(),
    });
    _ratings.clear(); // refreshed the next time rooms are loaded
  }

  Future<void> updateReview(int id, int rating, String? comment) async {
    await _send('PUT', 'reviews/$id', body: {
      'rating': rating,
      'comment': (comment ?? '').trim().isEmpty ? null : comment!.trim(),
    });
    _ratings.clear();
  }

  Future<List<Review>> myReviews() async {
    final d = await _send('GET', 'reviews/mine') as List;
    return [
      for (final j in d) Review.fromJson(Map<String, dynamic>.from(j as Map))
    ];
  }

  Future<RoomReviews> roomReviews(int roomId) async {
    final d = Map<String, dynamic>.from(
        await _send('GET', 'reviews/room/$roomId') as Map);
    final summary =
        ReviewSummary.fromJson(Map<String, dynamic>.from(d['summary'] as Map));
    _ratings[roomId] = summary;
    return RoomReviews(
      summary,
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

  /// Builds a normal JSON request and runs it.
  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
  }) {
    var uri = Uri.parse('${Config.baseUrl}/$path');
    if (query != null) uri = uri.replace(queryParameters: query);

    final req = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json; charset=utf-8';
      req.body = jsonEncode(body);
    }
    return _execute(req, auth: auth);
  }

  /// Sends any request (JSON or multipart) and turns errors into [ApiException].
  Future<dynamic> _execute(
    http.BaseRequest req, {
    required bool auth,
    Duration? timeout,
  }) async {
    if (auth && _token != null) {
      req.headers['Authorization'] = 'Bearer $_token';
    }

    final http.Response res;
    try {
      res = await http.Response.fromStream(
          await req.send().timeout(timeout ?? Config.requestTimeout));
    } on TimeoutException {
      throw ApiException(
          'The server took too long to respond. Please try again.');
    } on SocketException catch (e) {
      throw ApiException("Can't reach ${req.url}\n${e.message} ${e.osError}");
    } on http.ClientException catch (e) {
      throw ApiException("Can't reach ${req.url}\n${e.message}");
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
      case 413:
        return 'That photo is too large. Please use a smaller one.';
      case 415:
        return 'The server could not read that request. Please update the app.';
      case 429:
        return 'Too many tries. Please wait a little and try again.';
      case 500:
        return 'Something went wrong on the server. Please try again.';
      default:
        return 'Request failed ($status).';
    }
  }
}
