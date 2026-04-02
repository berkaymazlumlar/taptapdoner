import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/ui/theme/ui_asset_paths.dart';

void main() {
  testWidgets('tap visual png asset is registered and loadable', (
    tester,
  ) async {
    final data = await rootBundle.load(UiAssetPaths.tapDoner);
    final bytes = data.buffer.asUint8List();

    expect(bytes.length, greaterThan(8));
    expect(bytes[0], 0x89);
    expect(bytes[1], 0x50);
    expect(bytes[2], 0x4E);
    expect(bytes[3], 0x47);
    expect(bytes[4], 0x0D);
    expect(bytes[5], 0x0A);
    expect(bytes[6], 0x1A);
    expect(bytes[7], 0x0A);
  });

  testWidgets('falling doner slice assets are registered and loadable', (
    tester,
  ) async {
    for (final assetPath in UiAssetPaths.tapDonerSlices) {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      expect(bytes.length, greaterThan(8), reason: assetPath);
      expect(bytes[0], 0x89, reason: assetPath);
      expect(bytes[1], 0x50, reason: assetPath);
      expect(bytes[2], 0x4E, reason: assetPath);
      expect(bytes[3], 0x47, reason: assetPath);
      expect(bytes[4], 0x0D, reason: assetPath);
      expect(bytes[5], 0x0A, reason: assetPath);
      expect(bytes[6], 0x1A, reason: assetPath);
      expect(bytes[7], 0x0A, reason: assetPath);
    }
  });
}
