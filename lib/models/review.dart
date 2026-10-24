import 'json_utils.dart';

class Review {
  final int id, bookingId, roomId, rating;
  final String guestName, roomTitle;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Review({
    required this.id,
    required this.bookingId,
    required this.roomId,
    required this.rating,
    required this.guestName,
    required this.roomTitle,
    required this.createdAt,
    this.comment,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: asInt(j['id']),
        bookingId: asInt(j['bookingId']),
        roomId: asInt(j['roomId']),
        rating: asInt(j['rating']),
        guestName: asStr(j['guestName'], 'Guest'),
        roomTitle: asStr(j['roomTitle']),
        comment: asStrOrNull(j['comment']),
        createdAt: asDate(j['createdAt']),
        updatedAt: asDateOrNull(j['updatedAt']),
      );
}

class ReviewSummary {
  final int total;
  final double average;

  /// counts[0] = number of 1-star reviews ... counts[4] = 5-star
  final List<int> counts;

  const ReviewSummary(
      {required this.total, required this.average, required this.counts});

  factory ReviewSummary.fromJson(Map<String, dynamic> j) => ReviewSummary(
        total: asInt(j['total']),
        average: asDouble(j['average']),
        counts: [for (var i = 1; i <= 5; i++) asInt(j['star$i'])],
      );
}

class RoomReviews {
  final ReviewSummary summary;
  final List<Review> reviews;
  const RoomReviews(this.summary, this.reviews);
}
