import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monolith/core/data/models.dart';
import 'package:monolith/core/integrations/youtube/youtube_download_options_service.dart';
import 'package:monolith/core/integrations/youtube/youtube_link_resolver_service.dart';
import 'package:monolith/core/integrations/youtube/youtube_search_service.dart';
import 'package:monolith/core/state/player_state.dart';
import 'package:monolith/features/search/search_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows invalid query state without calling service', (
    tester,
  ) async {
    final service = _FakeSearchService();
    await _pumpSearch(tester, service);

    await tester.enterText(find.byType(TextField), 'a');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(
      find.text('Escribe al menos 2 caracteres para buscar.'),
      findsOneWidget,
    );
    expect(service.calls, isEmpty);
  });

  testWidgets('shows loading state while search is pending', (tester) async {
    final completer = Completer<List<RemoteSearchResult>>();
    final service = _FakeSearchService(
      onSearch: (_, {limit = 10}) => completer.future,
    );
    await _pumpSearch(tester, service);

    await tester.enterText(find.byType(TextField), 'ambient');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(find.text('Buscando en YouTube Music...'), findsOneWidget);

    completer.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('shows remote results with duration fallback', (tester) async {
    final service = _FakeSearchService(
      results: const [
        RemoteSearchResult(
          id: 'one',
          title: 'Cancion remota',
          artist: 'Artista remoto',
          sourceUrl: 'https://www.youtube.com/watch?v=one',
        ),
      ],
    );
    await _pumpSearch(tester, service);

    await tester.enterText(find.byType(TextField), 'remota');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Cancion remota'), findsOneWidget);
    expect(find.text('Artista remoto'), findsOneWidget);
    expect(find.text('--'), findsOneWidget);
  });

  testWidgets('shows empty state when service returns no results', (
    tester,
  ) async {
    final service = _FakeSearchService(results: const []);
    await _pumpSearch(tester, service);

    await tester.enterText(find.byType(TextField), 'sin resultados');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(
      find.text('No encontramos canciones para esta busqueda.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error state and retries successfully', (tester) async {
    final service = _FakeSearchService(
      onSearch: (query, {limit = 10}) {
        if (query == 'fallo' && limit == 10 && serviceCallCount == 0) {
          serviceCallCount++;
          throw const RemoteSearchException('failed');
        }
        return Future.value(const [
          RemoteSearchResult(
            id: 'two',
            title: 'Resultado recuperado',
            artist: 'Canal',
            sourceUrl: 'https://www.youtube.com/watch?v=two',
          ),
        ]);
      },
    );
    serviceCallCount = 0;
    await _pumpSearch(tester, service);

    await tester.enterText(find.byType(TextField), 'fallo');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No se pudo completar la busqueda. Revisa tu conexion e intentalo de nuevo.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Resultado recuperado'), findsOneWidget);
  });

  testWidgets('tapping a result opens options without playback or navigation', (
    tester,
  ) async {
    final state = PlayerState()..navigate(AppRoute.search);
    final service = _FakeSearchService(
      results: const [
        RemoteSearchResult(
          id: 'three',
          title: 'Resultado sin accion',
          artist: 'Canal',
          sourceUrl: 'https://www.youtube.com/watch?v=three',
        ),
      ],
    );
    final downloadService = _FakeDownloadOptionsService();
    await _pumpSearch(
      tester,
      service,
      downloadOptionsService: downloadService,
      state: state,
    );

    await tester.enterText(find.byType(TextField), 'accion');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resultado sin accion'));
    await tester.pumpAndSettle();

    expect(find.text('Opciones de descarga'), findsOneWidget);
    expect(state.route, AppRoute.search);
    expect(state.playerOpen, isFalse);
    expect(state.playing, isFalse);
    expect(downloadService.calls, ['three']);
  });

  testWidgets('shows loading while download options are pending', (
    tester,
  ) async {
    final completer = Completer<List<DownloadOption>>();
    final service = _FakeSearchService(results: const [_remoteResult]);
    final downloadService = _FakeDownloadOptionsService(
      onFetch: (_) => completer.future,
    );
    await _pumpSearch(
      tester,
      service,
      downloadOptionsService: downloadService,
    );

    await _showResultOptions(tester);

    expect(
      find.text('Buscando calidades disponibles...'),
      findsOneWidget,
    );

    completer.complete(const [_mp3Option]);
    await tester.pumpAndSettle();
  });

  testWidgets('shows available options with format quality and size', (
    tester,
  ) async {
    final service = _FakeSearchService(results: const [_remoteResult]);
    final downloadService = _FakeDownloadOptionsService(
      results: const [_m4a128Option, _mp3Option],
    );
    await _pumpSearch(
      tester,
      service,
      downloadOptionsService: downloadService,
    );

    await _showResultOptions(tester);
    await tester.pumpAndSettle();

    expect(find.text('Formato'), findsOneWidget);
    expect(find.text('Calidad'), findsOneWidget);
    expect(find.text('Tamaño aproximado'), findsOneWidget);
    expect(find.text('M4A'), findsOneWidget);
    expect(find.text('128 kbps'), findsOneWidget);
    expect(find.text('3.0 MB'), findsOneWidget);
  });

  testWidgets('disabled MP3 row cannot be selected', (tester) async {
    final service = _FakeSearchService(results: const [_remoteResult]);
    final downloadService = _FakeDownloadOptionsService(
      results: const [_m4a128Option, _mp3Option],
    );
    await _pumpSearch(
      tester,
      service,
      downloadOptionsService: downloadService,
    );

    await _showResultOptions(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('MP3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preparar descarga'));
    await tester.pumpAndSettle();

    expect(find.text('Requiere conversion'), findsOneWidget);
    expect(find.text('Descarga preparada'), findsNothing);
  });

  testWidgets('shows no-options state when only MP3 is available', (
    tester,
  ) async {
    final service = _FakeSearchService(results: const [_remoteResult]);
    final downloadService = _FakeDownloadOptionsService(
      results: const [_mp3Option],
    );
    await _pumpSearch(
      tester,
      service,
      downloadOptionsService: downloadService,
    );

    await _showResultOptions(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('No hay opciones de audio disponibles para esta canción.'),
      findsOneWidget,
    );
    expect(find.text('MP3'), findsOneWidget);
  });

  testWidgets('shows download options error and retries', (tester) async {
    var calls = 0;
    final service = _FakeSearchService(results: const [_remoteResult]);
    final downloadService = _FakeDownloadOptionsService(
      onFetch: (_) {
        calls++;
        if (calls == 1) {
          throw const DownloadOptionsException('failed');
        }
        return Future.value(const [_m4a128Option, _mp3Option]);
      },
    );
    await _pumpSearch(
      tester,
      service,
      downloadOptionsService: downloadService,
    );

    await _showResultOptions(tester);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No se pudieron cargar las opciones. Revisa tu conexión e inténtalo de nuevo.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('M4A'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('selecting an option enables preparation', (tester) async {
    final service = _FakeSearchService(results: const [_remoteResult]);
    final downloadService = _FakeDownloadOptionsService(
      results: const [_m4a128Option, _mp3Option],
    );
    await _pumpSearch(
      tester,
      service,
      downloadOptionsService: downloadService,
    );

    await _showResultOptions(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('M4A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preparar descarga'));
    await tester.pumpAndSettle();

    expect(find.text('Descarga preparada'), findsOneWidget);
    expect(
      find.text('La descarga local se completará en una historia posterior.'),
      findsOneWidget,
    );
  });

  testWidgets('preparing an option does not mutate route or playback', (
    tester,
  ) async {
    final state = PlayerState()..navigate(AppRoute.search);
    final service = _FakeSearchService(results: const [_remoteResult]);
    final downloadService = _FakeDownloadOptionsService(
      results: const [_m4a128Option, _mp3Option],
    );
    await _pumpSearch(
      tester,
      service,
      downloadOptionsService: downloadService,
      state: state,
    );

    await _showResultOptions(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('M4A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preparar descarga'));
    await tester.pumpAndSettle();

    expect(state.route, AppRoute.search);
    expect(state.playerOpen, isFalse);
    expect(state.playing, isFalse);
  });

  testWidgets('shows unknown size fallback', (tester) async {
    final service = _FakeSearchService(results: const [_remoteResult]);
    final downloadService = _FakeDownloadOptionsService(
      results: const [_unknownSizeOption, _mp3Option],
    );
    await _pumpSearch(
      tester,
      service,
      downloadOptionsService: downloadService,
    );

    await _showResultOptions(tester);
    await tester.pumpAndSettle();

    expect(find.text('Tamaño no disponible'), findsOneWidget);
  });

  testWidgets('hint text invites pasting a YouTube link', (tester) async {
    final service = _FakeSearchService();
    await _pumpSearch(tester, service);

    expect(find.text('Buscar o pegar enlace de YouTube'), findsOneWidget);
  });

  testWidgets(
    'pasting a YouTube URL shows resolving state and renders resolved row',
    (tester) async {
      final completer = Completer<RemoteSearchResult>();
      final service = _FakeSearchService();
      final linkResolver = _FakeLinkResolverService(
        onResolve: (_) => completer.future,
      );
      await _pumpSearch(
        tester,
        service,
        linkResolverService: linkResolver,
      );

      await tester.enterText(
        find.byType(TextField),
        'https://www.youtube.com/watch?v=abc123def45',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(find.text('Resolviendo enlace...'), findsOneWidget);

      completer.complete(_linkResult);
      await tester.pumpAndSettle();

      expect(find.text(_linkResult.title), findsAtLeastNWidgets(1));
      expect(find.text(_linkResult.artist), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'pasting a YouTube URL auto-opens the download sheet exactly once',
    (tester) async {
      final downloadService = _FakeDownloadOptionsService(
        results: const [_m4a128Option, _mp3Option],
      );
      final linkResolver = _FakeLinkResolverService();
      await _pumpSearch(
        tester,
        _FakeSearchService(),
        downloadOptionsService: downloadService,
        linkResolverService: linkResolver,
      );

      await _submitLink(tester);

      expect(find.text('Opciones de descarga'), findsOneWidget);
      expect(downloadService.calls, [_linkResult.id]);
      expect(linkResolver.calls, [_validUrl]);
    },
  );

  testWidgets(
    'closing the auto-opened sheet keeps the row and does not auto-reopen',
    (tester) async {
      final downloadService = _FakeDownloadOptionsService(
        results: const [_m4a128Option, _mp3Option],
      );
      final linkResolver = _FakeLinkResolverService();
      await _pumpSearch(
        tester,
        _FakeSearchService(),
        downloadOptionsService: downloadService,
        linkResolverService: linkResolver,
      );

      await _submitLink(tester);
      expect(find.text('Opciones de descarga'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('Opciones de descarga'), findsNothing);
      expect(find.text(_linkResult.title), findsOneWidget);
      expect(downloadService.calls.length, 1);
    },
  );

  testWidgets(
    'tapping the resolved row after dismissing the sheet reopens it',
    (tester) async {
      final downloadService = _FakeDownloadOptionsService(
        results: const [_m4a128Option, _mp3Option],
      );
      final linkResolver = _FakeLinkResolverService();
      await _pumpSearch(
        tester,
        _FakeSearchService(),
        downloadOptionsService: downloadService,
        linkResolverService: linkResolver,
      );

      await _submitLink(tester);
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text(_linkResult.title));
      await tester.pumpAndSettle();

      expect(find.text('Opciones de descarga'), findsOneWidget);
      expect(downloadService.calls.length, 2);
    },
  );

  testWidgets(
    'submitting a different URL replaces the row and auto-opens again',
    (tester) async {
      const otherResult = RemoteSearchResult(
        id: 'other',
        title: 'Otra cancion',
        artist: 'Otro canal',
        sourceUrl: 'https://www.youtube.com/watch?v=other',
      );
      const otherUrl = 'https://www.youtube.com/watch?v=other';

      final downloadService = _FakeDownloadOptionsService(
        results: const [_m4a128Option, _mp3Option],
      );
      final linkResolver = _FakeLinkResolverService(
        onResolve: (url) async =>
            url == otherUrl ? otherResult : _linkResult,
      );
      await _pumpSearch(
        tester,
        _FakeSearchService(),
        downloadOptionsService: downloadService,
        linkResolverService: linkResolver,
      );

      await _submitLink(tester);
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), otherUrl);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text(otherResult.title), findsAtLeastNWidgets(1));
      expect(find.text(_linkResult.title), findsNothing);
      expect(find.text('Opciones de descarga'), findsOneWidget);
      expect(linkResolver.calls, [_validUrl, otherUrl]);
    },
  );

  testWidgets('playlist URL renders the playlist message and no sheet', (
    tester,
  ) async {
    final downloadService = _FakeDownloadOptionsService();
    final linkResolver = _FakeLinkResolverService(
      onResolve: (_) async =>
          throw const LinkResolutionException.playlistOnly(),
    );
    await _pumpSearch(
      tester,
      _FakeSearchService(),
      downloadOptionsService: downloadService,
      linkResolverService: linkResolver,
    );

    await tester.enterText(
      find.byType(TextField),
      'https://www.youtube.com/playlist?list=PLabcDEF12',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Las listas de reproducción aún no son compatibles. Pega el enlace de una canción.',
      ),
      findsOneWidget,
    );
    expect(find.text('Opciones de descarga'), findsNothing);
    expect(downloadService.calls, isEmpty);
  });

  testWidgets('invalid resolver result renders the invalid message', (
    tester,
  ) async {
    final downloadService = _FakeDownloadOptionsService();
    final linkResolver = _FakeLinkResolverService(
      onResolve: (_) async => throw const LinkResolutionException.invalid(),
    );
    await _pumpSearch(
      tester,
      _FakeSearchService(),
      downloadOptionsService: downloadService,
      linkResolverService: linkResolver,
    );

    await _submitLink(tester);

    expect(
      find.text(
        'El enlace no es válido. Pega un enlace de YouTube o YouTube Music.',
      ),
      findsOneWidget,
    );
    expect(find.text('Opciones de descarga'), findsNothing);
  });

  testWidgets('network failure shows retry; tapping retry resolves once', (
    tester,
  ) async {
    var calls = 0;
    final downloadService = _FakeDownloadOptionsService(
      results: const [_m4a128Option, _mp3Option],
    );
    final linkResolver = _FakeLinkResolverService(
      onResolve: (_) async {
        calls++;
        if (calls == 1) {
          throw LinkResolutionException.network(Exception('boom'));
        }
        return _linkResult;
      },
    );
    await _pumpSearch(
      tester,
      _FakeSearchService(),
      downloadOptionsService: downloadService,
      linkResolverService: linkResolver,
    );

    await _submitLink(tester);

    expect(
      find.text(
        'No se pudo resolver el enlace. Revisa tu conexión e inténtalo de nuevo.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text(_linkResult.title), findsAtLeastNWidgets(1));
    expect(find.text('Opciones de descarga'), findsOneWidget);
  });

  testWidgets('unavailable failure renders the unavailable message', (
    tester,
  ) async {
    final downloadService = _FakeDownloadOptionsService();
    final linkResolver = _FakeLinkResolverService(
      onResolve: (_) async =>
          throw LinkResolutionException.unavailable(Exception('private')),
    );
    await _pumpSearch(
      tester,
      _FakeSearchService(),
      downloadOptionsService: downloadService,
      linkResolverService: linkResolver,
    );

    await _submitLink(tester);

    expect(find.text('El video no está disponible.'), findsOneWidget);
    expect(find.text('Opciones de descarga'), findsNothing);
  });

  testWidgets('URL submit does not mutate recentSearches', (tester) async {
    final state = PlayerState()..navigate(AppRoute.search);
    final initialRecents = List<String>.of(state.recentSearches);
    final downloadService = _FakeDownloadOptionsService(
      results: const [_m4a128Option, _mp3Option],
    );
    final linkResolver = _FakeLinkResolverService();
    await _pumpSearch(
      tester,
      _FakeSearchService(),
      downloadOptionsService: downloadService,
      linkResolverService: linkResolver,
      state: state,
    );

    await _submitLink(tester);

    expect(state.recentSearches, initialRecents);
  });

  testWidgets(
    'submitting plain text after a URL clears the resolved row and runs text search',
    (tester) async {
      final state = PlayerState()..navigate(AppRoute.search);
      final initialRecents = List<String>.of(state.recentSearches);
      final searchService = _FakeSearchService(
        results: const [
          RemoteSearchResult(
            id: 'tx',
            title: 'Resultado de texto',
            artist: 'Canal',
            sourceUrl: 'https://www.youtube.com/watch?v=tx',
          ),
        ],
      );
      final downloadService = _FakeDownloadOptionsService(
        results: const [_m4a128Option, _mp3Option],
      );
      final linkResolver = _FakeLinkResolverService();
      await _pumpSearch(
        tester,
        searchService,
        downloadOptionsService: downloadService,
        linkResolverService: linkResolver,
        state: state,
      );

      await _submitLink(tester);
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'consulta nueva');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text(_linkResult.title), findsNothing);
      expect(find.text('Resultado de texto'), findsOneWidget);
      expect(searchService.calls, ['consulta nueva']);
      expect(state.recentSearches.first, 'consulta nueva');
      expect(state.recentSearches.length, initialRecents.length + 1);
    },
  );

  testWidgets('clearing the field resets resolved row and error state', (
    tester,
  ) async {
    final downloadService = _FakeDownloadOptionsService(
      results: const [_m4a128Option, _mp3Option],
    );
    final linkResolver = _FakeLinkResolverService();
    await _pumpSearch(
      tester,
      _FakeSearchService(),
      downloadOptionsService: downloadService,
      linkResolverService: linkResolver,
    );

    await _submitLink(tester);
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    expect(find.text(_linkResult.title), findsNothing);
    expect(find.text('Sugerencias'.toUpperCase()), findsOneWidget);
  });
}

int serviceCallCount = 0;

const _remoteResult = RemoteSearchResult(
  id: 'three',
  title: 'Resultado sin accion',
  artist: 'Canal',
  sourceUrl: 'https://www.youtube.com/watch?v=three',
);

const _validUrl = 'https://www.youtube.com/watch?v=abc123def45';

const _linkResult = RemoteSearchResult(
  id: 'abc123def45',
  title: 'Cancion del enlace',
  artist: 'Canal del enlace',
  sourceUrl: _validUrl,
);

Future<void> _submitLink(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), _validUrl);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

const _m4a128Option = DownloadOption(
  id: 'three:M4A:128 kbps:140',
  videoId: 'three',
  sourceUrl: 'https://www.youtube.com/watch?v=three',
  format: DownloadFormat.m4a,
  quality: DownloadQuality.kbps128,
  bitrateKbps: 128,
  sizeBytes: 3145728,
  streamTag: 140,
  disabled: false,
);

const _unknownSizeOption = DownloadOption(
  id: 'three:M4A:128 kbps:141',
  videoId: 'three',
  sourceUrl: 'https://www.youtube.com/watch?v=three',
  format: DownloadFormat.m4a,
  quality: DownloadQuality.kbps128,
  bitrateKbps: 128,
  streamTag: 141,
  disabled: false,
);

const _mp3Option = DownloadOption(
  id: 'three:MP3:conversion-required',
  videoId: 'three',
  sourceUrl: 'https://www.youtube.com/watch?v=three',
  format: DownloadFormat.mp3,
  disabled: true,
  disabledReason: 'Requiere conversion',
);

Future<void> _pumpSearch(
  WidgetTester tester,
  SearchSongsService service, {
  DownloadOptionsService? downloadOptionsService,
  LinkResolverService? linkResolverService,
  PlayerState? state,
}) {
  return tester.pumpWidget(
    ChangeNotifierProvider<PlayerState>.value(
      value: state ?? PlayerState(),
      child: MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            searchService: service,
            downloadOptionsService:
                downloadOptionsService ?? _FakeDownloadOptionsService(),
            linkResolverService: linkResolverService,
          ),
        ),
      ),
    ),
  );
}

Future<void> _showResultOptions(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'accion');
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Resultado sin accion'));
  await tester.pump();
}

class _FakeSearchService implements SearchSongsService {
  final List<RemoteSearchResult> results;
  final Future<List<RemoteSearchResult>> Function(String query, {int limit})?
  onSearch;
  final calls = <String>[];

  _FakeSearchService({this.results = const [], this.onSearch});

  @override
  Future<List<RemoteSearchResult>> searchSongs(String query, {int limit = 10}) {
    calls.add(query);
    final handler = onSearch;
    if (handler != null) return handler(query, limit: limit);
    return Future.value(results);
  }
}

class _FakeDownloadOptionsService implements DownloadOptionsService {
  final List<DownloadOption> results;
  final Future<List<DownloadOption>> Function(RemoteSearchResult result)?
  onFetch;
  final calls = <String>[];

  _FakeDownloadOptionsService({
    this.results = const [_m4a128Option, _mp3Option],
    this.onFetch,
  });

  @override
  Future<List<DownloadOption>> fetchOptions(RemoteSearchResult result) {
    calls.add(result.id);
    final handler = onFetch;
    if (handler != null) return handler(result);
    return Future.value(results);
  }
}

class _FakeLinkResolverService implements LinkResolverService {
  final Future<RemoteSearchResult> Function(String url)? onResolve;
  final calls = <String>[];

  _FakeLinkResolverService({this.onResolve});

  @override
  Future<RemoteSearchResult> resolve(String rawUrl) {
    calls.add(rawUrl);
    final handler = onResolve;
    if (handler != null) return handler(rawUrl);
    return Future.value(_linkResult);
  }
}
