import 'package:flutter_test/flutter_test.dart';
import 'package:monolith/core/data/settings_repository.dart';
import 'package:monolith/shared/widgets/visualizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPrefsSettingsRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('load returns defaults when storage is empty', () async {
      const repo = SharedPrefsSettingsRepository();
      final loaded = await repo.load();

      expect(loaded.variant, SettingsSnapshot.defaults.variant);
      expect(loaded.libraryGrid, SettingsSnapshot.defaults.libraryGrid);
      expect(loaded.nowPlayingRadial, SettingsSnapshot.defaults.nowPlayingRadial);
      expect(loaded.vizStyle, SettingsSnapshot.defaults.vizStyle);
      expect(loaded.accentHue, SettingsSnapshot.defaults.accentHue);
    });

    test('save then load preserves every field', () async {
      const repo = SharedPrefsSettingsRepository();
      const written = SettingsSnapshot(
        variant: 'safe',
        libraryGrid: true,
        nowPlayingRadial: false,
        vizStyle: VizStyle.gradient,
        accentHue: 200,
      );

      await repo.save(written);
      final loaded = await repo.load();

      expect(loaded.variant, 'safe');
      expect(loaded.libraryGrid, isTrue);
      expect(loaded.nowPlayingRadial, isFalse);
      expect(loaded.vizStyle, VizStyle.gradient);
      expect(loaded.accentHue, 200);
    });

    test('load falls back to default vizStyle when stored value is unknown',
        () async {
      SharedPreferences.setMockInitialValues({
        'settings.vizStyle': 'definitely-not-a-style',
      });
      const repo = SharedPrefsSettingsRepository();

      final loaded = await repo.load();

      expect(loaded.vizStyle, SettingsSnapshot.defaults.vizStyle);
    });
  });
}
