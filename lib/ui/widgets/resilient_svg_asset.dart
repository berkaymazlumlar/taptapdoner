import 'package:flutter/material.dart';

/// Compatibility shim for legacy overlay code paths.
///
/// The active shared-widget layer no longer renders asset-backed chrome.
/// This widget now paints a compact code-native warm panel so older callers
/// do not depend on generated SVG assets at runtime.
class ResilientSvgAsset extends StatelessWidget {
  const ResilientSvgAsset(
    this.assetPath, {
    super.key,
    this.fit = BoxFit.fill,
    this.renderedKey,
  });

  final String assetPath;
  final BoxFit fit;
  final Key? renderedKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: renderedKey,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE8C1), Color(0xFFF0BE6D), Color(0xFF9D4E21)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF6D2B17).withValues(alpha: 0.18),
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
