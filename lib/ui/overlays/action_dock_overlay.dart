import 'package:flutter/material.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

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
    final size = 54 * scale;
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
                    blurRadius: 16 * scale,
                    offset: Offset(0, 6 * scale),
                  ),
                ],
              ),
              child: Center(
                child: FaIcon(
                  DonerIcons.rush,
                  size: 27 * scale,
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
