import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monolith/core/data/models.dart';
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

  testWidgets('tapping a result does not open player or navigate away', (
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
    await _pumpSearch(tester, service, state: state);

    await tester.enterText(find.byType(TextField), 'accion');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resultado sin accion'));
    await tester.pumpAndSettle();

    expect(state.route, AppRoute.search);
    expect(state.playerOpen, isFalse);
    expect(state.playing, isFalse);
  });
}

int serviceCallCount = 0;

Future<void> _pumpSearch(
  WidgetTester tester,
  SearchSongsService service, {
  PlayerState? state,
}) {
  return tester.pumpWidget(
    ChangeNotifierProvider<PlayerState>.value(
      value: state ?? PlayerState(),
      child: MaterialApp(
        home: Scaffold(body: SearchScreen(searchService: service)),
      ),
    ),
  );
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
