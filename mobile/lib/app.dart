import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class RideSyncApp extends ConsumerWidget {
  const RideSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BackHandler(
      child: MaterialApp.router(
        title: 'RideSync',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}

// ─── Global back-button handler ───────────────────────────────────────────────
// Uses WidgetsBindingObserver.didPopRoute() which fires BEFORE GoRouter or
// any Navigator processes the event (observers are called in reverse-add order,
// so this one — added last — runs first).

class _BackHandler extends StatefulWidget {
  final Widget child;
  const _BackHandler({super.key, required this.child});

  @override
  State<_BackHandler> createState() => _BackHandlerState();
}

class _BackHandlerState extends State<_BackHandler> with WidgetsBindingObserver {
  static const _shellTabs = {'/home', '/my-rides', '/bookings', '/profile'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Save the current tab when the app goes to background so SplashScreen can
  // restore it if Android kills and recreates the activity.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final path =
          appRouter.routerDelegate.currentConfiguration.uri.path;
      if (_shellTabs.contains(path)) {
        SharedPreferences.getInstance()
            .then((p) => p.setString('last_tab', path));
      }
    }
  }

  @override
  Future<bool> didPopRoute() async {
    // 1. If GoRouter has a screen to pop (e.g. /post-ride on top of shell),
    //    pop it and consume the event.
    if (appRouter.canPop()) {
      appRouter.pop();
      return true;
    }

    // 2. We're on a shell (bottom-nav) screen. If it's not Home, go Home.
    final location =
        appRouter.routerDelegate.currentConfiguration.uri.toString();
    if (location != '/home') {
      appRouter.go('/home');
      return true;
    }

    // 3. Already on Home — let the system handle it.
    //    MainActivity.finish() → moveTaskToBack(true) → app backgrounds.
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
