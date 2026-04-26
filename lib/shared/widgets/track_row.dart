import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/models.dart';
import '../../core/state/player_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/format.dart';
import 'cover.dart';

class TrackRow extends StatelessWidget {
  final Track track;
  final int? index;
  final bool showNumber;

  const TrackRow({
    super.key,
    required this.track,
    this.index,
    this.showNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerState>();
    final isCurrent = state.currentTrackId == track.id;
    final isFav = state.favorites.contains(track.id);

    return Material(
      color: isCurrent ? AppTokens.accentSoft() : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => state.playTrack(track.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (showNumber)
                SizedBox(
                  width: 28,
                  child: isCurrent && state.playing
                      ? const _PulseDot()
                      : Text(
                          (((index ?? 0) + 1)).toString().padLeft(2, '0'),
                          textAlign: TextAlign.center,
                          style: AppType.mono(size: 12, color: AppTokens.dim),
                        ),
                )
              else
                Cover(tone: track.cover, seed: track.seed, size: 40, radius: 7, bars: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.sans(
                        size: 14.5,
                        weight: isCurrent ? FontWeight.w500 : FontWeight.w400,
                        color: isCurrent ? AppTokens.accent() : AppTokens.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${track.artist} · ${track.album}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.caption(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(fmtDur(track.duration),
                  style: AppType.mono(size: 11, color: AppTokens.dim)),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => state.toggleFavorite(track.id),
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: isFav ? AppTokens.accent() : AppTokens.dim,
                ),
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Container(
          width: 8 * (0.7 + 0.3 * (1 - _c.value)),
          height: 8 * (0.7 + 0.3 * (1 - _c.value)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTokens.accent().withValues(alpha: 0.4 + 0.6 * (1 - _c.value)),
          ),
        ),
      ),
    );
  }
}
