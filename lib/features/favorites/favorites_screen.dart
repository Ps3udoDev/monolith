import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/seed_data.dart';
import '../../core/state/player_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/track_row.dart';
import '../../shared/widgets/waveform.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerState>();
    final favs = [
      for (final id in state.favorites)
        if (lookupTrack(id) != null) lookupTrack(id)!
    ];
    final totalDur = favs.fold<int>(0, (s, t) => s + t.duration);

    if (favs.isEmpty) {
      return ListView(
        padding: EdgeInsets.zero,
        children: const [
          ScreenHeader(
            eyebrow: 'Favorites',
            title: 'Your heart',
            subtitle: 'Tap the heart on any track to save it here',
          ),
          _EmptyFavorites(),
        ],
      );
    }

    final signatureSeed = favs.fold<int>(0, (s, t) => s + t.seed) + favs.length;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ScreenHeader(
          eyebrow:
              '${favs.length} TRACK${favs.length == 1 ? '' : 'S'} · ${fmtDur(totalDur)}',
          title: 'Favorites',
          subtitle: 'Pinned locally · always offline',
          trailing: PrimaryButton(
            label: 'Play all',
            leading: Icons.play_arrow,
            onTap: () => context.read<PlayerState>().playTrack(favs.first.id),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 44,
                child: WaveformLine(
                  seed: signatureSeed,
                  bars: (favs.length * 24).clamp(48, 200),
                  height: 44,
                  color: AppTokens.accent(),
                  opacity: 0.95,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SIGNATURE',
                      style: AppType.mono(size: 10, color: AppTokens.dim2, letterSpacing: 1)),
                  Text('${favs.length} · concatenated',
                      style: AppType.mono(size: 10, color: AppTokens.dim2, letterSpacing: 1)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              for (var i = 0; i < favs.length; i++)
                TrackRow(track: favs[i], index: i, showNumber: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: DottedBorderBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 32, color: AppTokens.dim),
            const SizedBox(height: 12),
            Text('No favorites yet', style: AppType.body()),
            const SizedBox(height: 4),
            Text('Your collection stays on this device.',
                style: AppType.caption()),
          ],
        ),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTokens.hairlineStrong,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: child,
    );
  }
}
