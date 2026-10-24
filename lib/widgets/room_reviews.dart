import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import 'common.dart';

/// Play-Store-style rating summary + latest reviews for one room.
/// Loads itself; if it fails it quietly hides (reviews are a bonus).
class RoomReviewsSection extends StatefulWidget {
  final int roomId;
  const RoomReviewsSection({super.key, required this.roomId});
  @override
  State<RoomReviewsSection> createState() => _RoomReviewsSectionState();
}

class _RoomReviewsSectionState extends State<RoomReviewsSection> {
  late final Future<RoomReviews> _f =
      ApiService.instance.roomReviews(widget.roomId);

  @override
  Widget build(BuildContext context) => FutureBuilder<RoomReviews>(
        future: _f,
        builder: (_, s) {
          if (!s.hasData) {
            return s.hasError
                ? const SizedBox.shrink()
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.green))));
          }
          final d = s.data!;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 22),
            Text('Guest reviews', style: serif(19)),
            const SizedBox(height: 10),
            if (d.summary.total == 0)
              const Panel(
                  child: Text('No reviews yet. Be the first to rate this room!',
                      style: TextStyle(fontSize: 12.5, color: AppColors.muted)))
            else ...[
              _Summary(d.summary),
              const SizedBox(height: 10),
              for (final r in d.reviews.take(5)) _ReviewTile(r),
            ],
          ]);
        },
      );
}

class _Summary extends StatelessWidget {
  final ReviewSummary s;
  const _Summary(this.s);

  @override
  Widget build(BuildContext context) {
    final max = s.counts.fold<int>(1, (a, b) => b > a ? b : a);
    return Panel(
      child: Row(children: [
        Column(children: [
          Text(s.average.toStringAsFixed(1), style: serif(34)),
          StarRating(s.average, size: 15),
          const SizedBox(height: 4),
          Text('${s.total} review${s.total == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
        const SizedBox(width: 20),
        Expanded(
          child: Column(children: [
            for (var star = 5; star >= 1; star--)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(children: [
                  Text('$star',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.counts[star - 1] / max,
                        minHeight: 6,
                        backgroundColor: AppColors.greenSoft,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review r;
  const _ReviewTile(this.r);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Panel(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.green,
                  child: Text(initials(r.guestName),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600))),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(r.guestName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600))),
              Text(fmtShort(r.createdAt),
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
            const SizedBox(height: 8),
            StarRating(r.rating.toDouble(), size: 15),
            if (r.comment != null) ...[
              const SizedBox(height: 6),
              Text(r.comment!,
                  style: const TextStyle(fontSize: 12.5, height: 1.45)),
            ],
          ]),
        ),
      );
}
