import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/app_theme.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/theme/ui_asset_paths.dart';
import 'package:taptapdoner/ui/widgets/chef_portrait_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('roasted theme uses the stitch palette and typography', () {
    final theme = buildAppTheme();

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF1F0F09));
    expect(theme.colorScheme.primary, const Color(0xFFE9C400));
    expect(theme.colorScheme.surfaceContainer, const Color(0xFF2D1B14));
    expect(theme.colorScheme.surfaceContainerHigh, const Color(0xFF39251E));
    expect(theme.colorScheme.onSurface, const Color(0xFFFDDBD0));

    expect(theme.textTheme.displayLarge?.fontFamily, 'Plus Jakarta Sans');
    expect(theme.textTheme.headlineMedium?.fontFamily, 'Plus Jakarta Sans');
    expect(theme.textTheme.titleLarge?.fontFamily, 'Be Vietnam Pro');
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Be Vietnam Pro');
    expect(theme.textTheme.labelLarge?.fontFamily, 'Be Vietnam Pro');

    expect(RoastedShadows.surface.first.color, const Color(0x1AFDDBD0));
    expect(RoastedShadows.glow.first.color, const Color(0x22E9C400));
  });

  testWidgets('chef portrait asset is bundled and the avatar widget builds', (
    tester,
  ) async {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/fonts/plus_jakarta_sans/'));
    expect(pubspec, contains('assets/fonts/be_vietnam_pro/'));
    expect(pubspec, contains('assets/ui/portraits/chef_portrait.jpg'));

    final data = await rootBundle.load(UiAssetPaths.chefPortrait);
    expect(data.lengthInBytes, greaterThan(0));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChefPortraitAvatar(size: 40))),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsOneWidget);

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;
    expect(
      decoration.boxShadow?.first.color,
      RoastedColors.onSurface.withValues(alpha: 0.18),
    );
  });
}
