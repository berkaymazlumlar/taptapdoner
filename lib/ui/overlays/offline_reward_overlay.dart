import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/ui/pages/offline_reward_page.dart';

class OfflineRewardOverlay extends StatelessWidget {
  const OfflineRewardOverlay({required this.controller, super.key});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.58),
      child: SafeArea(
        key: const ValueKey('offline-reward-overlay-root'),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactHeight = constraints.maxHeight < 700;
            final pagePadding = compactHeight ? 16.0 : 22.0;
            final availableWidth = math.max(
              0.0,
              constraints.maxWidth - pagePadding * 2,
            );

            return Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.all(pagePadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.min(430, availableWidth),
                    maxHeight: math.max(
                      0,
                      constraints.maxHeight - pagePadding * 2,
                    ),
                  ),
                  child: OfflineRewardPage(controller: controller),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
