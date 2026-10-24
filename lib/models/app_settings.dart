import 'json_utils.dart';

/// GET /api/settings - set by the admin on the web side.
class AppSettings {
  final String? gcashNumber, gcashName, businessName, businessAddress, businessContact;

  const AppSettings({
    this.gcashNumber,
    this.gcashName,
    this.businessName,
    this.businessAddress,
    this.businessContact,
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        gcashNumber: asStrOrNull(j['gcashNumber']),
        gcashName: asStrOrNull(j['gcashName']),
        businessName: asStrOrNull(j['businessName']),
        businessAddress: asStrOrNull(j['businessAddress']),
        businessContact: asStrOrNull(j['businessContact']),
      );
}
