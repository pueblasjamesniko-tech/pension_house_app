import 'json_utils.dart';

enum BookingTone { waiting, good, active, bad, neutral }

/// Matches the API's BookingDetail.
class Booking {
  final int id, roomId, rateId;
  final String bookingCode, roomNo, roomTitle, rateLabel, status;
  final String? paymentMethod, paymentStatus, referenceCode;
  final DateTime checkIn, checkOut;
  final double totalAmount;

  const Booking({
    required this.id,
    required this.roomId,
    required this.rateId,
    required this.bookingCode,
    required this.roomNo,
    required this.roomTitle,
    required this.rateLabel,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.totalAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.referenceCode,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: asInt(j['id']),
        roomId: asInt(j['roomId']),
        rateId: asInt(j['rateId']),
        bookingCode: asStr(j['bookingCode']),
        roomNo: asStr(j['roomNo']),
        roomTitle: asStr(j['roomTitle']),
        rateLabel: asStr(j['rateLabel']),
        status: asStr(j['status']).toUpperCase(),
        checkIn: asDate(j['checkIn']),
        checkOut: asDate(j['checkOut']),
        totalAmount: asDouble(j['totalAmount']),
        paymentMethod: asStrOrNull(j['paymentMethod']),
        paymentStatus: asStrOrNull(j['paymentStatus'])?.toUpperCase(),
        referenceCode: asStrOrNull(j['referenceCode']),
      );

  // ---- status helpers (API statuses: CHECKED_IN, COMPLETED, CANCELLED, else = reserved) ----
  bool get cancelled => status == 'CANCELLED';
  bool get completed => status == 'COMPLETED';
  bool get checkedIn => status == 'CHECKED_IN';
  bool get isPast => cancelled || completed;
  bool get paymentRejected => paymentStatus == 'REJECTED';
  bool get paymentApproved => paymentStatus == 'APPROVED';

  /// The guest may cancel only before check-in (the server makes the final call).
  bool get canCancel => !isPast && !checkedIn;

  int get hours => checkOut.difference(checkIn).inHours;

  String get statusLabel {
    if (cancelled) return 'Cancelled';
    if (completed) return 'Completed';
    if (checkedIn) return 'Checked in';
    if (paymentRejected) return 'Payment rejected';
    if (paymentApproved) return 'Confirmed';
    return 'Awaiting payment check';
  }

  BookingTone get tone {
    if (cancelled) return BookingTone.neutral;
    if (completed) return BookingTone.neutral;
    if (checkedIn) return BookingTone.active;
    if (paymentRejected) return BookingTone.bad;
    if (paymentApproved) return BookingTone.good;
    return BookingTone.waiting;
  }

  String get paymentLabel {
    switch (paymentStatus) {
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        return 'Pending review';
    }
  }

  /// Short line used in the "Updates" list.
  String get statusMessage {
    if (cancelled) return 'This booking was cancelled.';
    if (completed) return 'Your stay is complete. Thanks for staying with us!';
    if (checkedIn) return 'You are checked in. Enjoy your stay!';
    if (paymentRejected) {
      return 'We could not verify your GCash payment. Please contact the front desk.';
    }
    if (paymentApproved) return 'Payment confirmed. See you soon!';
    return 'Waiting for staff to verify your GCash payment.';
  }
}
