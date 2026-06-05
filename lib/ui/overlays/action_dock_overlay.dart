import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

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
      child: ValueListenableBuilder<RushSnapshot>(
        valueListenable: controller.rushSnapshotListenable,
        builder: (context, snapshot, _) {
          final readyText = snapshot.canStart
              ? strings.rushReady
              : strings.rushStatus(
                  snapshot.remaining,
                  snapshot.cooldownRemaining,
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

  double get actionHeight => 70 * scale;
  double get sidePadding => 32 * scale;
  double get bottomPadding => 8 * scale;
  double get pillVerticalPadding => 9 * scale;
  double get pillHorizontalPadding => 20 * scale;
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
        gradient: DonerGradients.activeButton,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DonerColors.borderPrimary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: DonerColors.orangeAccent.withValues(alpha: 0.26),
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
            FaIcon(
              DonerIcons.flame,
              size: 18 * scale,
              color: DonerColors.goldBright,
            ),
            SizedBox(width: 8 * scale),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DonerTypography.body(
                Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: DonerColors.creamText,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  fontSize: 10 * scale,
                ),
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
    final size = 68 * scale;
    return Tooltip(
      message: AppStrings.of(context).rushLabel,
      child: SizedBox.square(
        key: const ValueKey('shell-rush-button'),
        dimension: size,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashFactory: InkRipple.splashFactory,
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: enabled
                    ? DonerGradients.turbo
                    : DonerGradients.disabledButton,
                border: Border.all(
                  color: enabled
                      ? DonerColors.goldPrimary
                      : DonerColors.borderSoft,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (enabled
                                ? DonerColors.orangeAccent
                                : DonerColors.bgPrimary)
                            .withValues(alpha: enabled ? 0.36 : 0.22),
                    blurRadius: 20 * scale,
                    offset: Offset(0, 8 * scale),
                  ),
                ],
              ),
              child: Center(
                child: FaIcon(
                  DonerIcons.rush,
                  size: 34 * scale,
                  color: enabled
                      ? DonerColors.goldBright
                      : DonerColors.disabledText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
