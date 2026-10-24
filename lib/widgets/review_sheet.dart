import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import 'common.dart';

/// Bottom sheet to rate a stay (new) or edit an existing review.
/// Returns true when something was saved.
Future<bool> showReviewSheet(
  BuildContext context, {
  required String roomTitle,
  int? bookingId,
  Review? existing,
}) async {
  assert(bookingId != null || existing != null);
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: sheetShape(),
    builder: (_) => _ReviewForm(
        roomTitle: roomTitle, bookingId: bookingId, existing: existing),
  );
  return saved == true;
}

class _ReviewForm extends StatefulWidget {
  final String roomTitle;
  final int? bookingId;
  final Review? existing;
  const _ReviewForm(
      {required this.roomTitle, this.bookingId, this.existing});
  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  late int _rating = widget.existing?.rating ?? 0;
  late final _comment = TextEditingController(text: widget.existing?.comment);
  bool _busy = false;

  static const _words = ['', 'Poor', 'Fair', 'Good', 'Very good', 'Excellent'];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == 0) return toast(context, 'Tap a star to rate your stay.');
    setState(() => _busy = true);
    try {
      final api = ApiService.instance;
      if (widget.existing != null) {
        await api.updateReview(widget.existing!.id, _rating, _comment.text);
      } else {
        await api.createReview(widget.bookingId!, _rating, _comment.text);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 18),
              Text(widget.existing == null ? 'Rate your stay' : 'Edit your review',
                  style: serif(22)),
              const SizedBox(height: 2),
              Text(widget.roomTitle,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
              const SizedBox(height: 14),
              StarPicker(value: _rating, onChanged: (v) => setState(() => _rating = v)),
              SizedBox(
                height: 24,
                child: Center(
                  child: Text(_words[_rating],
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _comment,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                    hintText: 'Tell us about your stay (optional)'),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                  widget.existing == null ? 'Submit review' : 'Save changes',
                  loading: _busy,
                  onPressed: _save),
            ]),
          ),
        ),
      );
}
