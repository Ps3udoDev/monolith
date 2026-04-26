import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/models.dart';
import '../../core/integrations/youtube/youtube_search_service.dart';
import '../../core/state/player_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/buttons.dart' as ab;

class SearchScreen extends StatefulWidget {
  final SearchSongsService? searchService;

  const SearchScreen({super.key, this.searchService});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  late final SearchSongsService _searchService =
      widget.searchService ?? const YoutubeSearchService();

  String _query = '';
  bool _focused = false;
  bool _loading = false;
  List<RemoteSearchResult> _results = const [];
  String? _errorMessage;
  String? _lastSubmittedQuery;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit([String? rawQuery]) async {
    final normalized = (rawQuery ?? _ctrl.text).trim();
    setState(() {
      _query = normalized;
      _hasSubmitted = true;
      _errorMessage = null;
    });

    if (normalized.length < 2) {
      setState(() {
        _loading = false;
        _results = const [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _results = const [];
      _lastSubmittedQuery = normalized;
    });

    try {
      final results = await _searchService.searchSongs(normalized, limit: 10);
      if (!mounted) return;
      context.read<PlayerState>().addRecentSearch(normalized);
      setState(() {
        _loading = false;
        _results = results.take(10).toList(growable: false);
      });
    } on RemoteSearchException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage =
            'No se pudo completar la busqueda. Revisa tu conexion e intentalo de nuevo.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage =
            'No se pudo completar la busqueda. Revisa tu conexion e intentalo de nuevo.';
      });
    }
  }

  void _setAndSubmit(String query) {
    _ctrl.text = query;
    _submit(query);
  }

  @override
  Widget build(BuildContext context) {
    final recents = context.watch<PlayerState>().recentSearches;
    final suggestions = ['Midnight', 'Lianne Hoffmann', 'Ambient', 'Pendant'];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: _SearchField(
            controller: _ctrl,
            focusNode: _focus,
            focused: _focused,
            loading: _loading,
            onChanged: (value) => setState(() => _query = value),
            onSubmitted: _submit,
            onClear: () {
              _ctrl.clear();
              setState(() {
                _query = '';
                _hasSubmitted = false;
                _loading = false;
                _results = const [];
                _errorMessage = null;
              });
            },
          ),
        ),
        if (!_hasSubmitted) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: _SectionLabel(label: 'Sugerencias'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in suggestions)
                  ab.Chip(
                    label: suggestion,
                    onTap: () => _setAndSubmit(suggestion),
                  ),
              ],
            ),
          ),
          if (recents.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: _SectionLabel(label: 'Recientes'),
            ),
            for (final recent in recents)
              _RecentSearchRow(
                label: recent,
                onTap: () => _setAndSubmit(recent),
              ),
          ],
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _SearchBody(
              query: _query,
              loading: _loading,
              results: _results,
              errorMessage: _errorMessage,
              onRetry: _lastSubmittedQuery == null
                  ? null
                  : () => _submit(_lastSubmittedQuery),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool loading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.loading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: focused ? AppTokens.surface1 : AppTokens.surface2,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
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
              enabled: !loading,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: AppTokens.accent(),
              style: AppType.sans(size: 14.5),
              decoration: InputDecoration(
                hintText: 'Buscar canciones, artistas o albumes',
                hintStyle: AppType.sans(size: 14.5, color: AppTokens.dim2),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
          ab.PrimaryButton(
            label: 'Buscar',
            leading: Icons.search,
            onTap: loading ? null : () => onSubmitted(controller.text),
          ),
          if (controller.text.isNotEmpty)
            ab.GhostButton(
              onTap: loading ? null : onClear,
              child: const Icon(Icons.close, size: 16),
            ),
        ],
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  final String query;
  final bool loading;
  final List<RemoteSearchResult> results;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const _SearchBody({
    required this.query,
    required this.loading,
    required this.results,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (query.trim().length < 2) {
      return const _StatePanel(
        icon: Icons.search_off,
        message: 'Escribe al menos 2 caracteres para buscar.',
      );
    }

    if (loading) {
      return const _StatePanel(
        icon: Icons.graphic_eq,
        message: 'Buscando en YouTube Music...',
      );
    }

    if (errorMessage != null) {
      return _StatePanel(
        icon: Icons.wifi_off,
        message: errorMessage!,
        actionLabel: 'Reintentar',
        onAction: onRetry,
      );
    }

    if (results.isEmpty) {
      return const _StatePanel(
        icon: Icons.library_music_outlined,
        message: 'No encontramos canciones para esta busqueda.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${results.length} RESULTADOS',
          style: AppType.mono(
            size: 11,
            color: AppTokens.dim,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        for (final result in results) _RemoteResultRow(result: result),
      ],
    );
  }
}

class _RemoteResultRow extends StatelessWidget {
  final RemoteSearchResult result;

  const _RemoteResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _RemoteThumb(result: result),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        result.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.sans(size: 14.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.caption(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatDuration(result.duration),
                  style: AppType.mono(size: 11, color: AppTokens.dim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoteThumb extends StatelessWidget {
  final RemoteSearchResult result;

  const _RemoteThumb({required this.result});

  @override
  Widget build(BuildContext context) {
    final url = result.thumbnailUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        color: AppTokens.surface3,
        child: url == null
            ? Icon(Icons.music_note, color: AppTokens.accent(), size: 20)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.music_note, color: AppTokens.accent(), size: 20),
              ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatePanel({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTokens.accent(), size: 26),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppType.body(color: AppTokens.dim),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            ab.PrimaryButton(
              label: actionLabel!,
              leading: Icons.refresh,
              onTap: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RecentSearchRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: AppTokens.dim),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: AppType.sans(size: 14))),
              ],
            ),
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
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: AppType.sectionLabel());
  }
}

String _formatDuration(Duration? duration) {
  if (duration == null) return '--';
  return fmtDur(duration.inSeconds);
}
