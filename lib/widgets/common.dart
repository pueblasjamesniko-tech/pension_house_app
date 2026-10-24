import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

void toast(BuildContext c, String m, {bool error = false}) =>
    ScaffoldMessenger.of(c)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(m),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.danger : AppColors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  const Panel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.color,
      this.borderColor});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: borderColor ?? AppColors.line)),
        child: child,
      );
}

class SectionTitle extends StatelessWidget {
  final String title, subtitle;
  const SectionTitle(this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: serif(26)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
      ]);
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading, outlined;
  const PrimaryButton(this.label,
      {super.key,
      this.onPressed,
      this.loading = false,
      this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                color: outlined ? AppColors.green : Colors.white))
        : Text(label);
    final tap = loading ? null : onPressed;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton(onPressed: tap, child: child)
          : FilledButton(onPressed: tap, child: child),
    );
  }
}

class AppField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData? icon;
  final bool password;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboard;
  final TextInputAction? action;
  final TextCapitalization capitalization;
  final Iterable<String>? autofill;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  const AppField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.password = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboard,
    this.action,
    this.capitalization = TextCapitalization.none,
    this.autofill,
    this.formatters,
    this.validator,
    this.onSubmitted,
  });
  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  bool _hide = true;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.label,
            style:
                const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.password && _hide,
          keyboardType: widget.keyboard,
          textInputAction: widget.action,
          textCapitalization: widget.capitalization,
          autofillHints: widget.autofill,
          inputFormatters: widget.formatters,
          maxLines: widget.password ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: 18, color: AppColors.muted),
            suffixIcon: widget.password
                ? IconButton(
                    icon: Icon(
                        _hide
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.muted),
                    onPressed: () => setState(() => _hide = !_hide))
                : null,
          ),
        ),
      ]);
}

class RoomImage extends StatelessWidget {
  final String? url;
  final double? height;
  final BorderRadius radius;
  const RoomImage(
      {super.key, this.url, this.height, this.radius = BorderRadius.zero});

  Widget get _placeholder => Container(
      color: const Color(0xFFEDE8DA),
      child: const Center(
          child: Icon(Icons.bed_outlined, size: 36, color: AppColors.muted)));

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: (url == null || url!.isEmpty)
              ? _placeholder
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, p) =>
                      p == null ? child : _placeholder,
                  errorBuilder: (_, __, ___) => _placeholder,
                ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message,
      this.action,
      this.onAction});

  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(children: [
          CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.greenSoft,
              child: Icon(icon, color: AppColors.green)),
          const SizedBox(height: 14),
          Text(title, style: serif(18), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              textAlign: TextAlign.center),
          if (action != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 28)),
                child: Text(action!)),
          ],
        ]),
      );
}

/// Shows a spinner, then the data, or a friendly error with a retry button.
/// While refreshing it keeps showing the old data (no flicker).
class AsyncView<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;
  const AsyncView(
      {super.key,
      required this.future,
      required this.builder,
      required this.onRetry});

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (_, s) {
          if (s.hasData) return builder(s.data as T);
          if (s.connectionState == ConnectionState.done && s.hasError) {
            return ErrorView(message: '${s.error}', onRetry: onRetry);
          }
          return const Center(
              child: CircularProgressIndicator(color: AppColors.green));
        },
      );
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.coralSoft,
                child: Icon(Icons.wifi_off_rounded, color: AppColors.coral)),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.4)),
            const SizedBox(height: 14),
            OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again')),
          ]),
        ),
      );
}

class KeyValue extends StatelessWidget {
  final String k, v;
  final bool bold;
  const KeyValue(this.k, this.v, {super.key, this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(k,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: bold ? AppColors.ink : AppColors.muted,
                      fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
              const SizedBox(width: 16),
              Flexible(
                  child: Text(v,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: bold ? 14 : 12.5,
                          fontWeight: bold ? FontWeight.w700 : FontWeight.w500))),
            ]),
      );
}

/// Small coloured pill, e.g. "Confirmed", "Available".
class Pill extends StatelessWidget {
  final String label;
  final Color fg, bg;
  final IconData? icon;
  const Pill(this.label,
      {super.key, required this.fg, required this.bg, this.icon});

  factory Pill.good(String l) => Pill(l,
      fg: AppColors.success, bg: AppColors.successSoft, icon: Icons.circle);
  factory Pill.warn(String l) =>
      Pill(l, fg: const Color(0xFF8A5B00), bg: AppColors.goldSoft, icon: Icons.circle);
  factory Pill.bad(String l) =>
      Pill(l, fg: AppColors.danger, bg: AppColors.dangerSoft, icon: Icons.circle);
  factory Pill.neutral(String l) =>
      Pill(l, fg: AppColors.muted, bg: const Color(0xFFEFEBDD), icon: Icons.circle);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 7, color: fg),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ]),
      );
}

/// Read-only star row (supports halves).
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  const StarRating(this.rating, {super.key, this.size = 16});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          Icon(
              rating >= i
                  ? Icons.star_rounded
                  : rating >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              size: size,
              color: AppColors.gold),
      ]);
}

/// Tap-to-rate stars.
class StarPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const StarPicker({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            onPressed: () => onChanged(i),
            iconSize: 38,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(),
            icon: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppColors.gold),
          ),
      ]);
}

Future<bool> confirmDialog(BuildContext context,
    {required String title,
    required String message,
    String confirm = 'Confirm',
    String cancel = 'Cancel',
    bool danger = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title, style: serif(20)),
      content: Text(message, style: const TextStyle(fontSize: 13.5, height: 1.4)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: Text(cancel)),
        TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(
                foregroundColor: danger ? AppColors.danger : AppColors.coral),
            child: Text(confirm)),
      ],
    ),
  );
  return ok == true;
}

RoundedRectangleBorder sheetShape() => const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)));
