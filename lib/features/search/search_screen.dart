import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/models.dart';
import '../../core/data/seed_data.dart';
import '../../core/state/player_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/buttons.dart' as ab;
import '../../shared/widgets/track_row.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _q = '';
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<Track>? get _results {
    if (_q.trim().isEmpty) return null;
    final qq = _q.toLowerCase();
    return kLibrary
        .where((t) =>
            t.title.toLowerCase().contains(qq) ||
            t.artist.toLowerCase().contains(qq) ||
            t.album.toLowerCase().contains(qq))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<PlayerState>();
    final results = _results;
    final suggestions = ['Midnight', 'Lianne Hoffmann', 'Ambient', 'Pendant'];
    final recents = state.recentSearches;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: _SearchField(
            controller: _ctrl,
            focusNode: _focus,
            focused: _focused,
            onChanged: (v) => setState(() => _q = v),
            onClear: () {
              _ctrl.clear();
              setState(() => _q = '');
            },
          ),
        ),
        if (results == null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _HintCard(
              onTap: () => state.navigate(AppRoute.download),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: _SectionLabel(label: 'Suggestions'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in suggestions)
                  ab.Chip(
                    label: s,
                    onTap: () {
                      _ctrl.text = s;
                      setState(() => _q = s);
                    },
                  ),
              ],
            ),
          ),
          if (recents.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: _SectionLabel(label: 'Recent'),
            ),
            for (final r in recents)
              InkWell(
                onTap: () {
                  _ctrl.text = r;
                  setState(() => _q = r);
                },
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTokens.hairline)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 16, color: AppTokens.dim),
                      const SizedBox(width: 12),
                      Expanded(child: Text(r, style: AppType.sans(size: 14))),
                    ],
                  ),
                ),
              ),
          ],
        ] else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Text(
              '${results.length} LOCAL MATCH${results.length == 1 ? '' : 'ES'}',
              style: AppType.mono(size: 11, color: AppTokens.dim, letterSpacing: 0.6),
            ),
          ),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  Text('No matches on device.',
                      style: AppType.body(color: AppTokens.dim)),
                  const SizedBox(height: 16),
                  ab.PrimaryButton(
                    label: 'Search & download "$_q"',
                    leading: Icons.download_outlined,
                    onTap: () => state.navigate(AppRoute.download),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [for (final t in results) TrackRow(track: t)],
              ),
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: focused ? AppTokens.surface1 : AppTokens.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: focused ? AppTokens.accent() : AppTokens.hairline,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppTokens.dim),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              cursorColor: AppTokens.accent(),
              style: AppType.sans(size: 14.5),
              decoration: InputDecoration(
                hintText: 'Songs, artists, albums…',
                hintStyle: AppType.sans(size: 14.5, color: AppTokens.dim2),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            ab.GhostButton(
              onTap: onClear,
              child: const Icon(Icons.close, size: 16),
            ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final VoidCallback onTap;
  const _HintCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface1,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTokens.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.link, size: 18, color: AppTokens.accent()),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Paste a link',
                        style: AppType.sans(size: 14, weight: FontWeight.w500)),
                    const SizedBox(height: 1),
                    Text('Download by URL · MP3, M4A, Opus',
                        style: AppType.caption()),
                  ],
                ),
              ),
              const Icon(Icons.add, size: 18, color: AppTokens.dim),
            ],
          ),
        ),
      ),
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
