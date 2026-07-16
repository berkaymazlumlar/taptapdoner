import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/theme/ui_asset_paths.dart';

class DonerKitchenBackdrop extends Component
    with HasGameReference<TapTapDonerGame> {
  static const double _maxSpawnRate = 12;
  static const int _maxActiveDrops = 30;
  static const int _decodedBillWidth = 320;
  static const int _decodedBackdropWidth = 1440;

  final math.Random _random = math.Random();
  final List<_MoneyDrop> _drops = <_MoneyDrop>[];
  final List<_MoneyDrop> _dropPool = <_MoneyDrop>[];
  final List<_MoneySpriteVariant> _moneyVariants = <_MoneySpriteVariant>[];
  final List<_MoneyAtlasBatch> _atlasBatches = <_MoneyAtlasBatch>[];
  final Paint _billPaint = Paint()..filterQuality = FilterQuality.low;
  ui.Image? _backgroundImage;
  double _spawnAccumulator = 0;
  double _cachedPassiveIncomePerSecond = double.nan;
  double _cachedSpawnRate = 0;
  int _cachedMaxActiveDrops = 0;

  @visibleForTesting
  int get debugActiveMoneyDropCount => _drops.length;

  @visibleForTesting
  bool get debugHasBackdropImage => _backgroundImage != null;

  @visibleForTesting
  double debugSpawnRateFor(double passiveIncomePerSecond) {
    return _spawnRateFor(passiveIncomePerSecond);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _backgroundImage = await _loadUiImage(
        UiAssetPaths.kitchenBackdrop,
        targetWidth: _decodedBackdropWidth,
      );
    } catch (_) {
      _backgroundImage = null;
    }
    for (final assetPath in UiAssetPaths.moneyRainBills) {
      try {
        final image = await _loadUiImage(assetPath);
        _moneyVariants.add(_MoneySpriteVariant(image));
        _atlasBatches.add(_MoneyAtlasBatch());
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
    _refreshIntensityCache(passiveIncomePerSecond);
    final spawnRate = _cachedSpawnRate;
    final maxActiveDrops = _cachedMaxActiveDrops;

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
        _dropPool.add(_drops.removeAt(index));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final size = game.size.toSize();
    final rect = Offset.zero & size;
    final backgroundImage = _backgroundImage;
    if (backgroundImage != null) {
      paintImage(
        canvas: canvas,
        rect: rect,
        image: backgroundImage,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      );
    } else {
      final backgroundShader = DonerGradients.screen.createShader(rect);
      canvas.drawRect(rect, Paint()..shader = backgroundShader);
    }

    if (_moneyVariants.isEmpty || _drops.isEmpty) {
      return;
    }

    for (final batch in _atlasBatches) {
      batch.clear();
    }

    for (final drop in _drops) {
      final variant = _moneyVariants[drop.variantIndex];
      final batch = _atlasBatches[drop.variantIndex];
      final center = Offset(
        drop.baseX +
            math.sin(drop.age * drop.swaySpeed + drop.phase) * drop.sway,
        drop.y,
      );
      batch.transforms.add(
        ui.RSTransform.fromComponents(
          rotation: drop.rotation,
          scale: drop.width / variant.image.width,
          anchorX: variant.anchorX,
          anchorY: variant.anchorY,
          translateX: center.dx,
          translateY: center.dy,
        ),
      );
      batch.rects.add(variant.sourceRect);
      batch.colors.add(drop.tint);
    }

    for (var index = 0; index < _moneyVariants.length; index++) {
      final batch = _atlasBatches[index];
      if (batch.transforms.isEmpty) {
        continue;
      }
      canvas.drawAtlas(
        _moneyVariants[index].image,
        batch.transforms,
        batch.rects,
        batch.colors,
        BlendMode.modulate,
        null,
        _billPaint,
      );
    }
  }

  _MoneyDrop _createDrop() {
    final screenSize = game.size.toSize();
    final variantIndex = _random.nextInt(_moneyVariants.length);
    final variant = _moneyVariants[variantIndex];
    final width = screenSize.width * (0.12 + (_random.nextDouble() * 0.12));
    final height = width * variant.aspectRatio;
    final drop = _dropPool.isNotEmpty ? _dropPool.removeLast() : _MoneyDrop();

    drop.reset(
      variantIndex: variantIndex,
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
    return drop;
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

  void _refreshIntensityCache(double passiveIncomePerSecond) {
    if (passiveIncomePerSecond == _cachedPassiveIncomePerSecond) {
      return;
    }
    _cachedPassiveIncomePerSecond = passiveIncomePerSecond;
    if (_moneyVariants.isEmpty || passiveIncomePerSecond <= 0) {
      _cachedSpawnRate = 0;
      _cachedMaxActiveDrops = 0;
      return;
    }
    _cachedSpawnRate = _spawnRateFor(passiveIncomePerSecond);
    _cachedMaxActiveDrops = _maxActiveDropsFor(passiveIncomePerSecond);
  }

  Future<ui.Image> _loadUiImage(String assetPath, {int? targetWidth}) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetWidth ?? _decodedBillWidth,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}

class _MoneyDrop {
  void reset({
    required int variantIndex,
    required double baseX,
    required double y,
    required double width,
    required double height,
    required double velocityY,
    required double horizontalDrift,
    required double sway,
    required double swaySpeed,
    required double phase,
    required double rotation,
    required double angularVelocity,
    required double opacity,
  }) {
    this.variantIndex = variantIndex;
    this.baseX = baseX;
    this.y = y;
    this.width = width;
    this.height = height;
    this.velocityY = velocityY;
    this.horizontalDrift = horizontalDrift;
    this.sway = sway;
    this.swaySpeed = swaySpeed;
    this.phase = phase;
    this.rotation = rotation;
    this.angularVelocity = angularVelocity;
    tint = Color.fromRGBO(255, 255, 255, opacity);
    age = 0;
  }

  int variantIndex = 0;
  double baseX = 0;
  double y = 0;
  double width = 0;
  double height = 0;
  double velocityY = 0;
  double horizontalDrift = 0;
  double sway = 0;
  double swaySpeed = 0;
  double phase = 0;
  double rotation = 0;
  double angularVelocity = 0;
  Color tint = const Color(0xFFFFFFFF);
  double age = 0;

  bool isOffscreen(Size screenSize) {
    final margin = width * 1.4;
    return y - height > screenSize.height + margin ||
        baseX < -margin ||
        baseX > screenSize.width + margin;
  }
}

class _MoneySpriteVariant {
  _MoneySpriteVariant(this.image)
    : aspectRatio = image.height / image.width,
      sourceRect = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      anchorX = image.width / 2,
      anchorY = image.height / 2;

  final ui.Image image;
  final double aspectRatio;
  final Rect sourceRect;
  final double anchorX;
  final double anchorY;
}

class _MoneyAtlasBatch {
  final List<ui.RSTransform> transforms = <ui.RSTransform>[];
  final List<Rect> rects = <Rect>[];
  final List<Color> colors = <Color>[];

  void clear() {
    transforms.clear();
    rects.clear();
    colors.clear();
  }
}
