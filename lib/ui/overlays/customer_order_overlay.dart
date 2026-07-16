import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

class CustomerOrderOverlay extends StatelessWidget {
  const CustomerOrderOverlay({required this.controller, super.key});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final scale = _CustomerOrderMetrics.scaleOf(context);
    return ValueListenableBuilder<CustomerOrderSnapshot>(
      valueListenable: controller.customerOrderSnapshotListenable,
      builder: (context, snapshot, _) {
        final activeOrder = snapshot.activeOrder;
        if (activeOrder == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 14 * scale),
          child: AnimatedContainer(
            key: const ValueKey('customer-order-card'),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 10 * scale,
              vertical: 8 * scale,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF46110C).withValues(alpha: 0.72),
                  const Color(0xFF25110C).withValues(alpha: 0.68),
                ],
              ),
              borderRadius: BorderRadius.circular(8 * scale),
              border: Border.all(
                color: DonerColors.borderPrimary.withValues(alpha: 0.38),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 10 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            child: _ActiveCustomerStrip(order: activeOrder, scale: scale),
          ),
        );
      },
    );
  }
}

class _ActiveCustomerStrip extends StatelessWidget {
  const _ActiveCustomerStrip({required this.order, required this.scale});

  final ActiveCustomerOrderSnapshot order;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isTr = strings.isTurkish;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _CustomerIcon(scale: scale),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Text(
                '${order.customerName} - ${order.title}',
                key: const ValueKey('customer-order-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DonerTypography.body(
                  Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: DonerColors.creamText,
                    fontWeight: FontWeight.w900,
                    fontSize: 12 * scale,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8 * scale),
            Text(
              '${order.remaining.inSeconds}s',
              key: const ValueKey('customer-order-timer'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DonerTypography.body(
                Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: DonerColors.goldBright,
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5 * scale,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 5 * scale),
        _CompactProgress(
          valueKey: const ValueKey('customer-order-progress'),
          value: order.progress,
          color: DonerColors.orangeAccent,
          scale: scale,
        ),
        SizedBox(height: 4 * scale),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_numberLabel(context, order.currentValue)} / ${_numberLabel(context, order.targetValue)}',
                key: const ValueKey('customer-order-progress-text'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DonerTypography.body(
                  Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DonerColors.creamText,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5 * scale,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${isTr ? 'Ödül' : 'Reward'}: ${order.rewardLabel}',
                  key: const ValueKey('customer-order-reward'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: DonerTypography.body(
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: DonerColors.tealBright,
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5 * scale,
                      letterSpacing: 0,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CustomerIcon extends StatelessWidget {
  const _CustomerIcon({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24 * scale,
      height: 24 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DonerColors.goldPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7 * scale),
        border: Border.all(
          color: DonerColors.goldPrimary.withValues(alpha: 0.34),
          width: 1,
        ),
      ),
      child: FaIcon(
        DonerIcons.avatarFallback,
        color: DonerColors.goldBright,
        size: 12 * scale,
      ),
    );
  }
}

class _CompactProgress extends StatelessWidget {
  const _CompactProgress({
    required this.valueKey,
    required this.value,
    required this.color,
    required this.scale,
  });

  final Key valueKey;
  final double value;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        key: valueKey,
        minHeight: 4 * scale,
        value: value,
        backgroundColor: DonerColors.panelDark.withValues(alpha: 0.64),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _CustomerOrderMetrics {
  const _CustomerOrderMetrics._();

  static double scaleOf(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return math.min(size.width / 390.0, size.height / 884.0);
  }
}

String _numberLabel(BuildContext context, double value) {
  if (value.abs() >= 1000) {
    return formatCompactNumber(context, value);
  }
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}
