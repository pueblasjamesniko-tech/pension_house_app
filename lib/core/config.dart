/// App-wide settings.
///
/// The API runs on the OTHER laptop, so the phone must use that laptop's
/// IP address on the same Wi-Fi, e.g. http://192.168.1.20:5231/api
///
/// Change [_defaultUrl] below, OR pass it when running:
///   flutter run --dart-define=API_URL=http://192.168.1.20:5231/api
class Config {
  // Android emulator on the SAME machine as the API -> http://10.0.2.2:5231/api
  // Real phone -> http://<API-laptop-IP>:5231/api   (port from launchSettings.json)
  static const _defaultUrl = 'http://10.84.96.192:5300/api';

  static const baseUrl =
      String.fromEnvironment('API_URL', defaultValue: _defaultUrl);

  static const requestTimeout = Duration(seconds: 20);
  static const appName = 'Norberto Pension House';
}
