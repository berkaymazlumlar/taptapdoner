import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/ui/theme/ui_asset_paths.dart';

class DonerKitchenBackdrop extends Component
    with HasGameReference<TapTapDonerGame> {
  static const double _maxSpawnRate = 12;
  static const int _maxActiveDrops = 30;
  static const int _decodedBillWidth = 320;

  final math.Random _random = math.Random();
  final List<_MoneyDrop> _drops = <_MoneyDrop>[];
  final List<ui.Image> _moneyImages = <ui.Image>[];
  double _spawnAccumulator = 0;

  @visibleForTesting
  int get debugActiveMoneyDropCount => _drops.length;

  @visibleForTesting
  double debugSpawnRateFor(double passiveIncomePerSecond) {
    return _spawnRateFor(passiveIncomePerSecond);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final assetPath in UiAssetPaths.moneyRainBills) {
      try {
        _moneyImages.add(await _loadUiImage(assetPath));
      } catch (_) {
        continue;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.size.x <= 0 || game.size.y <= 0) {
      return;
    }

    final passiveIncomePerSecond = game.controller.passiveIncomePerSecond;
    final spawnRate = _moneyImages.isEmpty
        ? 0.0
        : _spawnRateFor(passiveIncomePerSecond);
    final maxActiveDrops = _maxActiveDropsFor(passiveIncomePerSecond);

    if (spawnRate > 0 && maxActiveDrops > 0) {
      _spawnAccumulator = math.min(
        _spawnAccumulator + (dt * spawnRate),
        maxActiveDrops * 2,
      );
      while (_spawnAccumulator >= 1 && _drops.length < maxActiveDrops) {
        _spawnAccumulator -= 1;
        _drops.add(_createDrop());
      }
    } else {
      _spawnAccumulator = 0;
    }

    for (var index = _drops.length - 1; index >= 0; index--) {
      final drop = _drops[index];
      drop.age += dt;
      drop.baseX += drop.horizontalDrift * dt;
      drop.y += drop.velocityY * dt;
      drop.rotation += drop.angularVelocity * dt;

      if (drop.isOffscreen(game.size.toSize())) {
        _drops.removeAt(index);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final size = game.size.toSize();
    final rect = Offset.zero & size;

    final backgroundShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF321A12), Color(0xFF24100A), Color(0xFF1F0F09)],
      stops: [0.0, 0.52, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = backgroundShader);

    for (final drop in _drops) {
      if (_moneyImages.isEmpty) {
        break;
      }
      final image = _moneyImages[drop.variantIndex];
      final frame = drop.frameFor(image);
      final center = Offset(
        drop.baseX +
            math.sin(drop.age * drop.swaySpeed + drop.phase) * drop.sway,
        drop.y,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(drop.rotation);
      paintImage(
        canvas: canvas,
        rect: Rect.fromCenter(
          center: Offset.zero,
          width: frame.width,
          height: frame.height,
        ),
        image: image,
        fit: BoxFit.fill,
        opacity: drop.opacity,
        filterQuality: FilterQuality.medium,
      );
      canvas.restore();
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x00322116),
          const Color(0x001F0F09),
          const Color(0xFF1F0F09).withValues(alpha: 0.94),
        ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  _MoneyDrop _createDrop() {
    final screenSize = game.size.toSize();
    final width = screenSize.width * (0.12 + (_random.nextDouble() * 0.12));
    final height = width * (0.48 + (_random.nextDouble() * 0.1));

    return _MoneyDrop(
      variantIndex: _random.nextInt(_moneyImages.length),
      baseX: _random.nextDouble() * screenSize.width,
      y: -(height * (0.8 + _random.nextDouble() * 1.4)),
      width: width,
      height: height,
      velocityY: 90 + (_random.nextDouble() * 140),
      horizontalDrift: -18 + (_random.nextDouble() * 36),
      sway: 6 + (_random.nextDouble() * 20),
      swaySpeed: 0.9 + (_random.nextDouble() * 1.6),
      phase: _random.nextDouble() * math.pi * 2,
      rotation: -0.28 + (_random.nextDouble() * 0.56),
      angularVelocity: -0.22 + (_random.nextDouble() * 0.44),
      opacity: 0.2 + (_random.nextDouble() * 0.24),
    );
  }

  double _spawnRateFor(double passiveIncomePerSecond) {
    if (passiveIncomePerSecond <= 0) {
      return 0;
    }
    return math.min(
      _maxSpawnRate,
      0.35 + (math.sqrt(passiveIncomePerSecond) * 0.65),
    );
  }

  int _maxActiveDropsFor(double passiveIncomePerSecond) {
    if (passiveIncomePerSecond <= 0) {
      return 0;
    }
    return math.min(
      _maxActiveDrops,
      math.max(2, 2 + (math.sqrt(passiveIncomePerSecond) * 2.4).round()),
    );
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: _decodedBillWidth,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}

class _MoneyDrop {
  _MoneyDrop({
    required this.variantIndex,
    required this.baseX,
    required this.y,
    required this.width,
    required this.height,
    required this.velocityY,
    required this.horizontalDrift,
    required this.sway,
    required this.swaySpeed,
    required this.phase,
    required this.rotation,
    required this.angularVelocity,
    required this.opacity,
  });

  final int variantIndex;
  double baseX;
  double y;
  final double width;
  final double height;
  final double velocityY;
  final double horizontalDrift;
  final double sway;
  final double swaySpeed;
  final double phase;
  double rotation;
  final double angularVelocity;
  final double opacity;
  double age = 0;

  Size frameFor(ui.Image image) {
    final aspectRatio = image.height / image.width;
    return Size(width, width * aspectRatio);
  }

  bool isOffscreen(Size screenSize) {
    final margin = width * 1.4;
    return y - height > screenSize.height + margin ||
        baseX < -margin ||
        baseX > screenSize.width + margin;
  }
}
