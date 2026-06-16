import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taptapdoner/app/app_theme.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/overlays/game_shell_overlay.dart';
import 'package:taptapdoner/ui/overlays/offline_reward_overlay.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

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
  bool _ready = false;
  String _localeCode = 'en';
  bool _showStartupOfflineReward = false;

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
    if (_controller.hasPendingOfflineReward) {
      _controller.stopTicking();
      setState(() {
        _ready = true;
        _showStartupOfflineReward = true;
        _localeCode = _controller.state.localeCode;
      });
      return;
    }
    _showGame();
  }

  void _showGame() {
    setState(() {
      _ready = true;
      _showStartupOfflineReward = false;
      _localeCode = _controller.state.localeCode;
    });
    _controller.startTicking();
  }

  String _resolveLocaleCode() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return code == 'tr' ? 'tr' : 'en';
  }

  Future<void> _onPause() async {
    _controller.stopTicking();
    await _controller.checkpointLifecycle();
  }

  Future<void> _onResume() async {
    if (!_controller.isInitialized) {
      return;
    }
    await _controller.reconcileBackground();
    if (!_showStartupOfflineReward) {
      _controller.startTicking();
    }
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
    if (_showStartupOfflineReward && !_controller.hasPendingOfflineReward) {
      _showGame();
      return;
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _controller.removeListener(_handleControllerUpdate);
    _controller.stopTicking();
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
          home: !_ready
              ? const _LoadingScreen()
              : _showStartupOfflineReward
              ? _StartupOfflineRewardScreen(controller: _controller)
              : _GameHome(controller: _controller),
        );
      },
    );
  }
}

class _GameHome extends StatefulWidget {
  const _GameHome({required this.controller});

  final GameController controller;

  @override
  State<_GameHome> createState() => _GameHomeState();
}

class _GameHomeState extends State<_GameHome> {
  late bool _showOfflineReward;

  @override
  void initState() {
    super.initState();
    _showOfflineReward = widget.controller.hasPendingOfflineReward;
    widget.controller.addListener(_handleControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant _GameHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleControllerUpdate);
    _showOfflineReward = widget.controller.hasPendingOfflineReward;
    widget.controller.addListener(_handleControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }

  void _handleControllerUpdate() {
    final nextShowOfflineReward = widget.controller.hasPendingOfflineReward;
    if (_showOfflineReward == nextShowOfflineReward || !mounted) {
      return;
    }

    setState(() {
      _showOfflineReward = nextShowOfflineReward;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameShellOverlay(controller: widget.controller),
          if (_showOfflineReward)
            OfflineRewardOverlay(controller: widget.controller),
        ],
      ),
    );
  }
}

class _StartupOfflineRewardScreen extends StatelessWidget {
  const _StartupOfflineRewardScreen({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _StartupSplashBackdrop(),
          OfflineRewardOverlay(controller: controller),
        ],
      ),
    );
  }
}

class _StartupSplashBackdrop extends StatelessWidget {
  const _StartupSplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8C1710), Color(0xFF5A0D09), Color(0xFF2A0604)],
        ),
      ),
      child: Center(
        child: Text(
          AppStrings.of(context).appTitle.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: RoastedTypography.headlineFontFamily,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: DonerColors.goldPrimary,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
