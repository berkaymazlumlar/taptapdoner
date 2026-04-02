import 'package:flutter/material.dart';
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
          color: RoastedColors.surfaceContainerHighest,
          border: Border.all(color: RoastedColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: RoastedColors.onSurface.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                child: Icon(
                  Icons.person,
                  color: RoastedColors.primaryFixed,
                  size: diameter * 0.42,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
