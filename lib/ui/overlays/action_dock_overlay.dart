import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/l10n/app_strings.dart';

class ActionDockOverlay extends StatelessWidget {
  const ActionDockOverlay({required this.controller, super.key});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final metrics = _ActionDockMetrics.fromContext(context);

    return SizedBox(
      key: const ValueKey('action-dock-panel'),
      height: metrics.actionHeight,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final readyText = controller.canStartRush
              ? strings.rushReady
              : strings.rushStatus(
                  controller.rushRemaining,
                  controller.rushCooldownRemaining,
                );

          return Padding(
            padding: EdgeInsets.fromLTRB(
              metrics.sidePadding,
              0,
              metrics.sidePadding,
              metrics.bottomPadding,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _RushReadyPill(
                key: const ValueKey('action-dock-rush-pill'),
                scale: metrics.scale,
                text: readyText,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionDockMetrics {
  const _ActionDockMetrics({required this.scale});

  factory _ActionDockMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = math.min(size.width / 390.0, size.height / 884.0);
    return _ActionDockMetrics(scale: scale);
  }

  final double scale;

  double get actionHeight => 64 * scale;
  double get sidePadding => 32 * scale;
  double get bottomPadding => 8 * scale;
  double get pillVerticalPadding => 7 * scale;
  double get pillHorizontalPadding => 16 * scale;
  double get pillDotSize => 8 * scale;
  double get pillFontSize => 10 * scale;
}

class _RushReadyPill extends StatelessWidget {
  const _RushReadyPill({required this.scale, required this.text, super.key});

  final double scale;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF39251E).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 7 * scale,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8 * scale,
              height: 8 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFE9C400),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x66E9C400),
                    blurRadius: 8 * scale,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8 * scale),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontFamily: 'Be Vietnam Pro',
                color: const Color(0xFFE9C400),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                fontSize: 10 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RushShortcutButton extends StatelessWidget {
  const RushShortcutButton({
    required this.scale,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final double scale;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final size = 50 * scale;
    return Tooltip(
      message: AppStrings.of(context).rushLabel,
      child: SizedBox.square(
        key: const ValueKey('shell-rush-button'),
        dimension: size,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: enabled
                      ? const [Color(0xFFF4D447), Color(0xFFD19A05)]
                      : const [Color(0xFF6C574A), Color(0xFF4A372E)],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: enabled ? 0.16 : 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (enabled
                                ? const Color(0xFFE9C400)
                                : const Color(0xFF1F0F09))
                            .withValues(alpha: enabled ? 0.24 : 0.20),
                    blurRadius: 18 * scale,
                    offset: Offset(0, 8 * scale),
                  ),
                ],
              ),
              child: Icon(
                Icons.bolt_rounded,
                size: 28 * scale,
                color: enabled
                    ? const Color(0xFF2D1B14)
                    : const Color(0xFFE0C0B4).withValues(alpha: 0.72),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
