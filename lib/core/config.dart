class Config {
  // Android emulator on the SAME machine as the API -> http://10.0.2.2:5300/api
  // Real phone -> http://<API-laptop-IP>:5300/api   (port from launchSettings.json)
  static const _defaultUrl = 'http://10.225.70.192:5300/api';

  static const baseUrl =
      String.fromEnvironment('API_URL', defaultValue: _defaultUrl);

  static const requestTimeout = Duration(seconds: 20);
  static const appName = 'Norberto Pension House';

  /// The server itself (baseUrl without "/api"), e.g. http://10.225.70.192:5300
  static String get origin {
    final u = Uri.parse(baseUrl);
    return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
  }

  static const _selfHosts = {
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '10.0.2.2',
    '::1'
  };

  /// Turns whatever the admin saved as a room photo into an address this
  /// phone can really open.
  static String? resolvePhoto(String? raw) {
    var s = (raw ?? '').trim().replaceAll('\\', '/');
    if (s.isEmpty) return null;

    final drive = RegExp(
            r'drive\.google\.com/(?:file/d/|open\?id=|uc\?(?:export=\w+&)?id=)([\w-]+)')
        .firstMatch(s);
    if (drive != null) {
      return 'https://drive.google.com/uc?export=view&id=${drive.group(1)}';
    }

    s = s.replaceAll(' ', '%20');
    final api = Uri.parse(baseUrl);

    if (s.startsWith('//')) return '${api.scheme}:$s';
    if (s.startsWith('www.')) return 'https://$s';

    final u = Uri.tryParse(s);
    if (u == null) return null;

    if (!u.hasScheme) {
      return '$origin${s.startsWith('/') ? '' : '/'}$s';
    }
    if (_selfHosts.contains(u.host)) {
      return u.replace(host: api.host).toString();
    }
    return s;
  }
}
