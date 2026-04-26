import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/seed_data.dart';
import '../../core/state/player_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cover.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/track_row.dart';
import '../../shared/widgets/waveform.dart';

class ArtistScreen extends StatelessWidget {
  const ArtistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerState>();
    final name = state.artistName;
    if (name == null) {
      return Center(child: Text('Artist not found', style: AppType.body()));
    }
    final artist = kArtists.where((a) => a.name == name).cast<dynamic>().firstWhere(
          (a) => true,
          orElse: () => null,
        );
    final tracks = tracksByArtist(name);
    final albums = kAlbums.where((a) => a.artist == name).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: GhostButton(
            onTap: () => state.navigate(AppRoute.library),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        ScreenHeader(
          eyebrow:
              '${tracks.length} TRACKS · ${albums.length} ALBUM${albums.length == 1 ? '' : 'S'}',
          title: name,
          subtitle: artist?.genre,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: SizedBox(
            height: 34,
            child: WaveformLine(
              seed: name.length * 13,
              bars: 60,
              height: 34,
              color: AppTokens.accent(),
              opacity: 0.85,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _SectionLabel(label: 'Albums'),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            itemCount: albums.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final a = albums[i];
              return GestureDetector(
                onTap: () => state.navigate(AppRoute.album, id: a.id),
                child: SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Cover(tone: a.cover, seed: a.trackIds.length * 7 + 1, size: 140, radius: 10, bars: 18),
                      const SizedBox(height: 8),
                      Text(a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.sans(size: 13)),
                      Text('${a.year}', style: AppType.caption(size: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 6),
          child: _SectionLabel(label: 'Tracks'),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) =>
      Text(label.toUpperCase(), style: AppType.sectionLabel());
}
