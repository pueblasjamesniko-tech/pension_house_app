import 'json_utils.dart';

/// Matches the API's AuthResponse: { role, id, fullName, email, token }
class User {
  final int id;
  final String fullName, email, role;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.role = 'user',
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: asInt(j['id']),
        fullName: asStr(j['fullName']),
        email: asStr(j['email']),
        role: asStr(j['role'], 'user'),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'fullName': fullName, 'email': email, 'role': role};
}
