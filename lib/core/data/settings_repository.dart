import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/visualizer.dart';

class SettingsSnapshot {
  final String variant;
  final bool libraryGrid;
  final bool nowPlayingRadial;
  final VizStyle vizStyle;
  final double accentHue;

  const SettingsSnapshot({
    required this.variant,
    required this.libraryGrid,
    required this.nowPlayingRadial,
    required this.vizStyle,
    required this.accentHue,
  });

  static const SettingsSnapshot defaults = SettingsSnapshot(
    variant: 'bold',
    libraryGrid: false,
    nowPlayingRadial: true,
    vizStyle: VizStyle.spectrum,
    accentHue: 340,
  );
}

abstract class SettingsRepository {
  Future<SettingsSnapshot> load();
  Future<void> save(SettingsSnapshot snapshot);
}

class SharedPrefsSettingsRepository implements SettingsRepository {
  static const _kVariant = 'settings.variant';
  static const _kLibraryGrid = 'settings.libraryGrid';
  static const _kNowPlayingRadial = 'settings.nowPlayingRadial';
  static const _kVizStyle = 'settings.vizStyle';
  static const _kAccentHue = 'settings.accentHue';

  const SharedPrefsSettingsRepository();

  @override
  Future<SettingsSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    const fallback = SettingsSnapshot.defaults;
    return SettingsSnapshot(
      variant: prefs.getString(_kVariant) ?? fallback.variant,
      libraryGrid: prefs.getBool(_kLibraryGrid) ?? fallback.libraryGrid,
      nowPlayingRadial:
          prefs.getBool(_kNowPlayingRadial) ?? fallback.nowPlayingRadial,
      vizStyle: parseVizStyle(
        prefs.getString(_kVizStyle) ?? fallback.vizStyle.name,
      ),
      accentHue: prefs.getDouble(_kAccentHue) ?? fallback.accentHue,
    );
  }

  @override
  Future<void> save(SettingsSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kVariant, snapshot.variant),
      prefs.setBool(_kLibraryGrid, snapshot.libraryGrid),
      prefs.setBool(_kNowPlayingRadial, snapshot.nowPlayingRadial),
      prefs.setString(_kVizStyle, snapshot.vizStyle.name),
      prefs.setDouble(_kAccentHue, snapshot.accentHue),
    ]);
  }
}

class InMemorySettingsRepository implements SettingsRepository {
  SettingsSnapshot _current;

  InMemorySettingsRepository([SettingsSnapshot? initial])
      : _current = initial ?? SettingsSnapshot.defaults;

  @override
  Future<SettingsSnapshot> load() async => _current;

  @override
  Future<void> save(SettingsSnapshot snapshot) async {
    _current = snapshot;
  }
}
