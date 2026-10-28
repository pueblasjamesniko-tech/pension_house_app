import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import 'common.dart';

String ratingWord(double avg) {
  if (avg >= 4.5) return 'Excellent';
  if (avg >= 3.5) return 'Very good';
  if (avg >= 2.5) return 'Good';
  if (avg >= 1.5) return 'Fair';
  return 'Poor';
}

/// Rating summary + latest reviews for one room.
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

  void _showAll(RoomReviews d) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.cream,
        shape: sheetShape(),
        builder: (_) => SizedBox(
          height: MediaQuery.of(context).size.height * .85,
          child: SafeArea(
            child: Column(children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 14),
              Text('All reviews', style: serif(22)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [for (final r in d.reviews) _ReviewTile(r)]),
              ),
            ]),
          ),
        ),
      );

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
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: Text('Guest reviews', style: serif(19))),
                  if (d.reviews.length > 3)
                    TextButton(
                        onPressed: () => _showAll(d),
                        child: Text('See all ${d.reviews.length}')),
                ]),
                const SizedBox(height: 8),
                if (d.summary.total == 0)
                  const Panel(
                      child: Row(children: [
                    Icon(Icons.star_outline_rounded, color: AppColors.gold),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            'No reviews yet. Guests can rate this room after their stay.',
                            style: TextStyle(
                                fontSize: 12.5, color: AppColors.muted))),
                  ]))
                else ...[
                  _Summary(d.summary),
                  const SizedBox(height: 12),
                  for (final r in d.reviews.take(3)) _ReviewTile(r),
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
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(s.average.toStringAsFixed(1), style: serif(36)),
          const SizedBox(height: 2),
          StarRating(s.average, size: 16),
          const SizedBox(height: 6),
          Text(ratingWord(s.average),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green)),
          Text('${s.total} review${s.total == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
        const SizedBox(width: 22),
        Expanded(
          child: Column(children: [
            for (var star = 5; star >= 1; star--)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  SizedBox(
                    width: 10,
                    child: Text('$star',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.counts[star - 1] / max,
                        minHeight: 7,
                        backgroundColor: AppColors.greenSoft,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 18,
                    child: Text('${s.counts[star - 1]}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted)),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Panel(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.green,
                  child: Text(initials(r.guestName),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.guestName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(fmtShort(r.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ]),
              ),
              Pill.good('Verified stay'),
            ]),
            const SizedBox(height: 10),
            StarRating(r.rating.toDouble(), size: 16),
            if (r.comment != null) ...[
              const SizedBox(height: 6),
              Text(r.comment!,
                  style: const TextStyle(fontSize: 12.5, height: 1.5)),
            ],
          ]),
        ),
      );
}
