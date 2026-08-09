import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hymnal_tool/models/models.dart';
import 'package:hymnal_tool/widgets/common.dart';

class PresenterScreen extends StatefulWidget {
  const PresenterScreen({
    super.key,
    required this.songs,
    required this.theme,
    this.initialSongId,
  });

  final List<Song> songs;
  final PresentationTheme theme;
  final String? initialSongId;

  @override
  State<PresenterScreen> createState() => _PresenterScreenState();
}

class _PresenterScreenState extends State<PresenterScreen> {
  late final List<PresentationSlide> _slides;
  final FocusNode _focusNode = FocusNode();
  Timer? _hideTimer;
  int _index = 0;
  bool _blank = false;
  bool _controlsVisible = true;
  double _fontAdjustment = 0;

  @override
  void initState() {
    super.initState();
    _slides = [
      for (var songIndex = 0; songIndex < widget.songs.length; songIndex++)
        for (
          var sectionIndex = 0;
          sectionIndex < widget.songs[songIndex].sections.length;
          sectionIndex++
        )
          PresentationSlide(
            song: widget.songs[songIndex],
            section: widget.songs[songIndex].sections[sectionIndex],
            songIndex: songIndex,
            sectionIndex: sectionIndex,
          ),
    ];
    if (widget.initialSongId != null) {
      final target = _slides.indexWhere(
        (slide) => slide.song.id == widget.initialSongId,
      );
      if (target >= 0) _index = target;
    }
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _showControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _move(int delta) {
    setState(() {
      _blank = false;
      _index = (_index + delta).clamp(0, _slides.length - 1);
    });
    _showControls();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.pageDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.pageUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyB || key == LogicalKeyboardKey.period) {
      setState(() => _blank = !_blank);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('No lyric slides', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    final slide = _slides[_index];
    final theme = widget.theme;
    final alignment = switch (theme.alignment) {
      'left' => TextAlign.left,
      'right' => TextAlign.right,
      _ => TextAlign.center,
    };
    final contentAlignment = switch (theme.alignment) {
      'left' => Alignment.centerLeft,
      'right' => Alignment.centerRight,
      _ => Alignment.center,
    };
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: MouseRegion(
          onHover: (_) => _showControls(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _controlsVisible = !_controlsVisible),
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() > 100) _move(velocity < 0 ? 1 : -1);
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _blank
                  ? const ColoredBox(
                      key: ValueKey('blank'),
                      color: Colors.black,
                    )
                  : ThemeBackdrop(
                      key: ValueKey('${slide.song.id}-${slide.section.id}'),
                      theme: theme,
                      child: SafeArea(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  48,
                                  92,
                                  48,
                                  122,
                                ),
                                child: Align(
                                  alignment: contentAlignment,
                                  child: FractionallySizedBox(
                                    widthFactor: .92,
                                    heightFactor: .78,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: contentAlignment,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 1200,
                                        ),
                                        child: Text(
                                          slide.section.lyrics,
                                          textAlign: alignment,
                                          style: TextStyle(
                                            color: Color(theme.textColor),
                                            fontSize:
                                                (theme.fontSize +
                                                        _fontAdjustment)
                                                    .clamp(32, 104),
                                            height: 1.28,
                                            fontWeight: FontWeight.w700,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.black87,
                                                blurRadius: 18,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 26,
                              left: 32,
                              right: 32,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      [
                                        if (slide.song.hymnal.number.isNotEmpty)
                                          '#${slide.song.hymnal.number}',
                                        slide.song.title,
                                      ].join('  ·  '),
                                      style: TextStyle(
                                        color: Color(
                                          theme.textColor,
                                        ).withValues(alpha: .82),
                                        fontSize: 18,
                                        letterSpacing: .5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${slide.section.label}  ·  ${slide.sectionIndex + 1}/${slide.song.sections.length}',
                                    style: TextStyle(
                                      color: Color(
                                        theme.textColor,
                                      ).withValues(alpha: .72),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _controls(slide),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls(PresentationSlide slide) => AnimatedPositioned(
    duration: const Duration(milliseconds: 220),
    left: 20,
    right: 20,
    bottom: _controlsVisible ? 18 : -150,
    child: Material(
      color: const Color(0xdd141419),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Exit presentation (Esc)',
              onPressed: () => Navigator.pop(context),
              color: Colors.white,
              icon: const Icon(Icons.close_rounded),
            ),
            IconButton(
              tooltip: 'Previous',
              onPressed: _index == 0 ? null : () => _move(-1),
              color: Colors.white,
              disabledColor: Colors.white30,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            IconButton(
              tooltip: 'Next',
              onPressed: _index == _slides.length - 1 ? null : () => _move(1),
              color: Colors.white,
              disabledColor: Colors.white30,
              icon: const Icon(Icons.skip_next_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0; index < _slides.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          selected: index == _index,
                          showCheckmark: false,
                          label: Text(_slideLabel(_slides[index])),
                          onSelected: (_) => setState(() {
                            _index = index;
                            _blank = false;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Smaller text',
              onPressed: () => setState(() => _fontAdjustment -= 4),
              color: Colors.white,
              icon: const Icon(Icons.text_decrease_rounded),
            ),
            IconButton(
              tooltip: 'Larger text',
              onPressed: () => setState(() => _fontAdjustment += 4),
              color: Colors.white,
              icon: const Icon(Icons.text_increase_rounded),
            ),
            IconButton.filled(
              tooltip: 'Blank screen (B)',
              onPressed: () => setState(() => _blank = !_blank),
              icon: const Icon(Icons.tv_off_rounded),
            ),
          ],
        ),
      ),
    ),
  );

  String _slideLabel(PresentationSlide slide) {
    if (widget.songs.length == 1) return slide.section.label;
    final songLabel = slide.song.hymnal.number.isNotEmpty
        ? '#${slide.song.hymnal.number}'
        : slide.song.title;
    return '$songLabel · ${slide.section.label}';
  }
}
