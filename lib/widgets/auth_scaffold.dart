import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/theme.dart';

class AuthScaffold extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const AuthScaffold(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
              padding: EdgeInsets.zero,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  padding: EdgeInsets.fromLTRB(
                      24, MediaQuery.of(context).padding.top + 28, 24, 30),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: const Color(0x22FFFFFF),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Text('NPH',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          const Text(Config.appName,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 18),
                        const Text(
                          'A small pension house on Lapu-Lapu shoreline, five minutes’ walk from Crab Island. '
                          'Fan or air-conditioned rooms, a garden kitchen, and a hammock deck for the afternoons you don’t plan anything.',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12.5, height: 1.55),
                        ),
                      ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
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
              ]),
        ),
      );
}
