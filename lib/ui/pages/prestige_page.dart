import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/stitch_bottom_sheet_primitives.dart';

class PrestigePage extends StatelessWidget {
  const PrestigePage({
    required this.controller,
    super.key,
    this.onOpenKitchen,
    this.onOpenShop,
    this.onBack,
    this.onPrestigeApplied,
  });

  final GameController controller;
  final VoidCallback? onOpenKitchen;
  final VoidCallback? onOpenShop;
  final VoidCallback? onBack;
  final Future<void> Function()? onPrestigeApplied;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('prestige-sheet-surface'),
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: _PrestigeBackdropGlow()),
            StitchBottomSheetSurface(
              backgroundGradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF34190F),
                  Color(0xFF2A140D),
                  Color(0xFF1F0F09),
                ],
              ),
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final strings = AppStrings.of(context);
                  final availablePoints = controller.availablePrestigePoints;
                  final reputation = controller.state.prestige.reputation;
                  final runCashEarned = controller.state.prestige.runCashEarned;
                  final threshold = controller.config.prestigeThreshold;
                  final progress = threshold <= 0
                      ? 0.0
                      : ((runCashEarned % threshold) / threshold).clamp(
                          0.0,
                          1.0,
                        );
                  final progressPercent = (progress * 100).round();
                  final canPrestige = availablePoints > 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const StitchSheetHandle(
                        key: ValueKey('prestige-sheet-handle'),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 2.h, 24.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              strings.prestigeTitle,
                              key: const ValueKey('prestige-sheet-title'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily:
                                    RoastedTypography.headlineFontFamily,
                                fontSize: 36.sp,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                letterSpacing: -1.1,
                                color: RoastedColors.primary,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              strings.prestigeConfirm.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: RoastedTypography.bodyFontFamily,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: 2.3,
                                color: RoastedColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PrestigeHeroCard(
                                availablePoints: availablePoints,
                                reputation: reputation,
                                progress: progress,
                                progressPercent: progressPercent,
                              ),
                              SizedBox(height: 18.h),
                              _PrestigeInfoCard(
                                title: 'Permanent Boost',
                                body:
                                    'Each prestige point permanently boosts global income.',
                                icon: Icons.trending_up_rounded,
                                accent: RoastedColors.primary,
                              ),
                              SizedBox(height: 14.h),
                              _PrestigeInfoCard(
                                title: 'What Resets',
                                body: 'Stations, cash, and upgrades reset.',
                                icon: Icons.restart_alt_rounded,
                                accent: const Color(0xFFFFB4AB),
                              ),
                              SizedBox(height: 14.h),
                              _PrestigeInfoCard(
                                title: 'What Stays',
                                body:
                                    'Your total reputation is kept permanently.',
                                icon: Icons.shield_rounded,
                                accent: RoastedColors.secondary,
                              ),
                              SizedBox(height: 24.h),
                              _PrestigePrimaryButton(
                                key: const ValueKey('prestige-action-button'),
                                enabled: canPrestige,
                                onPressed: canPrestige
                                    ? () async {
                                        final applied = await controller
                                            .applyPrestige();
                                        if (!applied) {
                                          return;
                                        }
                                        if (onPrestigeApplied != null) {
                                          await onPrestigeApplied!();
                                        } else if (context.mounted) {
                                          Navigator.of(context).maybePop();
                                        }
                                      }
                                    : null,
                              ),
                              SizedBox(height: 14.h),
                              _PrestigeCloseButton(
                                key: const ValueKey('prestige-close-button'),
                                onPressed:
                                    onBack ??
                                    onOpenKitchen ??
                                    onOpenShop ??
                                    () => Navigator.of(context).maybePop(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrestigeHeroCard extends StatelessWidget {
  const _PrestigeHeroCard({
    required this.availablePoints,
    required this.reputation,
    required this.progress,
    required this.progressPercent,
  });

  final int availablePoints;
  final int reputation;
  final double progress;
  final int progressPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('prestige-summary-card'),
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 22.h),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2015),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: RoastedColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -18.w,
            top: -18.h,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 154.sp,
              color: RoastedColors.tertiaryFixed.withValues(alpha: 0.11),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 4.h),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30.w,
                          height: 30.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: RoastedColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            size: 18.sp,
                            color: RoastedColors.primary,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          availablePoints.toString(),
                          style: TextStyle(
                            fontFamily: RoastedTypography.headlineFontFamily,
                            fontSize: 52.sp,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            color: const Color(0xFFFFE8DE),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Center(
                  child: Text(
                    'REPUTATION READY',
                    style: TextStyle(
                      fontFamily: RoastedTypography.bodyFontFamily,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: 3.w,
                      color: RoastedColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 26.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'PROGRESS TO NEXT POINT',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: RoastedTypography.bodyFontFamily,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: RoastedColors.outlineVariant.withValues(
                                alpha: 0.95,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '$progressPercent%',
                          style: TextStyle(
                            fontFamily: RoastedTypography.bodyFontFamily,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            color: RoastedColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _PrestigeProgressBar(value: progress),
                  ],
                ),
                SizedBox(height: 24.h),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 22.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A3D32),
                        borderRadius: BorderRadius.circular(999.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 18.sp,
                            color: RoastedColors.secondary,
                          ),
                          SizedBox(width: 10.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT TOTAL',
                                style: TextStyle(
                                  fontFamily: RoastedTypography.bodyFontFamily,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: RoastedColors.tertiary,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                reputation.toString(),
                                style: TextStyle(
                                  fontFamily: RoastedTypography.headlineFontFamily,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                  color: const Color(0xFFFFE8DE),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrestigeProgressBar extends StatelessWidget {
  const _PrestigeProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12.h,
      decoration: BoxDecoration(
        color: const Color(0xFF24120D),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: RoastedColors.outlineVariant.withValues(alpha: 0.20),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999.r),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [RoastedColors.primary, RoastedColors.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: RoastedColors.primary.withValues(alpha: 0.40),
                    blurRadius: 10.r,
                    offset: Offset.zero,
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

class _PrestigeInfoCard extends StatelessWidget {
  const _PrestigeInfoCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4A2D22),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24.sp, color: accent),
          ),
          SizedBox(width: 18.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: RoastedTypography.headlineFontFamily,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: accent,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: RoastedTypography.bodyFontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: RoastedColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrestigePrimaryButton extends StatelessWidget {
  const _PrestigePrimaryButton({
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final bool enabled;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () async {
                  await onPressed?.call();
                }
              : null,
          borderRadius: BorderRadius.circular(999.r),
          child: Ink(
            height: 60.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [RoastedColors.primary, RoastedColors.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(999.r),
              border: Border.all(
                color: RoastedColors.primaryFixed.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: RoastedColors.primary.withValues(alpha: 0.28),
                  blurRadius: 24.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'PRESTIGE',
                style: TextStyle(
                  fontFamily: RoastedTypography.headlineFontFamily,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: 2.4,
                  color: RoastedColors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrestigeCloseButton extends StatelessWidget {
  const _PrestigeCloseButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999.r),
        child: Ink(
          height: 48.h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(999.r),
            border: Border.all(
              color: RoastedColors.outlineVariant.withValues(alpha: 0.30),
            ),
          ),
          child: Center(
            child: Text(
              'Close',
              style: TextStyle(
                fontFamily: RoastedTypography.bodyFontFamily,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: 2.0,
                color: RoastedColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrestigeBackdropGlow extends StatelessWidget {
  const _PrestigeBackdropGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 96.h,
            left: -70.w,
            child: _GlowBlob(
              size: 220.w,
              color: RoastedColors.primary.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: 220.h,
            right: -54.w,
            child: _GlowBlob(
              size: 200.w,
              color: RoastedColors.secondary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
