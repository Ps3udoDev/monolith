import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/seed_data.dart';
import '../../core/state/player_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cover.dart';
import '../../shared/widgets/visualizer.dart';
import '../../shared/widgets/visualizer_ring.dart';

class NowPlayingScreen extends StatelessWidget {
  final VizStyle visualizer;
  final bool radial;

  const NowPlayingScreen({
    super.key,
    this.visualizer = VizStyle.spectrum,
    this.radial = true,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerState>();
    final track = state.currentTrack;
    final progress = state.progress;
    final isFav = state.favorites.contains(track.id);
    final recs = recommendations(track.id);
    final accent = AppTokens.accent();

    return Container(
      color: AppTokens.bg,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  GhostButton(
                    onTap: state.closePlayer,
                    child: const Icon(Icons.expand_more, size: 22),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('PLAYING FROM ALBUM',
                            style: AppType.mono(size: 10, color: AppTokens.dim, letterSpacing: 1.6)),
                        const SizedBox(height: 2),
                        Text(track.album, style: AppType.sans(size: 13)),
                      ],
                    ),
                  ),
                  GhostButton(
                    onTap: () {},
                    child: const Icon(Icons.more_vert, size: 22),
                  ),
                ],
              ),
            ),
            if (radial)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
                child: Center(
                  child: VisualizerRing(
                    seed: track.seed,
                    bars: 110,
                    size: 300,
                    progress: progress,
                    accent: accent,
                    playing: state.playing,
                    style: visualizer,
                    onScrubStart: state.scrubStart,
                    onScrub: (p) => state.scrub(p * track.duration),
                    onScrubEnd: state.scrubEnd,
                    child: AnimatedScale(
                      scale: state.playing ? 1.0 : 0.96,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      child: ClipOval(
                        child: Cover(
                          tone: track.cover,
                          seed: track.seed,
                          size: 170,
                          radius: 0,
                          bars: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 8),
                child: AnimatedScale(
                  scale: state.playing ? 1.0 : 0.97,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (_, c) => Cover(
                        tone: track.cover,
                        seed: track.seed,
                        size: c.maxWidth,
                        radius: 16,
                        bars: 24,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
              child: Row(
                mainAxisAlignment: radial
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: radial
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: radial ? TextAlign.center : TextAlign.start,
                          style: AppType.title(),
                        ),
                        const SizedBox(height: 4),
                        Text(track.artist, style: AppType.caption(size: 14)),
                      ],
                    ),
                  ),
                  if (!radial)
                    GhostButton(
                      onTap: () => state.toggleFavorite(track.id),
                      color: isFav ? accent : AppTokens.dim,
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
            if (!radial) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Visualizer(
                  style: visualizer == VizStyle.spectrum
                      ? VizStyle.waveform
                      : visualizer,
                  seed: track.seed,
                  progress: progress,
                  height: 72,
                  accent: accent,
                  playing: state.playing,
                  onScrubStart: state.scrubStart,
                  onScrub: (p) => state.scrub(p * track.duration),
                  onScrubEnd: state.scrubEnd,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: _Timestamps(state: state, track: track),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                child: _Timestamps(state: state, track: track),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CtlButton(
                    icon: Icons.shuffle,
                    active: state.shuffle,
                    onTap: state.toggleShuffle,
                  ),
                  CtlButton(icon: Icons.skip_previous, iconSize: 28, onTap: state.previous),
                  Material(
                    color: accent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: state.togglePlay,
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(
                          state.playing ? Icons.pause : Icons.play_arrow,
                          size: 30,
                          color: const Color(0xFF0A0A0C),
                        ),
                      ),
                    ),
                  ),
                  CtlButton(icon: Icons.skip_next, iconSize: 28, onTap: state.next),
                  CtlButton(
                    icon: Icons.repeat,
                    active: state.repeat,
                    onTap: state.toggleRepeat,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('AFFINITY · LOCAL',
                          style: AppType.mono(size: 10, color: AppTokens.dim2, letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: "Because you're playing ",
                            style: AppType.body(),
                          ),
                          TextSpan(
                            text: track.genre,
                            style: AppType.body(color: accent),
                          ),
                        ]),
                      ),
                    ],
                  ),
                  GhostButton(onTap: () {}, child: const Icon(Icons.queue_music, size: 20)),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                itemCount: recs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final r = recs[i];
                  return GestureDetector(
                    onTap: () => context.read<PlayerState>().playTrack(r.id),
                    child: SizedBox(
                      width: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Cover(tone: r.cover, seed: r.seed, size: 120, radius: 10, bars: 18),
                          const SizedBox(height: 8),
                          Text(r.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.sans(size: 12.5, weight: FontWeight.w500)),
                          const SizedBox(height: 1),
                          Text(r.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.caption(size: 11)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Timestamps extends StatelessWidget {
  final PlayerState state;
  final dynamic track;
  const _Timestamps({required this.state, required this.track});

  @override
  Widget build(BuildContext context) {
    final remain = (track.duration - state.position).clamp(0, track.duration).toInt();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(fmtDur(state.position),
            style: AppType.mono(size: 11, color: AppTokens.dim, letterSpacing: 0.4)),
        Text('-${fmtDur(remain)}',
            style: AppType.mono(size: 11, color: AppTokens.dim, letterSpacing: 0.4)),
      ],
    );
  }
}
