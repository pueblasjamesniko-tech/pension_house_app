import 'json_utils.dart';

/// GET /api/settings - set by the admin on the web side.
class AppSettings {
  final String? gcashNumber,
      gcashName,
      businessName,
      businessAddress,
      businessContact;

  /// True when the owner has uploaded a GCash QR image.
  /// [gcashQrVersion] changes with every upload, so the app knows to reload it.
  final bool hasGcashQr;
  final String? gcashQrVersion;

  const AppSettings({
    this.gcashNumber,
    this.gcashName,
    this.businessName,
    this.businessAddress,
    this.businessContact,
    this.hasGcashQr = false,
    this.gcashQrVersion,
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        gcashNumber: asStrOrNull(j['gcashNumber']),
        gcashName: asStrOrNull(j['gcashName']),
        businessName: asStrOrNull(j['businessName']),
        businessAddress: asStrOrNull(j['businessAddress']),
        businessContact: asStrOrNull(j['businessContact']),
        hasGcashQr: j['hasGcashQr'] == true,
        gcashQrVersion: asStrOrNull(j['gcashQrVersion']),
      );
}
