import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/seed_data.dart';
import '../../core/state/player_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cover.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/track_row.dart';
import '../../shared/widgets/waveform.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _tab = 'albums';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerState>();
    final totalSize = kLibrary.fold<double>(0, (s, t) => s + t.size);
    final totalTracks = kLibrary.length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ScreenHeader(
            eyebrow: 'Local · 100% on device',
            title: 'Library',
            subtitle: '$totalTracks tracks · ${totalSize.toStringAsFixed(1)} MB · offline',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GhostButton(
                  onTap: () => state.navigate(AppRoute.search),
                  child: const Icon(Icons.search, size: 20),
                ),
                GhostButton(
                  onTap: () => state.navigate(AppRoute.settings),
                  child: const Icon(Icons.settings_outlined, size: 20),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _Tabs(value: _tab, onChange: (v) => setState(() => _tab = v))),
        SliverToBoxAdapter(child: _buildTab(state.libraryGrid)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildTab(bool grid) {
    switch (_tab) {
      case 'albums':
        return grid ? const _LibraryAlbumsGrid() : const _LibraryAlbums();
      case 'artists':
        return const _LibraryArtists();
      case 'genres':
        return const _LibraryGenres();
      case 'songs':
      default:
        return const _LibrarySongs();
    }
  }
}

class _Tabs extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChange;
  const _Tabs({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      ('albums', 'Albums'),
      ('artists', 'Artists'),
      ('genres', 'Genres'),
      ('songs', 'Songs'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in tabs) ...[
              _Tab(label: t.$2, active: value == t.$1, onTap: () => onChange(t.$1)),
              const SizedBox(width: 22),
            ]
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppTokens.accent() : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppType.sans(
            size: 14,
            weight: FontWeight.w500,
            color: active ? AppTokens.fg : AppTokens.dim,
          ),
        ),
      ),
    );
  }
}

class _LibraryAlbums extends StatelessWidget {
  const _LibraryAlbums();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final a in kAlbums)
            _ShelfRow(
              album: a,
              onTap: () => context.read<PlayerState>().navigate(AppRoute.album, id: a.id),
            ),
        ],
      ),
    );
  }
}

class _ShelfRow extends StatelessWidget {
  final dynamic album;
  final VoidCallback onTap;
  const _ShelfRow({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tracks = album.trackIds.map(lookupTrack).whereType<dynamic>().toList();
    final totalDur = tracks.fold<int>(0, (s, t) => s + (t.duration as int));
    final tone = kCoverTones[album.cover] ?? kCoverTones['c-indigo']!;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Cover(tone: album.cover, seed: album.trackIds.length * 7 + 1, size: 44, radius: 8, bars: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(album.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.sans(size: 15, weight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            '${album.artist} · ${tracks.length} · ${fmtDur(totalDur)}',
                            style: AppType.mono(size: 12, color: AppTokens.dim, letterSpacing: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 28,
                  child: WaveformLine(
                    seed: tone.hue.round() + (album.year as int),
                    bars: 72,
                    height: 28,
                    color: AppTokens.tonalSignature(tone.hue),
                    opacity: 0.78,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryArtists extends StatelessWidget {
  const _LibraryArtists();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (final ar in kArtists)
            InkWell(
              onTap: () => context.read<PlayerState>().navigate(AppRoute.artist, name: ar.name),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTokens.hairline)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Cover(tone: ar.cover, seed: ar.id.length * 3, size: 40, radius: 999, bars: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(ar.name, style: AppType.sans(size: 15)),
                          const SizedBox(height: 2),
                          Text(
                            '${ar.trackCount} tracks · ${ar.genre}',
                            style: AppType.mono(size: 11.5, color: AppTokens.dim, letterSpacing: 0.4),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: AppTokens.dim),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LibraryGenres extends StatelessWidget {
  const _LibraryGenres();

  @override
  Widget build(BuildContext context) {
    final genres = <String>{for (final t in kLibrary) t.genre}.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          for (final g in genres) _GenreCard(genre: g),
        ],
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  final String genre;
  const _GenreCard({required this.genre});

  @override
  Widget build(BuildContext context) {
    final hue = (genre.codeUnitAt(0) * 13) % 360;
    final count = kLibrary.where((t) => t.genre == genre).length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTokens.hairline),
        gradient: LinearGradient(
          begin: const Alignment(-0.2, -1),
          end: const Alignment(0.2, 1),
          colors: [
            AppTokens.tonalLow(hue.toDouble()),
            AppTokens.tonalLower(hue.toDouble()),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(genre, style: AppType.sans(size: 15, weight: FontWeight.w500)),
              Text('$count', style: AppType.mono(size: 11, color: const Color(0x99FFFFFF))),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 22,
            child: WaveformLine(
              seed: hue,
              bars: 40,
              height: 22,
              color: AppTokens.tonalSignature(hue.toDouble()),
              opacity: 0.85,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryAlbumsGrid extends StatelessWidget {
  const _LibraryAlbumsGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        childAspectRatio: 0.78,
        children: [
          for (final a in kAlbums)
            _GridAlbum(
              album: a,
              onTap: () => context.read<PlayerState>().navigate(AppRoute.album, id: a.id),
            ),
        ],
      ),
    );
  }
}

class _GridAlbum extends StatelessWidget {
  final dynamic album;
  final VoidCallback onTap;
  const _GridAlbum({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (_, c) => Cover(
                  tone: album.cover,
                  seed: album.trackIds.length * 7 + 1,
                  size: c.maxWidth,
                  radius: 10,
                  bars: 18,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(album.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.sans(size: 13.5, weight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(album.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption(size: 11.5)),
          ],
        ),
      ),
    );
  }
}

class _LibrarySongs extends StatelessWidget {
  const _LibrarySongs();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          for (final t in kLibrary) TrackRow(track: t),
        ],
      ),
    );
  }
}
