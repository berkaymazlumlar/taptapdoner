import 'package:flutter/material.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/theme/ui_asset_paths.dart';

class ChefPortraitAvatar extends StatelessWidget {
  const ChefPortraitAvatar({
    super.key,
    this.size = 40,
    this.semanticLabel = 'Premium Chef Portrait',
  });

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final diameter = size.clamp(24, 128).toDouble();
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DonerColors.panelPrimary,
          border: Border.all(color: DonerColors.tealPrimary, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: DonerColors.tealPrimary.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DonerColors.goldPrimary, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                UiAssetPaths.chefPortrait,
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: RoastedColors.surfaceContainer,
                    alignment: Alignment.center,
                    child: FaIcon(
                      DonerIcons.avatarFallback,
                      color: DonerColors.goldBright,
                      size: diameter * 0.42,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
