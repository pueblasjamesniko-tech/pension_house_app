import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'common.dart';

/// Full-screen photo gallery: swipe between photos, pinch to zoom,
/// tap a thumbnail to jump.
Future<void> showPhotoViewer(BuildContext context, List<String> photos,
        {int initial = 0, String? title}) =>
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          _PhotoViewer(photos: photos, initial: initial, title: title),
    ));

class _PhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initial;
  final String? title;
  const _PhotoViewer({required this.photos, required this.initial, this.title});
  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pc = PageController(initialPage: widget.initial);
  late int _i = widget.initial;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.photos.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _pc,
          itemCount: n,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: RoomImage(url: widget.photos[i], fit: BoxFit.contain),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
            child: Row(children: [
              CircleIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  onTap: () => Navigator.pop(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: serif(17, color: Colors.white)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0x66FFFFFF),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${_i + 1} / $n',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
        if (n > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: SizedBox(
                height: 74,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  scrollDirection: Axis.horizontal,
                  itemCount: n,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _pc.animateToPage(i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: i == _i ? Colors.white : Colors.white24,
                            width: i == _i ? 2 : 1),
                      ),
                      child: RoomImage(
                          url: widget.photos[i],
                          radius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
