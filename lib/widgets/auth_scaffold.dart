import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/theme.dart';
import 'common.dart';

class AuthScaffold extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const AuthScaffold(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.child});

  Widget _feature(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0x1FFFFFFF),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ]),
      );

  Widget _hero(BuildContext context) => Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Stack(children: [
          Positioned(
            right: -50,
            top: -40,
            child: Container(
                width: 190,
                height: 190,
                decoration: const BoxDecoration(
                    color: Color(0x33E05A40), shape: BoxShape.circle)),
          ),
          Positioned(
            right: 56,
            bottom: 34,
            child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                    color: Color(0x88E0A43A), shape: BoxShape.circle)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                22, MediaQuery.of(context).padding.top + 18, 22, 54),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (Navigator.canPop(context)) ...[
                  CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                ],
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text('NPH',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(Config.appName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 22),
              Text('A small pension house on the Lapu-Lapu shoreline.',
                  style: serif(24, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Five minutes’ walk from Crab Island.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.5)),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _feature(Icons.ac_unit_rounded, 'Fan or aircon rooms'),
                _feature(Icons.yard_outlined, 'Garden kitchen'),
                _feature(Icons.deck_outlined, 'Hammock deck'),
              ]),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
              padding: EdgeInsets.zero,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _hero(context),
                // The card slides up so it overlaps the green header.
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.line),
                        boxShadow: AppShadow.lift,
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: serif(28)),
                            const SizedBox(height: 4),
                            Text(subtitle,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.muted)),
                            const SizedBox(height: 22),
                            child,
                          ]),
                    ),
                  ),
                ),
              ]),
        ),
      );
}
