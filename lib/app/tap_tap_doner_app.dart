import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taptapdoner/app/app_theme.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/overlay_ids.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/overlays/game_shell_overlay.dart';
import 'package:taptapdoner/ui/overlays/offline_reward_overlay.dart';
import 'package:taptapdoner/ui/overlays/settings_overlay.dart';
import 'package:taptapdoner/ui/pages/prestige_page.dart';
import 'package:taptapdoner/ui/pages/shop_page.dart';

class TapTapDonerApp extends StatefulWidget {
  const TapTapDonerApp({super.key, this.controller});

  final GameController? controller;

  @override
  State<TapTapDonerApp> createState() => _TapTapDonerAppState();
}

class _TapTapDonerAppState extends State<TapTapDonerApp> {
  late final GameController _controller;
  late final bool _ownsController;
  AppLifecycleListener? _lifecycleListener;
  TapTapDonerGame? _game;
  bool _ready = false;
  bool _overlaysReady = false;
  String _localeCode = 'en';
  bool _offlineRewardVisible = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? GameController();
    _localeCode = _resolveLocaleCode();
    _controller.addListener(_handleControllerUpdate);
    _lifecycleListener = AppLifecycleListener(
      onResume: _onResume,
      onInactive: _onPause,
      onHide: _onPause,
      onPause: _onPause,
      onDetach: _onPause,
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    if (!_controller.isInitialized) {
      await _controller.initialize(fallbackLocaleCode: _resolveLocaleCode());
    }
    if (!mounted) {
      return;
    }
    final game = TapTapDonerGame(controller: _controller);
    setState(() {
      _game = game;
      _ready = true;
      _localeCode = _controller.state.localeCode;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _overlaysReady = true;
      _syncOfflineRewardOverlay(force: true);
    });
  }

  String _resolveLocaleCode() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return code == 'tr' ? 'tr' : 'en';
  }

  Future<void> _onPause() async {
    await _controller.checkpointLifecycle();
  }

  Future<void> _onResume() async {
    if (!_controller.isInitialized) {
      return;
    }
    await _controller.reconcileBackground();
    _handleControllerUpdate();
  }

  void _handleControllerUpdate() {
    if (!mounted) {
      return;
    }
    final nextLocaleCode = _controller.state.localeCode;
    if (_localeCode != nextLocaleCode) {
      setState(() {
        _localeCode = nextLocaleCode;
      });
    }
    _syncOfflineRewardOverlay();
  }

  void _syncOfflineRewardOverlay({bool force = false}) {
    if (!_overlaysReady) {
      return;
    }
    final game = _game;
    if (game == null) {
      return;
    }
    final shouldShowOfflineReward = _controller.hasPendingOfflineReward;
    if (!force && shouldShowOfflineReward == _offlineRewardVisible) {
      return;
    }
    _offlineRewardVisible = shouldShowOfflineReward;
    if (shouldShowOfflineReward) {
      game.showExclusiveOverlay(OverlayIds.offlineReward);
    } else {
      game.closeModal(OverlayIds.offlineReward);
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _controller.removeListener(_handleControllerUpdate);
    if (_ownsController) {
      _controller.dispose();
    }
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 884),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TapTap Doner',
          locale: Locale(_localeCode),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: AppStrings.localizationsDelegates,
          theme: buildAppTheme(),
          home: _ready && _game != null
              ? _GameHome(controller: _controller, game: _game!)
              : const _LoadingScreen(),
        );
      },
    );
  }
}

class _GameHome extends StatelessWidget {
  const _GameHome({required this.controller, required this.game});

  final GameController controller;
  final TapTapDonerGame game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<TapTapDonerGame>(
        game: game,
        initialActiveOverlays: OverlayIds.persistent,
        overlayBuilderMap: {
          OverlayIds.gameShell: (context, game) => GameShellOverlay(
            controller: controller,
            game: game,
            onOpenShop: () => unawaited(_showShopSheet(context, controller)),
            onOpenPrestige: () =>
                unawaited(_showPrestigeSheet(context, controller)),
            onOpenSettings: () => game.toggleModal(OverlayIds.settings),
          ),
          OverlayIds.settings: (context, game) => SettingsOverlay(
            controller: controller,
            onClose: () => game.closeModal(OverlayIds.settings),
          ),
          OverlayIds.offlineReward: (context, game) =>
              OfflineRewardOverlay(controller: controller),
        },
      ),
    );
  }
}

Future<void> _showShopSheet(
  BuildContext context,
  GameController controller,
) async {
  final navigator = Navigator.of(context);
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    enableDrag: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.96,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) {
      return KeyedSubtree(
        key: const ValueKey('shop-sheet-root'),
        child: ShopPage(
          controller: controller,
          onOpenKitchen: () => navigator.maybePop(),
          onOpenPrestige: () {
            navigator.maybePop();
            unawaited(
              Future<void>.delayed(
                Duration.zero,
                () {
                  if (!context.mounted) {
                    return;
                  }
                  unawaited(_showPrestigeSheet(context, controller));
                },
              ),
            );
          },
          onBack: () => navigator.maybePop(),
        ),
      );
    },
  );
}

Future<void> _showPrestigeSheet(
  BuildContext context,
  GameController controller,
) async {
  final navigator = Navigator.of(context);
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    enableDrag: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.96,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) {
      return KeyedSubtree(
        key: const ValueKey('prestige-sheet-root'),
        child: PrestigePage(
          controller: controller,
          onOpenKitchen: () => navigator.maybePop(),
          onOpenShop: () {
            navigator.maybePop();
            unawaited(
              Future<void>.delayed(
                Duration.zero,
                () {
                  if (!context.mounted) {
                    return;
                  }
                  unawaited(_showShopSheet(context, controller));
                },
              ),
            );
          },
          onBack: () => navigator.maybePop(),
          onPrestigeApplied: () async {
            if (context.mounted) {
              navigator.maybePop();
            }
          },
        ),
      );
    },
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF2A120A),
      child: Center(child: CircularProgressIndicator(color: Color(0xFFFFC067))),
    );
  }
}
