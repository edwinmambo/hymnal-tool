import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hymnal_tool/models/models.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xffb9755d), Color(0xff694b67)],
      ),
      borderRadius: BorderRadius.circular(size * .34),
      boxShadow: const [
        BoxShadow(
          color: Color(0x338c5545),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Icon(
      Icons.auto_stories_rounded,
      color: Colors.white,
      size: size * .55,
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 34),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    ),
  );
}

class ThemeBackdrop extends StatelessWidget {
  const ThemeBackdrop({
    super.key,
    required this.theme,
    required this.child,
    this.borderRadius,
  });

  final PresentationTheme theme;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = theme.gradientColors.map(Color.new).toList();
    final bytes = theme.backgroundBytes;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          ),
          if (bytes != null) _MemoryBackground(bytes: bytes),
          ColoredBox(
            color: Colors.black.withValues(alpha: theme.overlayStrength),
          ),
          child,
        ],
      ),
    );
  }
}

class _MemoryBackground extends StatelessWidget {
  const _MemoryBackground({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => Image.memory(
    bytes,
    fit: BoxFit.cover,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}
