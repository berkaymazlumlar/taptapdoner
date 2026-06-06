import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

class StarterQuestOverlay extends StatelessWidget {
  const StarterQuestOverlay({required this.controller, super.key});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final metrics = _StarterQuestMetrics.fromContext(context);
    return ValueListenableBuilder<QuestSnapshot?>(
      valueListenable: controller.questSnapshotListenable,
      builder: (context, snapshot, _) {
        if (snapshot == null) {
          return const SizedBox.shrink();
        }
        return _StarterQuestCard(
          snapshot: snapshot,
          metrics: metrics,
          onClaim: snapshot.canClaim
              ? () => controller.claimActiveQuestReward()
              : null,
        );
      },
    );
  }
}

class QuestShortcutButton extends StatelessWidget {
  const QuestShortcutButton({
    required this.scale,
    required this.enabled,
    required this.active,
    required this.canClaim,
    required this.onPressed,
    super.key,
  });

  final double scale;
  final bool enabled;
  final bool active;
  final bool canClaim;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final size = 54 * scale;
    final highlighted = enabled && (active || canClaim);
    return Tooltip(
      message: AppStrings.of(context).questLabel,
      child: SizedBox.square(
        key: const ValueKey('shell-quest-button'),
        dimension: size,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashFactory: InkRipple.splashFactory,
            onTap: enabled ? onPressed : null,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: highlighted
                    ? DonerGradients.activeButton
                    : DonerGradients.card,
                border: Border.all(
                  color: highlighted
                      ? DonerColors.goldPrimary
                      : DonerColors.borderSoft,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (highlighted
                                ? DonerColors.goldPrimary
                                : DonerColors.bgPrimary)
                            .withValues(alpha: highlighted ? 0.34 : 0.24),
                    blurRadius: 16 * scale,
                    offset: Offset(0, 6 * scale),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: FaIcon(
                      DonerIcons.upgradeMenu,
                      size: 25 * scale,
                      color: enabled
                          ? DonerColors.goldBright
                          : DonerColors.disabledText,
                    ),
                  ),
                  if (canClaim)
                    Positioned(
                      top: -2 * scale,
                      right: -2 * scale,
                      child: Container(
                        key: const ValueKey('shell-quest-button-badge'),
                        width: 22 * scale,
                        height: 22 * scale,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              DonerColors.tealBright,
                              DonerColors.tealPrimary,
                            ],
                          ),
                          border: Border.all(
                            color: DonerColors.creamText,
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.30),
                              blurRadius: 8 * scale,
                              offset: Offset(0, 3 * scale),
                            ),
                          ],
                        ),
                        child: Text(
                          '1',
                          textAlign: TextAlign.center,
                          style: DonerTypography.body(
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: DonerColors.creamText,
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5 * scale,
                              height: 1,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarterQuestMetrics {
  const _StarterQuestMetrics({required this.scale, required this.width});

  factory _StarterQuestMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = math.min(size.width / 390.0, size.height / 884.0);
    return _StarterQuestMetrics(
      scale: scale,
      width: math.min(size.width - (40 * scale), 286 * scale),
    );
  }

  final double scale;
  final double width;

  double get radius => 18 * scale;
  double get padding => 12 * scale;
  double get iconSize => 18 * scale;
  double get titleSize => 12.5 * scale;
  double get metaSize => 9.5 * scale;
  double get buttonHeight => 30 * scale;
}

class _StarterQuestCard extends StatelessWidget {
  const _StarterQuestCard({
    required this.snapshot,
    required this.metrics,
    required this.onClaim,
  });

  final QuestSnapshot snapshot;
  final _StarterQuestMetrics metrics;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final completed = snapshot.canClaim;

    return AnimatedContainer(
      key: const ValueKey('starter-quest-card'),
      width: metrics.width,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: DonerGradients.card,
        borderRadius: BorderRadius.circular(metrics.radius),
        border: Border.all(
          color: completed ? DonerColors.goldBright : DonerColors.borderSoft,
          width: completed ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (completed ? DonerColors.goldPrimary : Colors.black)
                .withValues(alpha: completed ? 0.38 : 0.30),
            blurRadius: completed ? 22 * metrics.scale : 14 * metrics.scale,
            offset: Offset(0, 7 * metrics.scale),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(metrics.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FaIcon(
                  DonerIcons.upgradeMenu,
                  color: DonerColors.goldBright,
                  size: metrics.iconSize,
                ),
                SizedBox(width: 8 * metrics.scale),
                Expanded(
                  child: Text(
                    strings.questLabel.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DonerTypography.body(
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DonerColors.bodyText,
                        fontSize: metrics.metaSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                if (completed)
                  Text(
                    strings.questCompletedLabel.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DonerTypography.body(
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DonerColors.goldBright,
                        fontSize: metrics.metaSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 7 * metrics.scale),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    strings.questTitle(snapshot.questId),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DonerTypography.body(
                      Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: DonerColors.creamText,
                        fontSize: metrics.titleSize,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                  ),
                ),
                if (snapshot.questId == 'starter_combo_15') ...[
                  SizedBox(width: 6 * metrics.scale),
                  _QuestInfoButton(
                    metrics: metrics,
                    message: strings.questComboUnlockInfo,
                  ),
                ],
              ],
            ),
            SizedBox(height: 8 * metrics.scale),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                key: const ValueKey('starter-quest-progress-bar'),
                value: snapshot.progress,
                minHeight: 6 * metrics.scale,
                backgroundColor: DonerColors.panelDark.withValues(alpha: 0.92),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed ? DonerColors.goldBright : DonerColors.tealBright,
                ),
              ),
            ),
            SizedBox(height: 8 * metrics.scale),
            Row(
              children: [
                Expanded(
                  child: _QuestMetaLine(
                    label: strings.questProgressLabel,
                    value:
                        '${_formatProgress(snapshot.currentValue)} / ${_formatProgress(snapshot.targetValue)}',
                    metrics: metrics,
                  ),
                ),
                SizedBox(width: 8 * metrics.scale),
                Expanded(
                  child: _QuestMetaLine(
                    label: strings.questRewardLabel,
                    value: strings.questReward(snapshot.questId),
                    metrics: metrics,
                  ),
                ),
              ],
            ),
            if (completed) ...[
              SizedBox(height: 9 * metrics.scale),
              SizedBox(
                height: metrics.buttonHeight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey('starter-quest-claim-button'),
                    onTap: onClaim,
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: DonerGradients.activeButton,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: DonerColors.goldPrimary,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          strings.questClaimLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DonerTypography.body(
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: DonerColors.creamText,
                              fontWeight: FontWeight.w900,
                              fontSize: 11.5 * metrics.scale,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatProgress(double value) {
    if (value >= 100) {
      return value.floor().toString();
    }
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _QuestMetaLine extends StatelessWidget {
  const _QuestMetaLine({
    required this.label,
    required this.value,
    required this.metrics,
  });

  final String label;
  final String value;
  final _StarterQuestMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DonerTypography.body(
            Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DonerColors.mutedText,
              fontSize: metrics.metaSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(height: 2 * metrics.scale),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DonerTypography.body(
            Theme.of(context).textTheme.labelMedium?.copyWith(
              color: DonerColors.creamText,
              fontSize: metrics.metaSize + 0.8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestInfoButton extends StatelessWidget {
  const _QuestInfoButton({required this.metrics, required this.message});

  final _StarterQuestMetrics metrics;
  final String message;

  @override
  Widget build(BuildContext context) {
    final size = 24 * metrics.scale;
    return Tooltip(
      message: message,
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: Colors.transparent,
          child: InkResponse(
            key: const ValueKey('starter-quest-info-button'),
            radius: size,
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(message),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            },
            child: Center(
              child: FaIcon(
                DonerIcons.info,
                size: 15 * metrics.scale,
                color: DonerColors.bodyText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
