import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/domain/random_events/random_event_models.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

class RandomEventOverlay extends StatefulWidget {
  const RandomEventOverlay({
    required this.controller,
    required this.snapshot,
    super.key,
  });

  final GameController controller;
  final RandomEventSnapshot snapshot;

  @override
  State<RandomEventOverlay> createState() => _RandomEventOverlayState();
}

class _RandomEventOverlayState extends State<RandomEventOverlay>
    with TickerProviderStateMixin {
  RandomEventResolutionSnapshot? _resolution;
  bool _busy = false;
  bool _closing = false;
  bool _reduceMotion = false;
  late final AnimationController _entranceController;
  late final AnimationController _exitController;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceTurn;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _entranceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.36,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 58,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.12,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.96,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 22,
      ),
    ]).animate(_entranceController);
    _entranceTurn = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.018, end: 0.012),
        weight: 48,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.012, end: -0.006),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.006, end: 0),
        weight: 28,
      ),
    ]).animate(_entranceController);
    _entranceController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _entranceController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant RandomEventOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.event.id != widget.snapshot.event.id) {
      _resolution = null;
      _closing = false;
      _exitController.reset();
      if (_reduceMotion) {
        _entranceController.value = 1;
      } else {
        _entranceController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _choose(RandomEventChoice choice) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
    });
    final resolution = await widget.controller.chooseRandomEvent(choice.key);
    if (!mounted) {
      return;
    }
    setState(() {
      _resolution = resolution;
      _busy = false;
    });
  }

  Future<void> _close() async {
    if (_closing || _busy) {
      return;
    }
    setState(() {
      _closing = true;
      _busy = true;
    });
    if (!_reduceMotion) {
      await _exitController.forward(from: 0);
    }
    if (!mounted) {
      return;
    }
    await widget.controller.dismissRandomEvent();
    if (mounted) {
      setState(() {
        _resolution = null;
        _closing = false;
        _busy = false;
      });
    }
  }

  Future<void> _showNextDebugEvent() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _resolution = null;
    });
    await widget.controller.showDebugRandomEvent();
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.snapshot.event;
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceController, _exitController]),
        builder: (context, child) {
          final entrance = _entranceController.value;
          final exit = Curves.easeIn.transform(_exitController.value);
          final visible = 1 - exit;
          final backdropOpacity =
              Curves.easeOut.transform((entrance / 0.28).clamp(0, 1)) * visible;
          final burstProgress = ((entrance - 0.04) / 0.58).clamp(0.0, 1.0);
          final burstOpacity = math.sin(burstProgress * math.pi) * visible;

          return Opacity(
            opacity: visible,
            child: ColoredBox(
              key: const ValueKey('random-event-backdrop'),
              color: Colors.black.withValues(alpha: 0.58 * backdropOpacity),
              child: SafeArea(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IgnorePointer(
                        child: Opacity(
                          key: const ValueKey('random-event-surprise-burst'),
                          opacity: burstOpacity,
                          child: Transform.scale(
                            scale: 0.35 + (burstProgress * 1.25),
                            child: Container(
                              width: 310,
                              height: 310,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    DonerColors.goldBright.withValues(
                                      alpha: 0.42,
                                    ),
                                    DonerColors.goldPrimary.withValues(
                                      alpha: 0.12,
                                    ),
                                    Colors.transparent,
                                  ],
                                  stops: const [0, 0.42, 1],
                                ),
                                border: Border.all(
                                  color: DonerColors.goldBright.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, (1 - entrance) * 54 + exit * 12),
                        child: Transform.rotate(
                          angle: _entranceTurn.value * math.pi * 2,
                          child: Transform.scale(
                            scale: _entranceScale.value * (1 - exit * 0.04),
                            child: Opacity(
                              opacity: Curves.easeOut.transform(
                                (entrance / 0.2).clamp(0, 1),
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: _EventPanel(
              event: event,
              resolution: _resolution,
              busy: _busy,
              canShowRewardedAd: widget.controller.canDoubleOfflineReward,
              onClose: _close,
              onDebugNext: kDebugMode ? _showNextDebugEvent : null,
              onChoice: _choose,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventPanel extends StatelessWidget {
  const _EventPanel({
    required this.event,
    required this.resolution,
    required this.busy,
    required this.canShowRewardedAd,
    required this.onClose,
    required this.onDebugNext,
    required this.onChoice,
  });

  final RandomEventDefinition event;
  final RandomEventResolutionSnapshot? resolution;
  final bool busy;
  final bool canShowRewardedAd;
  final VoidCallback onClose;
  final AsyncCallback? onDebugNext;
  final ValueChanged<RandomEventChoice> onChoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final resolved = resolution != null;
    return DecoratedBox(
      key: const ValueKey('random-event-panel'),
      decoration: BoxDecoration(
        gradient: DonerGradients.sheet,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DonerColors.goldPrimary, width: 1.5),
        boxShadow: DonerShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    resolved ? 'SONUÇ' : 'SÜRPRİZ OLAY!',
                    style: DonerTypography.display(
                      theme.labelLarge?.copyWith(
                        color: DonerColors.goldBright,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                if (onDebugNext != null)
                  TextButton.icon(
                    key: const ValueKey('random-event-debug-next'),
                    onPressed: busy
                        ? null
                        : () {
                            onDebugNext?.call();
                          },
                    icon: const FaIcon(DonerIcons.expand, size: 12),
                    label: const Text('Debug Next'),
                    style: TextButton.styleFrom(
                      foregroundColor: DonerColors.tealBright,
                      textStyle: DonerTypography.body(
                        theme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  key: const ValueKey('random-event-close'),
                  tooltip: 'Kapat',
                  onPressed: busy ? null : onClose,
                  icon: const FaIcon(DonerIcons.close),
                  color: DonerColors.creamText,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: DonerColors.tealPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DonerColors.tealBright.withValues(alpha: 0.65),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: FaIcon(
                    DonerIcons.info,
                    color: DonerColors.tealBright,
                    size: 34,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              event.title,
              textAlign: TextAlign.center,
              style: DonerTypography.display(
                theme.titleLarge?.copyWith(
                  color: DonerColors.creamText,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              resolution?.resultText ?? event.eventText,
              textAlign: TextAlign.center,
              style: DonerTypography.body(
                theme.bodyMedium?.copyWith(
                  color: DonerColors.bodyText,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (resolution == null) ...[
              _SummaryRow(
                icon: DonerIcons.cash,
                label: 'Olası Ödül',
                value: event.rewardSummary,
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                icon: DonerIcons.shield,
                label: 'Olası Risk',
                value: event.riskSummary,
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final choices = event.choices
                      .where(
                        (choice) =>
                            !choice.requiresRewardedAd || canShowRewardedAd,
                      )
                      .toList(growable: false);
                  return Row(
                    children: [
                      for (var index = 0; index < choices.length; index += 1)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : 8,
                              right: index == choices.length - 1 ? 0 : 8,
                            ),
                            child: _ChoiceButton(
                              choice: choices[index],
                              primary: choices[index].key == 'accept',
                              busy: busy,
                              onPressed: () => onChoice(choices[index]),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ] else ...[
              _SummaryRow(
                icon: DonerIcons.rewardAd,
                label: 'Etki',
                value: resolution!.effectLabel,
              ),
              const SizedBox(height: 16),
              _ActionButton(
                key: const ValueKey('random-event-result-ok'),
                label: 'Tamam',
                primary: true,
                onPressed: onClose,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final FaIconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DonerColors.panelDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DonerColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            FaIcon(icon, color: DonerColors.goldBright, size: 15),
            const SizedBox(width: 10),
            Text(
              '$label: ',
              style: DonerTypography.body(
                theme.labelMedium?.copyWith(
                  color: DonerColors.goldPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DonerTypography.body(
                  theme.labelMedium?.copyWith(
                    color: DonerColors.creamText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.choice,
    required this.primary,
    required this.busy,
    required this.onPressed,
  });

  final RandomEventChoice choice;
  final bool primary;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      key: ValueKey('random-event-choice-${choice.key}'),
      label: choice.label,
      primary: primary,
      onPressed: busy ? null : onPressed,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.primary,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool primary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: primary ? DonerGradients.activeButton : DonerGradients.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primary ? DonerColors.goldBright : DonerColors.borderPrimary,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DonerTypography.body(
                theme.labelLarge?.copyWith(
                  color: DonerColors.creamText,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
