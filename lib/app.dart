import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/state/player_state.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'features/album/album_screen.dart';
import 'features/artist/artist_screen.dart';
import 'features/download/download_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/library/library_screen.dart';
import 'features/now_playing/now_playing_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/splash/splash_screen.dart';
import 'shared/widgets/bottom_nav.dart';
import 'shared/widgets/mini_player.dart';

class MonolithApp extends StatelessWidget {
  const MonolithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayerState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Monolith',
        theme: buildAppTheme(),
        home: const _Boot(),
      ),
    );
  }
}

class _Boot extends StatefulWidget {
  const _Boot();
  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  bool _booted = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: _booted
          ? const _AppShell(key: ValueKey('shell'))
          : SplashScreen(
              key: const ValueKey('splash'),
              onDone: () => setState(() => _booted = true),
            ),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerState>();

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: _RouteSwitch(route: state.route),
                ),
              ),
              if (!state.playerOpen) const MiniPlayer(),
              if (!state.playerOpen)
                BottomNav(
                  route: state.route,
                  onNav: (r) => state.navigate(r),
                ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: state.playerOpen
                ? NowPlayingScreen(
                    key: const ValueKey('now-playing'),
                    visualizer: state.vizStyle,
                    radial: state.nowPlayingRadial,
                  )
                : const SizedBox.shrink(key: ValueKey('np-empty')),
          ),
        ],
      ),
    );
  }
}

class _RouteSwitch extends StatelessWidget {
  final AppRoute route;
  const _RouteSwitch({required this.route});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: child,
      ),
      child: KeyedSubtree(
        key: ValueKey(route),
        child: switch (route) {
          AppRoute.library => const LibraryScreen(),
          AppRoute.search => const SearchScreen(),
          AppRoute.download => const DownloadScreen(),
          AppRoute.favorites => const FavoritesScreen(),
          AppRoute.album => const AlbumScreen(),
          AppRoute.artist => const ArtistScreen(),
          AppRoute.settings => const SettingsScreen(),
        },
      ),
    );
  }
}
