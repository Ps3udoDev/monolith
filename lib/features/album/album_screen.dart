import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/seed_data.dart';
import '../../core/state/player_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cover.dart';
import '../../shared/widgets/track_row.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerState>();
    final albId = state.albumId;
    final alb = albId == null
        ? null
        : kAlbums.where((a) => a.id == albId).cast<dynamic>().firstWhere(
              (a) => true,
              orElse: () => null,
            );
    if (alb == null) {
      return Center(child: Text('Album not found', style: AppType.body()));
    }
    final tracks =
        alb.trackIds.map(lookupTrack).whereType<dynamic>().toList();
    final totalDur = tracks.fold<int>(0, (s, t) => s + (t.duration as int));
    final totalSize = tracks.fold<double>(0, (s, t) => s + (t.size as double));
    final tone = kCoverTones[alb.cover] ?? kCoverTones['c-indigo']!;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tone.b.withValues(alpha: 0.27),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: GhostButton(
                  onTap: () => state.navigate(AppRoute.library),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Cover(tone: alb.cover, seed: alb.trackIds.length * 7 + 1, size: 120, radius: 12, bars: 18),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${alb.year} · ALBUM',
                              style: AppType.mono(size: 10, color: AppTokens.dim2, letterSpacing: 1.2)),
                          const SizedBox(height: 4),
                          Text(alb.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.sans(
                                size: 24,
                                weight: FontWeight.w500,
                                letterSpacing: -0.5,
                                height: 1.15,
                              )),
                          const SizedBox(height: 4),
                          Text(alb.artist, style: AppType.caption(size: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${tracks.length} tracks · ${fmtDur(totalDur)} · ${totalSize.toStringAsFixed(1)} MB',
                        style: AppType.mono(size: 11, color: AppTokens.dim, letterSpacing: 0.4),
                      ),
                    ),
                    GhostButton(onTap: () {}, child: const Icon(Icons.shuffle, size: 20)),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      label: 'Play',
                      leading: Icons.play_arrow,
                      onTap: () => state.playTrack(tracks.first.id as String),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              for (var i = 0; i < tracks.length; i++)
                TrackRow(track: tracks[i], index: i, showNumber: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
