import 'package:flutter_test/flutter_test.dart';
import 'package:monolith/core/state/player_state.dart';

void main() {
  test('trims recent searches before storing them', () {
    final state = PlayerState();

    state.addRecentSearch('  Lianne  ');

    expect(state.recentSearches.first, 'Lianne');
  });

  test('ignores empty recent searches', () {
    final state = PlayerState();
    final before = List<String>.from(state.recentSearches);

    state.addRecentSearch('   ');

    expect(state.recentSearches, before);
  });

  test('deduplicates recent searches case-insensitively', () {
    final state = PlayerState();

    state.addRecentSearch('Ambient');
    state.addRecentSearch('ambient');

    expect(
      state.recentSearches
          .where((item) => item.toLowerCase() == 'ambient')
          .length,
      1,
    );
    expect(state.recentSearches.first, 'ambient');
  });

  test('keeps newest searches first and caps at five items', () {
    final state = PlayerState();

    for (final query in ['One', 'Two', 'Three', 'Four', 'Five', 'Six']) {
      state.addRecentSearch(query);
    }

    expect(state.recentSearches, ['Six', 'Five', 'Four', 'Three', 'Two']);
  });
}
