import 'package:flutter/material.dart';
import '../../core/state/player_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

class BottomNav extends StatelessWidget {
  final AppRoute route;
  final ValueChanged<AppRoute> onNav;

  const BottomNav({super.key, required this.route, required this.onNav});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _NavSpec(AppRoute.library, Icons.home_outlined, Icons.home, 'Library'),
      _NavSpec(AppRoute.search, Icons.search, Icons.search, 'Search'),
      _NavSpec(AppRoute.download, Icons.download_outlined, Icons.download, 'Download'),
      _NavSpec(AppRoute.favorites, Icons.favorite_border, Icons.favorite, 'Favorites'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppTokens.surface1,
        border: Border(top: BorderSide(color: AppTokens.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: items.map((item) {
            final active = item.route == route ||
                (item.route == AppRoute.library &&
                    (route == AppRoute.album || route == AppRoute.artist));
            return Expanded(
              child: InkResponse(
                onTap: () => onNav(item.route),
                radius: 38,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        width: 56,
                        height: 28,
                        decoration: BoxDecoration(
                          color: active ? AppTokens.accentSoft() : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          active ? item.iconFilled : item.icon,
                          size: 22,
                          color: active ? AppTokens.accent() : AppTokens.dim,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: AppType.sans(
                          size: 11,
                          weight: FontWeight.w500,
                          color: active ? AppTokens.fg : AppTokens.dim,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavSpec {
  final AppRoute route;
  final IconData icon;
  final IconData iconFilled;
  final String label;
  const _NavSpec(this.route, this.icon, this.iconFilled, this.label);
}
