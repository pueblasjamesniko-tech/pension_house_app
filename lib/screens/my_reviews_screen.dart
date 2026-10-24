import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';
import '../widgets/review_sheet.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});
  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  late Future<List<Review>> _f = ApiService.instance.myReviews();
  void _reload() => setState(() => _f = ApiService.instance.myReviews());

  Future<void> _edit(Review r) async {
    final ok = await showReviewSheet(context,
        roomTitle: r.roomTitle, existing: r);
    if (ok) {
      if (mounted) toast(context, 'Review updated.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My reviews')),
        body: AsyncView<List<Review>>(
          future: _f,
          onRetry: _reload,
          builder: (list) => RefreshIndicator(
            color: AppColors.green,
            onRefresh: () async {
              _reload();
              await _f;
            },
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (list.isEmpty)
                    const EmptyState(
                      icon: Icons.star_outline_rounded,
                      title: 'No reviews yet',
                      message:
                          'After your stay ends, you can rate it from the Bookings tab.',
                    ),
                  for (final r in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Panel(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(r.roomTitle, style: serif(17))),
                                Text(fmtShort(r.createdAt),
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.muted)),
                              ]),
                              const SizedBox(height: 6),
                              StarRating(r.rating.toDouble()),
                              if (r.comment != null) ...[
                                const SizedBox(height: 8),
                                Text(r.comment!,
                                    style: const TextStyle(
                                        fontSize: 12.5, height: 1.45)),
                              ],
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _edit(r),
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit'),
                                ),
                              ),
                            ]),
                      ),
                    ),
                ]),
          ),
        ),
      );
}
