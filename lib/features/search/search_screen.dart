import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/models.dart';
import '../../core/integrations/youtube/youtube_download_options_service.dart';
import '../../core/integrations/youtube/youtube_link_resolver_service.dart';
import '../../core/integrations/youtube/youtube_search_service.dart';
import '../../core/state/player_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/buttons.dart' as ab;
import '../../shared/widgets/loading_bars.dart';

class SearchScreen extends StatefulWidget {
  final SearchSongsService? searchService;
  final DownloadOptionsService? downloadOptionsService;
  final LinkResolverService? linkResolverService;

  const SearchScreen({
    super.key,
    this.searchService,
    this.downloadOptionsService,
    this.linkResolverService,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  late final SearchSongsService _searchService =
      widget.searchService ?? const YoutubeSearchService();
  late final DownloadOptionsService _downloadOptionsService =
      widget.downloadOptionsService ?? const YoutubeDownloadOptionsService();
  late final LinkResolverService _linkResolverService =
      widget.linkResolverService ?? const YoutubeLinkResolverService();

  static final RegExp _urlPattern = RegExp(
    r'^(https?:\/\/)?(www\.|m\.|music\.)?(youtube\.com|youtu\.be)(\/|$)',
    caseSensitive: false,
  );

  String _query = '';
  bool _focused = false;
  bool _loading = false;
  List<RemoteSearchResult> _results = const [];
  String? _errorMessage;
  String? _lastSubmittedQuery;
  bool _hasSubmitted = false;

  bool _resolvingLink = false;
  RemoteSearchResult? _resolvedResult;
  LinkResolutionExceptionKind? _resolvedLinkError;
  String? _lastSubmittedLink;
  bool _linkSheetAlreadyAutoOpened = false;

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

    if (_isYoutubeUrl(normalized)) {
      await _resolveLink(normalized);
      return;
    }

    setState(() {
      _query = normalized;
      _hasSubmitted = true;
      _errorMessage = null;
      _resolvingLink = false;
      _resolvedResult = null;
      _resolvedLinkError = null;
      _lastSubmittedLink = null;
      _linkSheetAlreadyAutoOpened = false;
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

  bool _isYoutubeUrl(String text) => _urlPattern.hasMatch(text);

  bool get _isLinkBranchActive =>
      _resolvingLink || _resolvedResult != null || _resolvedLinkError != null;

  Future<void> _resolveLink(String trimmedUrl) async {
    setState(() {
      _query = trimmedUrl;
      _hasSubmitted = true;
      _resolvingLink = true;
      _resolvedResult = null;
      _resolvedLinkError = null;
      _linkSheetAlreadyAutoOpened = false;
      _lastSubmittedLink = trimmedUrl;
      _loading = false;
      _results = const [];
      _errorMessage = null;
      _lastSubmittedQuery = null;
    });

    try {
      final result = await _linkResolverService.resolve(trimmedUrl);
      if (!mounted) return;
      setState(() {
        _resolvingLink = false;
        _resolvedResult = result;
      });
      _scheduleAutoOpen();
    } on LinkResolutionException catch (e) {
      if (!mounted) return;
      setState(() {
        _resolvingLink = false;
        _resolvedLinkError = e.kind;
      });
    }
  }

  void _scheduleAutoOpen() {
    if (_linkSheetAlreadyAutoOpened) return;
    final result = _resolvedResult;
    if (result == null) return;
    _linkSheetAlreadyAutoOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openDownloadOptions(result);
    });
  }

  void _setAndSubmit(String query) {
    _ctrl.text = query;
    _submit(query);
  }

  Future<void> _openDownloadOptions(RemoteSearchResult result) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTokens.bg,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DownloadOptionsSheet(
        result: result,
        service: _downloadOptionsService,
      ),
    );
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
                _resolvingLink = false;
                _resolvedResult = null;
                _resolvedLinkError = null;
                _lastSubmittedLink = null;
                _linkSheetAlreadyAutoOpened = false;
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
            child: _isLinkBranchActive
                ? _ResolvedLinkBody(
                    resolving: _resolvingLink,
                    result: _resolvedResult,
                    errorKind: _resolvedLinkError,
                    onResultTap: _openDownloadOptions,
                    onRetry: _lastSubmittedLink == null
                        ? null
                        : () => _resolveLink(_lastSubmittedLink!),
                  )
                : _SearchBody(
                    query: _query,
                    loading: _loading,
                    results: _results,
                    errorMessage: _errorMessage,
                    onResultTap: _openDownloadOptions,
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
                hintText: 'Buscar o pegar enlace de YouTube',
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
  final ValueChanged<RemoteSearchResult> onResultTap;
  final VoidCallback? onRetry;

  const _SearchBody({
    required this.query,
    required this.loading,
    required this.results,
    required this.errorMessage,
    required this.onResultTap,
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
        leading: LoadingBars(),
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
        for (final result in results)
          _RemoteResultRow(result: result, onTap: () => onResultTap(result)),
      ],
    );
  }
}

class _ResolvedLinkBody extends StatelessWidget {
  final bool resolving;
  final RemoteSearchResult? result;
  final LinkResolutionExceptionKind? errorKind;
  final ValueChanged<RemoteSearchResult> onResultTap;
  final VoidCallback? onRetry;

  const _ResolvedLinkBody({
    required this.resolving,
    required this.result,
    required this.errorKind,
    required this.onResultTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (resolving) {
      return const _StatePanel(
        leading: LoadingBars(),
        message: 'Resolviendo enlace...',
      );
    }
    final kind = errorKind;
    if (kind != null) {
      return _buildError(kind);
    }
    final value = result;
    if (value != null) {
      return _RemoteResultRow(
        result: value,
        onTap: () => onResultTap(value),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildError(LinkResolutionExceptionKind kind) {
    switch (kind) {
      case LinkResolutionExceptionKind.invalid:
        return const _StatePanel(
          icon: Icons.link_off,
          message:
              'El enlace no es válido. Pega un enlace de YouTube o YouTube Music.',
        );
      case LinkResolutionExceptionKind.playlistOnly:
        return const _StatePanel(
          icon: Icons.playlist_remove,
          message:
              'Las listas de reproducción aún no son compatibles. Pega el enlace de una canción.',
        );
      case LinkResolutionExceptionKind.network:
        return _StatePanel(
          icon: Icons.wifi_off,
          message:
              'No se pudo resolver el enlace. Revisa tu conexión e inténtalo de nuevo.',
          actionLabel: 'Reintentar',
          onAction: onRetry,
        );
      case LinkResolutionExceptionKind.unavailable:
        return const _StatePanel(
          icon: Icons.videocam_off,
          message: 'El video no está disponible.',
        );
    }
  }
}

class _RemoteResultRow extends StatelessWidget {
  final RemoteSearchResult result;
  final VoidCallback onTap;

  const _RemoteResultRow({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          onTap: onTap,
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

class _DownloadOptionsSheet extends StatefulWidget {
  final RemoteSearchResult result;
  final DownloadOptionsService service;

  const _DownloadOptionsSheet({
    required this.result,
    required this.service,
  });

  @override
  State<_DownloadOptionsSheet> createState() => _DownloadOptionsSheetState();
}

class _DownloadOptionsSheetState extends State<_DownloadOptionsSheet> {
  RemoteSearchResult? activeDownloadResult;
  bool downloadOptionsLoading = true;
  List<DownloadOption> downloadOptions = const [];
  String? downloadOptionsError;
  String? selectedDownloadOptionId;
  bool downloadPrepared = false;

  @override
  void initState() {
    super.initState();
    activeDownloadResult = widget.result;
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    setState(() {
      downloadOptionsLoading = true;
      downloadOptionsError = null;
      selectedDownloadOptionId = null;
      downloadPrepared = false;
    });

    try {
      final options = await widget.service.fetchOptions(widget.result);
      if (!mounted) return;
      setState(() {
        downloadOptionsLoading = false;
        downloadOptions = options;
      });
    } on DownloadOptionsException {
      if (!mounted) return;
      setState(() {
        downloadOptionsLoading = false;
        downloadOptions = const [];
        downloadOptionsError =
            'No se pudieron cargar las opciones. Revisa tu conexión e inténtalo de nuevo.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        downloadOptionsLoading = false;
        downloadOptions = const [];
        downloadOptionsError =
            'No se pudieron cargar las opciones. Revisa tu conexión e inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final realOptions = downloadOptions.where((option) => !option.disabled);
    final selected = downloadOptions
        .where((option) => option.id == selectedDownloadOptionId)
        .firstOrNull;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTokens.surface3,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Opciones de descarga',
                  style: AppType.sans(size: 20, weight: FontWeight.w500),
                ),
              ),
              ab.GhostButton(
                size: 34,
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.result.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.caption(),
          ),
          const SizedBox(height: 16),
          if (downloadPrepared)
            _PreparedPanel(option: selected)
          else if (downloadOptionsLoading)
            const _SheetStatePanel(
              leading: LoadingBars(),
              message: 'Buscando calidades disponibles...',
            )
          else if (downloadOptionsError != null)
            _SheetStatePanel(
              icon: Icons.wifi_off,
              message: downloadOptionsError!,
              actionLabel: 'Reintentar',
              onAction: _fetchOptions,
            )
          else ...[
            if (realOptions.isEmpty)
              const _SheetStatePanel(
                icon: Icons.music_off,
                message: 'No hay opciones de audio disponibles para esta canción.',
              )
            else ...[
              const _OptionLabelsRow(),
              const SizedBox(height: 8),
            ],
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in downloadOptions)
                      _DownloadOptionRow(
                        option: option,
                        selected: option.id == selectedDownloadOptionId,
                        onTap: option.disabled
                            ? null
                            : () => setState(
                                  () => selectedDownloadOptionId = option.id,
                                ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            ab.PrimaryButtonBlock(
              label: 'Preparar descarga',
              leading: Icons.download_done_outlined,
              enabled: selectedDownloadOptionId != null,
              onTap: () => setState(() => downloadPrepared = true),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionLabelsRow extends StatelessWidget {
  const _OptionLabelsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Formato', style: AppType.sectionLabel())),
        Expanded(child: Text('Calidad', style: AppType.sectionLabel())),
        Expanded(
          child: Text(
            'Tamaño aproximado',
            textAlign: TextAlign.right,
            style: AppType.sectionLabel(),
          ),
        ),
      ],
    );
  }
}

class _DownloadOptionRow extends StatelessWidget {
  final DownloadOption option;
  final bool selected;
  final VoidCallback? onTap;

  const _DownloadOptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent();
    final fg = option.disabled ? AppTokens.dim2 : AppTokens.fg;
    final quality = option.quality?.label ?? '--';
    final size = option.disabled ? option.disabledReason! : _formatSize(option);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: option.disabled ? 0.48 : 1,
        child: Material(
          color: selected ? AppTokens.accentSoft() : AppTokens.surface1,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(
                  color: selected ? accent : AppTokens.hairline,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.format.label,
                      style: AppType.sans(size: 14, color: fg),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      quality,
                      style: AppType.mono(size: 12, color: fg),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      size,
                      textAlign: TextAlign.right,
                      style: AppType.mono(
                        size: 12,
                        color: selected ? accent : fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreparedPanel extends StatelessWidget {
  final DownloadOption? option;

  const _PreparedPanel({required this.option});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: AppTokens.accent()),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: AppTokens.accent(), size: 30),
          const SizedBox(height: 12),
          Text(
            'Descarga preparada',
            style: AppType.sans(size: 18, weight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          if (option != null)
            Text(
              '${option!.format.label} · ${option!.quality!.label} · ${_formatSize(option!)}',
              style: AppType.mono(size: 12, color: AppTokens.dim),
            ),
          const SizedBox(height: 8),
          Text(
            'La descarga local se completará en una historia posterior.',
            textAlign: TextAlign.center,
            style: AppType.body(color: AppTokens.dim),
          ),
        ],
      ),
    );
  }
}

class _SheetStatePanel extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SheetStatePanel({
    this.icon,
    this.leading,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : assert(icon != null || leading != null,
            'icon or leading must be provided');

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
          leading ?? Icon(icon, color: AppTokens.accent(), size: 26),
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
  final IconData? icon;
  final Widget? leading;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatePanel({
    this.icon,
    this.leading,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : assert(icon != null || leading != null,
            'icon or leading must be provided');

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
          leading ?? Icon(icon, color: AppTokens.accent(), size: 26),
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

String _formatSize(DownloadOption option) {
  final bytes = option.sizeBytes;
  if (bytes == null) return 'Tamaño no disponible';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
